// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector

import com.hyya.footprintinspector.catalogue.Directions
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test

class DirectionsTest {
    private val galaxyOneUi9 = Directions(samsung = true, api = 37)
    private val pixelAndroid13 = Directions(samsung = false, api = 33)
    private val pixelAndroid16 = Directions(samsung = false, api = 36)

    @Test fun samsungPathsMatchItsOwnSettingsApp() {
        assertEquals("Settings › Security and privacy › More privacy settings › Permission manager", galaxyOneUi9.permissionManager)
        assertEquals("Settings › Security and privacy › Screen lock and biometrics", galaxyOneUi9.screenLock)
        assertEquals("Settings › General management › Keyboard list and default", galaxyOneUi9.keyboards)
        assertEquals("Settings › Security and privacy › Lost device protection › Theft protection", galaxyOneUi9.theftProtection)
    }

    @Test fun android13UsesItsOlderMenus() {
        assertEquals("Settings › Privacy › Permission manager", pixelAndroid13.permissionManager)
        assertEquals("Settings › Security › Find My Device", pixelAndroid13.findDevice)
        assertEquals("Settings › System › Languages & input › On-screen keyboard", pixelAndroid13.keyboards)
        assertEquals("Settings › Display › Screen timeout", pixelAndroid13.screenTimeout)
    }

    @Test fun advancedProtectionOnlyWhereItExists() {
        assertNull(pixelAndroid13.advancedProtection)
        assertEquals("Settings › Google › All services › Advanced Protection", pixelAndroid16.advancedProtection)
    }

    @Test fun aDirectionNamesOnePlaceOnly() {
        for (d in listOf(galaxyOneUi9, pixelAndroid13, pixelAndroid16)) {
            for (path in listOf(d.permissionManager, d.screenLock, d.findDevice, d.deviceAdmin, d.ads, d.softwareUpdate)) {
                assertFalse(path, path.contains("on Samsung") || path.contains(" or later") || path.contains("Android 1"))
            }
        }
    }
}
