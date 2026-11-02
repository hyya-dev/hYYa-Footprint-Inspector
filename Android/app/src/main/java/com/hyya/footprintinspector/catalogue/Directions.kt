// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.catalogue

import android.os.Build

/**
 * Where things are on this device. Settings menus differ by maker and Android version, so each
 * direction is chosen from what's installed, not listed for every device at once.
 *
 * Checked 2026-11-02: Android 13 on a Pixel system image, One UI 9 (Android 17) from a Galaxy
 * S25's own Settings app, and Google's and Samsung's help pages for the versions between.
 * One UI's version isn't public, so its Android level stands in: One UI 7 is API 35, 9 is API 37.
 */
class Directions(private val samsung: Boolean, private val api: Int) {
    private val oneUi9 = samsung && api >= 37
    private val oneUi7 = samsung && api >= 35

    val security = when {
        samsung -> "Settings › Security and privacy"
        api >= 34 -> "Settings › Security & privacy"
        else -> "Settings › Security"
    }
    val permissionManager = when {
        oneUi9 -> "$security › More privacy settings › Permission manager"
        samsung -> "$security › Privacy › Permission manager"
        api >= 34 -> "$security › Privacy controls › Permission manager"
        else -> "Settings › Privacy › Permission manager"
    }
    val screenLock = when {
        oneUi9 -> "$security › Screen lock and biometrics"
        samsung -> "Settings › Lock screen › Screen lock"
        api >= 34 -> "$security › Device unlock › Screen lock"
        else -> "$security › Screen lock"
    }
    val screenTimeout = when {
        !samsung && api >= 35 -> "Settings › Display & touch › Screen timeout"
        else -> "Settings › Display › Screen timeout"
    }
    val findDevice = when {
        oneUi7 -> "$security › Lost device protection › Find My Mobile"
        samsung -> "$security › Lost device protection › Allow this phone to be found"
        api >= 34 -> "Settings › Google › All services › Find Hub"
        else -> "$security › Find My Device"
    }
    val theftProtection = when {
        oneUi7 -> "$security › Lost device protection › Theft protection"
        else -> "Settings › Google › All services › Theft protection"
    }
    val softwareUpdate = if (samsung) "Settings › Software update" else "Settings › System › Software updates"
    val deviceAdmin = when {
        oneUi9 -> "$security › More security settings › Device admin apps"
        samsung -> "$security › More security settings › Other security settings › Device admin apps"
        else -> "Settings › Apps › Special app access › Device admin apps"
    }
    val notificationAccess = when {
        samsung -> "Settings › Apps › Special app access › Notification access"
        api >= 34 -> "Settings › Apps › Special app access › Notification read, reply & control"
        else -> "Settings › Apps › Special app access › Device & app notifications"
    }
    val usageAccess = "Settings › Apps › Special app access › Usage access"
    val overlay = if (samsung) "Settings › Apps › Special app access › Appear on top" else "Settings › Apps › Special app access › Display over other apps"
    val keyboards = when {
        samsung -> "Settings › General management › Keyboard list and default"
        api >= 34 -> "Settings › System › Keyboard › On-screen keyboard"
        else -> "Settings › System › Languages & input › On-screen keyboard"
    }
    val languages = when {
        samsung -> "Settings › General management › Languages"
        api >= 34 -> "Settings › System › Languages"
        else -> "Settings › System › Languages & input › Languages"
    }
    val ads = when {
        samsung -> "$security › More privacy settings › Ads"
        api >= 34 -> "Settings › Google › All services › Ads"
        else -> "Settings › Privacy › Ads"
    }
    val bluetooth = if (samsung) "Settings › Connections › Bluetooth" else "Settings › Connected devices"
    val developerOptions = if (samsung) "Settings › Developer options" else "Settings › System › Developer options"
    val accessibilityGroup = if (samsung) "Installed apps" else "Downloaded apps"
    /** Android 16 and later, on Google's own route on every maker. */
    val advancedProtection = if (api >= 36) "Settings › Google › All services › Advanced Protection" else null

    companion object {
        val here = Directions(Build.MANUFACTURER.orEmpty().equals("samsung", ignoreCase = true), Build.VERSION.SDK_INT)
    }
}
