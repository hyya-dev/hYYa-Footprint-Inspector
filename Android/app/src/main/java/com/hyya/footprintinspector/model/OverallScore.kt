// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.model

/**
 * One number for all four checks, out of 100, as on iOS (App/Sources/Scanner/PrivacyCheck.swift).
 * It's the average of the checks done so far. On Android the Tracker check is the scan's own
 * "who can watch you" part, so it's done together with the Footprint scan.
 */
data class OverallScore(val parts: Map<Part, Int>) {
    enum class Part { FOOTPRINT, SENSITIVE, TRACKER, CHECKUP }

    enum class Level(val title: String) { GOOD("Well protected"), FAIR("Partly protected"), WEAK("Easy to track") }

    val doneCount: Int get() = parts.size
    val total: Int get() = Part.entries.size
    val value: Int? get() = if (parts.isEmpty()) null else Math.round(parts.values.sum().toDouble() / parts.size).toInt()
    val level: Level? get() = value?.let { if (it >= 75) Level.GOOD else if (it >= 50) Level.FAIR else Level.WEAK }

    companion object {
        /** Every app that can be spotted costs 25 points, down to 20. */
        fun sensitivePart(found: Int) = maxOf(20, 100 - 25 * found)
        /** Every app holding a watching power that's worth a look costs 20 points, down to 20. */
        fun trackerPart(watchers: Int) = maxOf(20, 100 - 20 * watchers)

        fun of(footprint: Int?, sensitiveFound: Int?, watchers: Int?, checkUpDone: Int, checkUpTotal: Int): OverallScore {
            val p = mutableMapOf<Part, Int>()
            footprint?.let { p[Part.FOOTPRINT] = it }
            sensitiveFound?.let { p[Part.SENSITIVE] = sensitivePart(it) }
            watchers?.let { p[Part.TRACKER] = trackerPart(it) }
            // Check-up counts once every area is done, so ticking an area never lowers the score.
            if (checkUpTotal > 0 && checkUpDone >= checkUpTotal) p[Part.CHECKUP] = 100
            return OverallScore(p)
        }

        val explanation = """
            Your privacy score is the average of the checks you've done, out of 100. Higher is better.

            • Footprint: how much any app can read about this device. Everyone starts at 100; each thing worth a look that you can fix costs 10 points, each smaller one 2, and every 40 points lost halve it, so it never hits zero.
            • Sensitive apps: 100 if none of the apps you checked can be spotted, then 25 less for each one that can.
            • Tracker: 100 if no app holds a power to watch you that's worth a look, then 20 less for each one.
            • Check-up: counts as 100 once you've been through every Settings area. Until then it isn't in the score, so ticking areas off never lowers it.

            Sensitive apps and Tracker never go below 20. Things only Google or your device's maker can fix don't count. The score isn't a measure of how unique your device is: that would need data from other devices, and this app never sends or receives any.
        """.trimIndent()
    }
}
