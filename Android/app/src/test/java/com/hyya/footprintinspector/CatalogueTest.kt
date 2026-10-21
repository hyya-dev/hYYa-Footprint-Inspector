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

    @Test fun copyIsDeviceNeutralAndNamesNoAppleProduct() {
        val bad = Regex("\\b(iPhone|iPad|iOS|Pixel|Galaxy)\\b")
        val texts = Catalogue.list.flatMap { d -> listOf(d.title, d.reveals, d.why, d.fix.summary) + d.fix.steps } +
            Sensitive.categories.flatMap { listOf(it.tells) + it.steps } + CheckUp.steps.flatMap { listOf(it.why) + it.actions }
        val offenders = texts.filter { bad.containsMatchIn(it) && "\"Sam's Pixel\"" !in it }
        assertTrue("Device brand in copy: $offenders", offenders.isEmpty())
    }
}
