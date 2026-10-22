// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector

import com.hyya.footprintinspector.catalogue.Catalogue
import com.hyya.footprintinspector.catalogue.CheckUp
import com.hyya.footprintinspector.catalogue.Sensitive
import com.hyya.footprintinspector.model.Fix
import com.hyya.footprintinspector.model.FixLevel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class CatalogueTest {
    @Test fun idsAreUnique() {
        val ids = Catalogue.list.map { it.id }
        assertEquals(ids.toSet().size, ids.size)
    }

    @Test fun everySensitivePackageIsDeclaredInTheManifest() {
        val manifest = File("src/main/AndroidManifest.xml").readText()
        val missing = Sensitive.allPackages.filter { "android:name=\"$it\"" !in manifest }
        assertTrue("Not in <queries>: $missing", missing.isEmpty())
        assertTrue("The app must never ask for internet access", "android.permission.INTERNET" !in manifest)
        assertTrue("No broad package visibility", "QUERY_ALL_PACKAGES" !in manifest)
    }

    @Test fun settingsFixesCarryAnAction() {
        Catalogue.list.filter { it.fix.level == FixLevel.OPEN_SETTINGS }.forEach {
            assertTrue("${it.id} has no Settings page", it.fix.settingsAction != null)
        }
    }

    /** Store rules: we show who holds the access, never claim to detect spying (docs/WATCHERS-RESEARCH.md). */
    @Test fun watchCopyMakesNoDetectionClaims() {
        val watch = Catalogue.list.filter { it.section == com.hyya.footprintinspector.model.Section.WATCH }
        assertEquals(setOf("watch-screen", "watch-notifications", "watch-admin", "watch-several"), watch.map { it.id }.toSet())
        val claims = Regex("(?i)\\b(spy\\w*|malware|virus|threat|detect\\w*|infected)\\b")
        val texts = watch.flatMap { listOf(it.title, it.reveals, it.why, it.fix.summary) + it.fix.steps } +
            Sensitive.OTHERS_LINE + Sensitive.WEBSITE_LINE
        val offenders = texts.filter { claims.containsMatchIn(it) }
        assertTrue("Detection claim in copy: $offenders", offenders.isEmpty())
        // No organisation is named as doing the check: we can't see which apps do.
        assertTrue(Regex("(?i)bank of|HSBC|Chase|gov\\.").find(Sensitive.OTHERS_LINE) == null)
    }

    @Test fun copyIsDeviceNeutralAndNamesNoAppleProduct() {
        val bad = Regex("\\b(iPhone|iPad|iOS|Pixel|Galaxy)\\b")
        val texts = Catalogue.list.flatMap { d -> listOf(d.title, d.reveals, d.why, d.fix.summary) + d.fix.steps } +
            Sensitive.categories.flatMap { listOf(it.tells) + it.steps } + CheckUp.steps.flatMap { listOf(it.why) + it.actions }
        val offenders = texts.filter { bad.containsMatchIn(it) && "\"Sam's Pixel\"" !in it }
        assertTrue("Device brand in copy: $offenders", offenders.isEmpty())
    }
}
