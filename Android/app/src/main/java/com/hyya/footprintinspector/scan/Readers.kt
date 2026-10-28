// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.scan

import android.annotation.SuppressLint
import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.hardware.Sensor
import android.hardware.SensorManager
import android.hardware.biometrics.BiometricManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.SystemClock
import android.provider.Settings
import android.telephony.TelephonyManager
import android.text.format.DateFormat
import android.view.WindowManager
import android.view.accessibility.AccessibilityManager
import android.view.inputmethod.InputMethodManager
import com.hyya.footprintinspector.model.Reading
import com.hyya.footprintinspector.model.Severity
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Every reader, in display order. Permission readers return nothing until granted. */
object Readers {
    val all: List<Reader> = listOf(
        ::identity, ::system, ::storage, ::display, ::audio, ::language, ::accessibility, ::sensors,
        ::network, ::security, ::apps, ::reinstall,
    ).map { f -> Reader { f(it) } } + Reader { WatchReaders.read(it) } + PermissionReaders.all
}

/** Store screenshots must never show a real device: `-e sampleData true` swaps personal values. */
object Sample {
    @Volatile var on = false
}

private val bytesFormat: NumberFormat = NumberFormat.getIntegerInstance()
fun exactBytes(b: Long) = "${android.text.format.Formatter.formatFileSize(null, b)} (${bytesFormat.format(b)} bytes)"
fun shortBytes(b: Long) = android.text.format.Formatter.formatShortFileSize(null, b)
fun dateTime(ms: Long): String = SimpleDateFormat("d MMM yyyy, HH:mm:ss", Locale.getDefault()).format(Date(ms))

/** Spots a first name in names like "Sam's Buds" or "Sam’s Galaxy". */
fun ownerName(name: String): String? = Regex("^([\\p{L}][\\p{L}\\-]{1,20})['’]s\\s").find(name)?.groupValues?.get(1)

// MARK: This device

@SuppressLint("HardwareIds")
private fun identity(c: Context): List<Reading> {
    val name = if (Sample.on) "Alex's Pixel" else Settings.Global.getString(c.contentResolver, Settings.Global.DEVICE_NAME) ?: Build.MODEL
    val first = ownerName(name)
    return listOf(
        Reading("device-name", name,
            severityOverride = if (first == null) Severity.LOW else null,
            note = first?.let { "This name suggests the owner is called $it. Any app can read it." }),
        Reading("model", "${Build.MANUFACTURER.replaceFirstChar { it.uppercase() }} ${Build.MODEL}",
            listOfNotNull("Product: ${Build.PRODUCT}", "Board: ${Build.BOARD}", Build.SOC_MODEL.takeIf { it != Build.UNKNOWN }?.let { "Chip: $it" })),
        Reading("system-version", "Android ${Build.VERSION.RELEASE}",
            listOf("Security update: ${Build.VERSION.SECURITY_PATCH}", "API level ${Build.VERSION.SDK_INT}")),
        Reading("build-fingerprint", Build.FINGERPRINT, listOf("Build: ${Build.DISPLAY}")),
    )
}

// MARK: System

private fun system(c: Context): List<Reading> {
    val boot = System.currentTimeMillis() - SystemClock.elapsedRealtime()
    val battery = c.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    val level = battery?.let { it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / it.getIntExtra(BatteryManager.EXTRA_SCALE, 100) }
    val charging = battery?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) == BatteryManager.BATTERY_STATUS_CHARGING
    val dev = Settings.Global.getInt(c.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1
    val adb = Settings.Global.getInt(c.contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
    val upHours = SystemClock.elapsedRealtime() / 3_600_000
    val boots = Settings.Global.getInt(c.contentResolver, Settings.Global.BOOT_COUNT, -1)
    return listOf(
        // A restart in the last week is the fix itself, so it counts as done.
        Reading("boot-time", dateTime(boot), listOf("Running for ${upHours / 24} days, ${upHours % 24} h"),
            severityOverride = if (RecentRestart.isRecent(SystemClock.elapsedRealtime())) Severity.LOW else null,
            note = if (RecentRestart.isRecent(SystemClock.elapsedRealtime())) RecentRestart.NOTE else null),
        Reading("boot-count", if (boots >= 0) "Started $boots times" else "Hidden on this device",
            severityOverride = if (boots < 0) Severity.LOW else null),
        Reading("battery", if (level != null) "$level%${if (charging) ", charging" else ""}" else "Unknown"),
        Reading("developer-options", if (dev) "On${if (adb) ", USB debugging on" else ""}" else "Off",
            severityOverride = if (!dev) Severity.LOW else null),
    )
}

// MARK: Storage and memory

private fun storage(c: Context): List<Reading> {
    val fs = StatFs(Environment.getDataDirectory().path)
    val mem = ActivityManager.MemoryInfo().also { (c.getSystemService(ActivityManager::class.java)).getMemoryInfo(it) }
    return listOf(
        Reading("disk-total", shortBytes(fs.totalBytes)),
        Reading("disk-free", exactBytes(fs.availableBytes)),
        Reading("memory", "${shortBytes(mem.totalMem)} memory · ${Runtime.getRuntime().availableProcessors()} processor cores"),
    )
}

// MARK: Screen

private fun display(c: Context): List<Reading> {
    val wm = c.getSystemService(WindowManager::class.java)
    val b = wm.maximumWindowMetrics.bounds
    val cfg = c.resources.configuration
    val dm = c.resources.displayMetrics
    val zoomChanged = dm.densityDpi != android.util.DisplayMetrics.DENSITY_DEVICE_STABLE
    return listOf(
        Reading("screen", "${b.width()} × ${b.height()} · ${dm.densityDpi} dpi",
            listOf("Refresh: ${c.display.refreshRate.toInt()} refreshes a second")),
        Reading("text-size", when {
            cfg.fontScale > 1.05f -> "Larger (${(cfg.fontScale * 100).toInt()}%)"
            cfg.fontScale < 0.95f -> "Smaller (${(cfg.fontScale * 100).toInt()}%)"
            else -> "Default"
        }, listOf("Display size: ${if (zoomChanged) "changed from the default" else "default"}"),
            severityOverride = if (cfg.fontScale in 0.95f..1.05f && !zoomChanged) Severity.LOW else null),
    )
}

// MARK: Sound and accessories

private fun audio(c: Context): List<Reading> {
    val am = c.getSystemService(AudioManager::class.java)
    val names = if (Sample.on) listOf("Alex's Buds") else am.getDevices(AudioManager.GET_DEVICES_ALL)
        .filter { it.type in setOf(AudioDeviceInfo.TYPE_BLUETOOTH_A2DP, AudioDeviceInfo.TYPE_BLUETOOTH_SCO, AudioDeviceInfo.TYPE_BLE_HEADSET,
            AudioDeviceInfo.TYPE_BLE_SPEAKER, AudioDeviceInfo.TYPE_USB_HEADSET, AudioDeviceInfo.TYPE_WIRED_HEADSET, AudioDeviceInfo.TYPE_HEARING_AID) }
        .map { it.productName.toString() }.filter { it.isNotBlank() }.distinct()
    val first = names.firstNotNullOfOrNull(::ownerName)
    return listOf(
        Reading("audio-route", if (names.isEmpty()) "Nothing connected" else names.joinToString(", "), names,
            severityOverride = when { first != null -> Severity.HIGH; names.isEmpty() -> Severity.LOW; else -> null },
            note = first?.let { "This name suggests the owner is called $it. Any app can read it." }),
    )
}

// MARK: Language, region and time

private fun language(c: Context): List<Reading> {
    val locales = c.resources.configuration.locales
    val langs = (0 until locales.size()).map { locales[it].displayName }
    val imm = c.getSystemService(InputMethodManager::class.java)
    val keyboards = imm.enabledInputMethodList.map { it.loadLabel(c.packageManager).toString() }
    val subtypes = imm.enabledInputMethodList.flatMap { imm.getEnabledInputMethodSubtypeList(it, true) }
        .mapNotNull { it.languageTag.takeIf(String::isNotEmpty) }.map { Locale.forLanguageTag(it).displayName }.distinct()
    val tz = TimeZone.getDefault()
    return listOf(
        Reading("languages", langs.joinToString(", "), langs, severityOverride = if (langs.size <= 1) Severity.LOW else null),
        Reading("keyboards", "${keyboards.size} keyboard app${if (keyboards.size == 1) "" else "s"}", keyboards + subtypes.map { "Language: $it" },
            severityOverride = if (keyboards.size <= 1 && subtypes.size <= 1) Severity.LOW else null),
        Reading("timezone", tz.id.replace('_', ' '),
            listOf("Clock: ${if (DateFormat.is24HourFormat(c)) "24-hour" else "12-hour"}")),
    )
}

// MARK: Accessibility and appearance

private fun accessibility(c: Context): List<Reading> {
    val am = c.getSystemService(AccessibilityManager::class.java)
    val services = am.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        .map { it.resolveInfo.loadLabel(c.packageManager).toString() }
    val dark = (c.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    return listOf(
        Reading("accessibility", if (services.isEmpty()) "None detected" else services.joinToString(", "), services,
            severityOverride = if (services.isEmpty()) Severity.LOW else null),
        Reading("appearance", if (dark) "Dark theme" else "Light theme"),
    )
}

// MARK: Sensors

private fun sensors(c: Context): List<Reading> {
    val list = c.getSystemService(SensorManager::class.java).getSensorList(Sensor.TYPE_ALL)
    val cams = c.getSystemService(android.hardware.camera2.CameraManager::class.java)
    val cameras = cams.cameraIdList.map { id ->
        val ch = cams.getCameraCharacteristics(id)
        val side = when (ch.get(android.hardware.camera2.CameraCharacteristics.LENS_FACING)) {
            android.hardware.camera2.CameraCharacteristics.LENS_FACING_FRONT -> "Front"
            android.hardware.camera2.CameraCharacteristics.LENS_FACING_BACK -> "Back"
            else -> "Connected"
        }
        val px = ch.get(android.hardware.camera2.CameraCharacteristics.SENSOR_INFO_PIXEL_ARRAY_SIZE)
        "$side camera${px?.let { ", ${(it.width.toLong() * it.height / 1_000_000)} megapixels" } ?: ""}"
    }
    return listOf(
        Reading("sensors", "${list.size} sensors", list.map { "${it.name} (${it.vendor})" }),
        Reading("cameras", "${cameras.size} cameras", cameras),
    )
}

// MARK: Network and mobile

@SuppressLint("MissingPermission")
private fun network(c: Context): List<Reading> {
    val cm = c.getSystemService(ConnectivityManager::class.java)
    val caps = cm.getNetworkCapabilities(cm.activeNetwork)
    val kind = when {
        caps == null -> "Offline"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi-Fi"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "Mobile data"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
        else -> "Other"
    }
    val vpn = cm.allNetworks.any { cm.getNetworkCapabilities(it)?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true }
    val tm = c.getSystemService(TelephonyManager::class.java)
    val carrier = if (Sample.on) "Carrier" else tm.simOperatorName.orEmpty()
    val country = tm.simCountryIso.orEmpty().uppercase()
    return listOf(
        Reading("connection", kind, listOf("Data saver treats it as costly: ${if (cm.isActiveNetworkMetered) "yes" else "no"}")),
        Reading("vpn", if (vpn) "VPN detected" else "No VPN detected", severityOverride = if (!vpn) Severity.LOW else null),
        Reading("carrier", if (carrier.isBlank()) "No SIM" else "$carrier${if (country.isNotBlank()) " · $country" else ""}",
            severityOverride = if (carrier.isBlank()) Severity.LOW else null),
    )
}

// MARK: Security set-up

private fun security(c: Context): List<Reading> {
    val secure = c.getSystemService(KeyguardManager::class.java).isDeviceSecure
    val bio = c.getSystemService(BiometricManager::class.java)
        .canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS
    return listOf(
        Reading("screen-lock", when {
            !secure -> "No screen lock"
            bio -> "Screen lock and biometrics"
            else -> "Screen lock"
        }, severityOverride = if (secure) Severity.LOW else Severity.HIGH,
            note = if (!secure) "Without a screen lock, anyone holding this device can see everything on it." else null),
    )
}

// MARK: Apps

private fun apps(c: Context): List<Reading> {
    val pm = c.packageManager
    // Visible only because the manifest asks for "any browser" (an intent query), like any app can.
    val browser = pm.resolveActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com")), PackageManager.MATCH_DEFAULT_ONLY)
        ?.loadLabel(pm)?.toString() ?: "Unknown"
    return listOf(Reading("default-browser", browser))
}

// MARK: Remembered after deleting

@SuppressLint("HardwareIds")
private fun reinstall(c: Context): List<Reading> {
    val id = if (Sample.on) "8c2f4a91d03e57b6" else Settings.Secure.getString(c.contentResolver, Settings.Secure.ANDROID_ID).orEmpty()
    val info = c.packageManager.getPackageInfo(c.packageName, 0)
    return listOf(
        Reading("android-id", id, listOf("This app was first installed: ${dateTime(info.firstInstallTime)}")),
    )
}

object SampleData {
    val apps = listOf("Calendar", "Camera", "Chrome", "Clock", "Contacts", "Drive", "Files", "Gmail", "Maps", "Messages",
        "Phone", "Photos", "Play Store", "Settings", "hYYa Footprint Inspector")
}

/** A restart within a week counts as done (owner, 2026-10-28). Elapsed time includes deep sleep. */
object RecentRestart {
    const val WINDOW_MS = 7L * 24 * 3600 * 1000
    const val NOTE = "Restarted within the last week, so this changes again soon. Nothing to do."
    fun isRecent(elapsedMs: Long) = elapsedMs < WINDOW_MS
}
