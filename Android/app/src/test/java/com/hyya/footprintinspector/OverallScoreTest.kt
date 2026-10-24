// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector

import com.hyya.footprintinspector.catalogue.Catalogue
import com.hyya.footprintinspector.model.OverallScore
import com.hyya.footprintinspector.model.PlainWords
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OverallScoreTest {
    @Test fun averagesOnlyTheChecksDone() {
        assertNull(OverallScore.of(null, null, null, 0, 18).value)
        assertEquals(62, OverallScore.of(62, null, null, 0, 18).value)
        assertEquals(Math.round((62 + 75 + 100) / 3.0).toInt(), OverallScore.of(62, 1, 0, 0, 18).value)
    }

    /** Ticking Check-up areas never lowers the score: it only counts, as 100, once finished. */
    @Test fun checkUpNeverLowersTheScore() {
        val before = OverallScore.of(62, null, null, 0, 18).value!!
        for (done in 1 until 18) assertEquals(before, OverallScore.of(62, null, null, done, 18).value)
        assertTrue(OverallScore.of(62, null, null, 18, 18).value!! > before)
    }

    /** Every Android finding has a plain headline and one short line, in device-neutral words. */
    @Test fun everyFindingHasPlainWords() {
        val device = Regex("(?i)\\b(iphone|ipad|phone|pixel|galaxy)\\b")
        for (d in Catalogue.list) {
            val w = PlainWords.text[d.id]
            assertTrue("No plain words for ${d.id}", w != null)
            assertTrue("Headline too long: ${d.id}", w!!.headline.length <= 60)
            assertTrue("Device word in ${d.id}", device.find(w.headline + " " + w.brief) == null)
        }
    }
}

/** Security review 2026-10-24: launch extras are honoured in debug builds only. */
class LaunchExtrasTest {
    @Test fun everyExtraIsDebugOnly() {
        val src = java.io.File("src/main/java/com/hyya/footprintinspector/MainActivity.kt").readText()
        val unguarded = src.lines().filter { "intent.get" in it && "dev" !in it }
        assertTrue("Extras read without the debug guard: $unguarded", unguarded.isEmpty())
    }
}
