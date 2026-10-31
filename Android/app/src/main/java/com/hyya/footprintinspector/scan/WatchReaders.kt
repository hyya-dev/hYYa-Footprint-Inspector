// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.scan

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import com.hyya.footprintinspector.model.Reading
import com.hyya.footprintinspector.model.Severity

/**
 * Who holds the access that watching someone needs: reading the screen (accessibility), reading
 * every notification (notification access) and locking or erasing the device (device admin).
 *
 * All three lists are readable by any app with no permission and no broad app visibility
 * (tested on Android 16, target SDK 36: docs/WATCHERS-RESEARCH.md). Accessibility entries carry
 * the app's name; the other two give a package ID unless the app is otherwise visible to us.
 * We never say an app spies: holding the access is the fact, and Settings shows the full name.
 */
object WatchReaders {
    /** One app that holds at least one of the three, as shown to the person. */
    data class Holder(val pkg: String, val name: String?, val builtIn: Boolean) {
        val shown: String get() = name ?: "$pkg (open Settings to see its name)"
    }

    fun read(c: Context): List<Reading> {
        // Store screenshots: an invented app (no real product is named) holding all three.
        if (Sample.on) return listOf(
            Reading("watch-screen", "1 app can read your screen", listOf("Screen Helper")),
            Reading("watch-notifications", "2 apps can read every notification", listOf("Screen Helper", "Watch Companion")),
            Reading("watch-admin", "1 app can lock or erase this device", listOf("Screen Helper")),
            Reading("watch-several", "1 app holds more than one", listOf("Screen Helper"),
                note = "This is how monitoring apps work. If you don't know an app here, remove it."),
        )
        val pm = c.packageManager
        val a11yNames = mutableMapOf<String, String>()
        val screen = c.getSystemService(AccessibilityManager::class.java)
            .getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .map { info ->
                val app = info.resolveInfo.serviceInfo.applicationInfo
                a11yNames[app.packageName] = app.loadLabel(pm).toString()
                app.packageName
            }.distinct()
        val listeners = Settings.Secure.getString(c.contentResolver, "enabled_notification_listeners")
        val notifications = listeners.orEmpty()
            .split(':').mapNotNull { ComponentName.unflattenFromString(it)?.packageName }.distinct()
        val admins = c.getSystemService(DevicePolicyManager::class.java).activeAdmins.orEmpty()
            .map { it.packageName }.distinct()

        fun holder(pkg: String): Holder {
            val info = runCatching { pm.getApplicationInfo(pkg, 0) }.getOrNull()
            val builtIn = info != null && (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            // An outside app chooses its own name, so it can't borrow our built-in label.
            val label = (a11yNames[pkg] ?: info?.loadLabel(pm)?.toString())?.takeUnless { !builtIn && BUILT_IN in it }
            return Holder(pkg, label, builtIn)
        }
        val mine = c.packageName
        fun others(pkgs: List<String>) = pkgs.filter { it != mine }.map(::holder)

        val s = others(screen); val n = others(notifications); val a = others(admins)
        val several = (s + n + a).filter { !it.builtIn }.groupBy { it.pkg }
            .filter { (_, v) -> v.size >= 2 }.map { (_, v) -> v.first() }

        return listOf(
            list("watch-screen", s, "can read your screen", "No app can read your screen"),
            // An unreadable setting must not look like an all-clear.
            if (listeners == null) Reading("watch-notifications", "Couldn't check this on your device", severityOverride = Severity.LOW)
            else list("watch-notifications", n, "can read every notification", "No app can read every notification"),
            list("watch-admin", a, "can lock or erase this device", "No app can lock or erase this device"),
            if (several.isEmpty()) none("watch-several", "No app holds more than one of these")
            else Reading("watch-several",
                if (several.size == 1) "1 app holds more than one" else "${several.size} apps hold more than one",
                several.map { it.shown },
                note = "This is how monitoring apps work. If you don't know an app here, remove it."),
        )
    }

    private fun none(id: String, value: String) = Reading(id, value, severityOverride = Severity.LOW)

    /** Built-in apps (part of the system) are listed but don't count towards the finding. */
    private fun list(id: String, holders: List<Holder>, verb: String, empty: String): Reading {
        if (holders.isEmpty()) return none(id, empty)
        val outside = holders.filter { !it.builtIn }
        val items = outside.map { it.shown } + holders.filter { it.builtIn }.map { "${it.shown} · $BUILT_IN" }
        return if (outside.isEmpty()) Reading(id, "Only apps built into your device", items, severityOverride = Severity.LOW)
        else Reading(id, if (outside.size == 1) "1 app $verb" else "${outside.size} apps $verb", items)
    }
}

private const val BUILT_IN = "built into your device"
