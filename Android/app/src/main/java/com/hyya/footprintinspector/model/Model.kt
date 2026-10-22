// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.model

/** Mirrors the iOS model (App/Sources/Model/Signal.swift) so wording rules and the score match. */

enum class Severity(val label: String) { LOW("Low"), MEDIUM("Medium"), HIGH("Worth a look") }

/** How an app gets at a signal. */
enum class Group { WATCH, PASSIVE, ADVANCED, PERMISSION }

enum class Persistence(val label: String) {
    UNTIL_RESTART("Until you restart"),
    UNTIL_REINSTALL("Until you reinstall the app"),
    UNTIL_RESET("Until you reset the device"),
    HARDWARE("Fixed for this model"),
    UNTIL_YOU_CHANGE_IT("Until you change the setting"),
    CHANGES_OFTEN("Changes often"),
    UNTIL_UPDATE("Until you update the system"),
    PERMANENT("Never changes, even if you reset the device"),
}

/** The four fix levels agreed for the product. */
enum class FixLevel(val label: String) {
    IN_APP("Fix it here"),
    OPEN_SETTINGS("You can fix this"),
    GUIDED("You can fix this"),
    ONLY_MAKER("Only Google or the device maker can fix this"),
}

/**
 * What to do about a finding. [settingsAction] is an `android.provider.Settings` intent action
 * that opens the right page, so most Android fixes are one tap.
 */
data class Fix(
    val level: FixLevel,
    val summary: String,
    val steps: List<String> = emptyList(),
    val settingsAction: String? = null,
) {
    val fixable: Boolean get() = level != FixLevel.ONLY_MAKER

    companion object {
        fun onlyMaker(summary: String = "No setting changes this. Only a system update could.") =
            Fix(FixLevel.ONLY_MAKER, summary)
        fun guided(summary: String, vararg steps: String) = Fix(FixLevel.GUIDED, summary, steps.toList())
        fun settings(summary: String, action: String, vararg steps: String) =
            Fix(FixLevel.OPEN_SETTINGS, summary, steps.toList(), action)
        /** For signals that reflect a choice the user needs (accessibility, protective settings). */
        fun leaveIt(summary: String) = Fix(FixLevel.ONLY_MAKER, summary)
    }
}

enum class Section(val title: String, val group: Group) {
    WATCH("Who can watch you", Group.WATCH),
    IDENTITY("This device", Group.PASSIVE),
    SYSTEM("System", Group.PASSIVE),
    STORAGE("Storage and memory", Group.PASSIVE),
    DISPLAY("Screen", Group.PASSIVE),
    AUDIO("Sound and accessories", Group.PASSIVE),
    LANGUAGE("Language, region and time", Group.PASSIVE),
    ACCESSIBILITY("Accessibility and appearance", Group.PASSIVE),
    SENSORS("Sensors", Group.PASSIVE),
    NETWORK("Network and mobile", Group.PASSIVE),
    SECURITY("Security set-up", Group.PASSIVE),
    APPS("Apps", Group.ADVANCED),
    REINSTALL("Remembered after deleting", Group.ADVANCED),
    LOCATION("Location", Group.PERMISSION),
    NEARBY("Nearby devices", Group.PERMISSION),
    CONTACTS("Contacts", Group.PERMISSION),
    CALENDARS("Calendars", Group.PERMISSION),
}

/** Everything we say about a signal. Values are read separately. */
data class Definition(
    val id: String,
    val section: Section,
    val title: String,
    /** What it tells an app, in plain words. */
    val reveals: String,
    /** Why the system lets apps read it at all. */
    val why: String,
    val persistence: Persistence,
    val severity: Severity,
    val fix: Fix,
)

/** A value read from this device. */
data class Reading(
    val id: String,
    val value: String,
    val items: List<String> = emptyList(),
    /** Raised or lowered for this device, e.g. higher when a first name is found. */
    val severityOverride: Severity? = null,
    /** One calm line on why this reading was raised or lowered. */
    val note: String? = null,
)

data class Finding(val definition: Definition, val reading: Reading) {
    val id: String get() = definition.id
    val severity: Severity get() = reading.severityOverride ?: definition.severity
    val isConcerning: Boolean get() = severity == Severity.HIGH
}

/** Same rules as iOS: start at 100; fixable high −10, fixable medium −2; unfixable not counted. */
data class FootprintScore(val value: Int, val fixableCount: Int, val onlyMakerCount: Int) {
    enum class Level(val title: String) { LIGHT("Light footprint"), MODERATE("Moderate footprint"), HEAVY("Heavy footprint") }

    val level: Level
        get() = when {
            value >= 75 -> Level.LIGHT
            value >= 50 -> Level.MODERATE
            else -> Level.HEAVY
        }

    companion object {
        const val HIGH_WEIGHT = 10
        const val MEDIUM_WEIGHT = 2

        /** Every 40 points lost halve the score, as on iOS: never zero, first fixes count most. */
        fun value(lost: Int): Int = Math.round(100.0 * Math.pow(0.5, lost / 40.0)).toInt()

        fun points(f: Finding): Int = if (!f.definition.fix.fixable) 0 else when (f.severity) {
            Severity.HIGH -> HIGH_WEIGHT
            Severity.MEDIUM -> MEDIUM_WEIGHT
            Severity.LOW -> 0
        }

        fun of(findings: List<Finding>): FootprintScore {
            var lost = 0; var fixable = 0; var maker = 0
            for (f in findings) {
                val p = points(f)
                lost += p
                if (p > 0) fixable++
                if (!f.definition.fix.fixable && f.severity == Severity.HIGH) maker++
            }
            return FootprintScore(value(lost), fixable, maker)
        }

        val explanation = """
            Everyone starts at 100, and higher is better. Each detail worth a look that you can fix counts $HIGH_WEIGHT points against you, and each smaller one $MEDIUM_WEIGHT. Every 40 points against you halve the score, so the first fixes make the biggest difference, and the score never hits zero. Settings left at their ordinary default don't count.

            Things only Google or your device's maker can fix aren't in the score, because nothing you do changes them. We list them separately.

            The score isn't a measure of how unique your device is: that would need data from other devices, and this app never sends or receives any.
        """.trimIndent()
    }
}
