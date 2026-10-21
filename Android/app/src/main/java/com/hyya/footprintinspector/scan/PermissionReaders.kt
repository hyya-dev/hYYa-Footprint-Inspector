// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.scan

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.provider.CalendarContract
import android.provider.ContactsContract
import androidx.core.content.ContextCompat
import com.hyya.footprintinspector.model.Reading
import com.hyya.footprintinspector.model.Section
import com.hyya.footprintinspector.model.Severity
import java.util.Locale
import kotlin.math.roundToInt

/** A permission an app can ask for, the section it fills, and what we show once it's granted. */
enum class PermissionKind(val section: Section, val permissions: List<String>) {
    LOCATION(Section.LOCATION, listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)),
    NEARBY(Section.NEARBY, listOf(Manifest.permission.BLUETOOTH_CONNECT)),
    CONTACTS(Section.CONTACTS, listOf(Manifest.permission.READ_CONTACTS)),
    CALENDARS(Section.CALENDARS, listOf(Manifest.permission.READ_CALENDAR)),
    ;

    fun granted(c: Context) = permissions.any { ContextCompat.checkSelfPermission(c, it) == PackageManager.PERMISSION_GRANTED }

    companion object {
        fun of(section: Section) = entries.firstOrNull { it.section == section }
    }
}

object PermissionReaders {
    val all: List<Reader> = listOf(
        Reader(::location), Reader(::nearby), Reader(::contacts), Reader(::calendars),
    )

    /** Rounds to about 1 km so the screen never shows an exact position. */
    private fun rough(lat: Double, lon: Double) = String.format(Locale.US, "%.2f, %.2f", lat, lon)

    @SuppressLint("MissingPermission")
    private suspend fun location(c: Context): List<Reading> {
        if (!PermissionKind.LOCATION.granted(c)) return emptyList()
        val lm = c.getSystemService(LocationManager::class.java)
        val fine = ContextCompat.checkSelfPermission(c, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val fix = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER, LocationManager.FUSED_PROVIDER)
            .mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }.maxByOrNull { it.time }
        val out = mutableListOf(
            Reading("loc-precise", if (fine) "On" else "Off: only a rough area",
                severityOverride = if (fine) null else Severity.LOW),
        )
        if (fix == null) {
            out += Reading("loc-where", "No position yet", listOf("Open a map app once, then scan again."))
        } else {
            val where = if (Sample.on) "51.50, -0.12" else rough(fix.latitude, fix.longitude)
            out += Reading("loc-where", where, listOf("Accurate to within ${fix.accuracy.roundToInt()} m"))
        }
        return out
    }

    @SuppressLint("MissingPermission")
    private suspend fun nearby(c: Context): List<Reading> {
        if (!PermissionKind.NEARBY.granted(c)) return emptyList()
        val adapter = c.getSystemService(BluetoothManager::class.java).adapter ?: return listOf(Reading("bt-paired", "No Bluetooth"))
        val names = if (Sample.on) listOf("Alex's Buds", "Car audio") else adapter.bondedDevices.mapNotNull { it.name }
        val first = names.firstNotNullOfOrNull(::ownerName)
        return listOf(
            Reading("bt-paired", "${names.size} paired device${if (names.size == 1) "" else "s"}", names,
                severityOverride = when { first != null -> Severity.HIGH; names.isEmpty() -> Severity.LOW; else -> null },
                note = first?.let { "A device name suggests the owner is called $it." }),
            Reading("bt-name", if (Sample.on) "Alex's Pixel" else adapter.name ?: "Unknown"),
        )
    }

    private suspend fun contacts(c: Context): List<Reading> {
        if (!PermissionKind.CONTACTS.granted(c)) return emptyList()
        val cr = c.contentResolver
        val people = cr.query(ContactsContract.Contacts.CONTENT_URI, arrayOf(ContactsContract.Contacts._ID), null, null, null)?.use { it.count } ?: 0
        val phones = cr.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, arrayOf(ContactsContract.CommonDataKinds.Phone._ID), null, null, null)?.use { it.count } ?: 0
        val emails = cr.query(ContactsContract.CommonDataKinds.Email.CONTENT_URI, arrayOf(ContactsContract.CommonDataKinds.Email._ID), null, null, null)?.use { it.count } ?: 0
        val custom = cr.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, arrayOf(ContactsContract.CommonDataKinds.Phone.LABEL),
            "${ContactsContract.CommonDataKinds.Phone.TYPE}=${ContactsContract.CommonDataKinds.Phone.TYPE_CUSTOM}", null, null)
            ?.use { cur -> buildSet { while (cur.moveToNext()) cur.getString(0)?.let(::add) } } ?: emptySet()
        val accounts = cr.query(ContactsContract.RawContacts.CONTENT_URI, arrayOf(ContactsContract.RawContacts.ACCOUNT_TYPE), null, null, null)
            ?.use { cur -> buildSet { while (cur.moveToNext()) add(friendlyAccount(cur.getString(0))) } } ?: emptySet()
        return listOf(
            Reading("contact-count", "$people people", listOf("Phone numbers: $phones", "Email addresses: $emails")),
            Reading("contact-labels", if (custom.isEmpty()) "No labels you typed" else "${custom.size} labels you typed",
                if (Sample.on) emptyList() else custom.toList().take(12),
                severityOverride = if (custom.isEmpty()) Severity.LOW else null),
            Reading("contact-accounts", accounts.joinToString(", ").ifEmpty { "On this device" }, accounts.toList()),
        )
    }

    private fun friendlyAccount(type: String?) = when {
        type == null -> "On this device"
        type.contains("google") -> "Google"
        type.contains("exchange") || type.contains("outlook") -> "Work email account"
        type.contains("samsung") -> "Samsung"
        else -> "Other account"
    }

    private suspend fun calendars(c: Context): List<Reading> {
        if (!PermissionKind.CALENDARS.granted(c)) return emptyList()
        val cr = c.contentResolver
        val accounts = cr.query(CalendarContract.Calendars.CONTENT_URI, arrayOf(CalendarContract.Calendars.ACCOUNT_NAME), null, null, null)
            ?.use { cur -> buildSet { while (cur.moveToNext()) cur.getString(0)?.let(::add) } } ?: emptySet()
        val now = System.currentTimeMillis(); val month = 30L * 24 * 3600 * 1000
        val events = cr.query(CalendarContract.Events.CONTENT_URI, arrayOf(CalendarContract.Events._ID),
            "${CalendarContract.Events.DTSTART} BETWEEN ? AND ?", arrayOf((now - month).toString(), (now + month).toString()), null)?.use { it.count } ?: 0
        val emailLike = accounts.any { it.contains("@") }
        return listOf(
            Reading("cal-accounts", "${accounts.size} account${if (accounts.size == 1) "" else "s"}",
                if (Sample.on) listOf("alex@example.com") else accounts.toList(),
                note = if (emailLike) "At least one account is named after an email address." else null),
            Reading("cal-busy", "$events events in the past and next 30 days"),
        )
    }
}
