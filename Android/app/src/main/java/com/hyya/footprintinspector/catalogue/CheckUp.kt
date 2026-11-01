// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.catalogue

import android.content.Intent
import android.provider.Settings

/**
 * Android never tells one app which other apps hold a permission; only Settings knows. The
 * check-up walks through Settings one area at a time. [action] opens the closest page; every
 * opener falls back to the Settings home if the device doesn't have that page.
 */
data class CheckUpStep(
    val id: String, val title: String, val why: String, val path: String, val actions: List<String>, val action: String,
    /** False for steps added after 1.0.3: finishing Check-up must never lower a score, so people who finished keep their credit. */
    val counts: Boolean = true,
)

object CheckUp {
    private const val PM = "Settings › Security & privacy › Privacy controls › Permission manager (on Samsung: Security and privacy › Permission manager)"

    val steps = listOf(
        CheckUpStep("safety", "Start with the privacy check", "Android's own overview of your privacy and security settings, in one place.",
            "Settings › Security & privacy", listOf("Follow any suggestions it shows.", "Open Privacy dashboard to see which apps used your location, camera and microphone recently."),
            Intent.ACTION_SAFETY_CENTER),
        CheckUpStep("screen-lock", "Lock your device", "Your screen lock protects everything else on this device. A short screen timeout locks it soon after you put it down.",
            "Android 14 or later: Settings › Security & privacy › Device unlock › Screen lock. Android 13: Settings › Security › Screen lock. Samsung: Settings › Security and privacy › Screen lock and biometrics",
            listOf("Use a PIN of at least six digits, or a password.", "Set the screen to turn off after 30 seconds or 1 minute: Settings › Display › Screen timeout. On Android 15 and 16, Display is called Display & touch.",
                "Menu names vary by maker. If you can't see it, search for Screen lock in Settings."),
            Settings.ACTION_SECURITY_SETTINGS, counts = false),
        CheckUpStep("google-account", "Protect your Google Account", "Your Google Account can hold your passwords, photos and backups. 2-Step Verification protects it even if your password leaks.",
            "Settings › Google › Manage your Google Account › Security › 2-Step Verification",
            listOf("Turn on 2-Step Verification.", "Check that your recovery phone and email are up to date.", "This works the same on every Android version this app supports."),
            Settings.ACTION_SETTINGS, counts = false),
        CheckUpStep("find-device", "Be able to find your device", "If you lose your device, you can see where it is, lock it or erase it from another device.",
            "Android 14 or later: Settings › Security & privacy › Device finders › Find Hub. Android 13: Settings › Security › Find My Device. Samsung: Settings › Security and privacy › Lost device protection › Find My Mobile",
            listOf("Check that finding this device is turned on.", "Find Hub used to be called Find My Device, so your version may still use that name. It's the same service."),
            Settings.ACTION_SECURITY_SETTINGS, counts = false),
        CheckUpStep("theft-protection", "Theft protection", "If someone takes your device, these features can lock the screen quickly and keep your information out of reach.",
            "Android: Settings › Google › All services › Theft protection. Samsung with One UI 7 or later: Settings › Security and privacy › Lost device protection › Theft protection",
            listOf("Turn on Theft Detection Lock, Offline Device Lock and Remote Lock.", "If you see Identity Check, turn it on too. Only some devices have it.",
                "Samsung with One UI 6.1 or earlier: use the Android path. If an option is greyed out, your device doesn't support it. Tablets don't have these features."),
            Settings.ACTION_SETTINGS, counts = false),
        CheckUpStep("updates", "Keep the system updated", "Updates close the holes that spyware uses to get in. It's the single best protection there is.",
            "Settings › System › Software updates (on Samsung: Settings › Software update)",
            listOf("Install any update that's waiting.", "Also update apps in the Play Store, and turn on automatic updates."),
            "android.settings.SYSTEM_UPDATE_SETTINGS"),
        CheckUpStep("restart", "Restart once a week", "Some spyware lives only in memory and is cleared by a restart. It also gives apps a new restart time, so they can't use it to recognise you.",
            "Press and hold the power button (on some devices, power and volume up together)",
            listOf("Tap Restart.", "Do it again next week."), Settings.ACTION_SETTINGS),
        CheckUpStep("passwords", "Check for leaked passwords", "Google's Password Checkup warns you when a saved password has turned up in a known data leak. It checks without revealing your passwords, and this app sees nothing.",
            "Settings › Passwords & accounts › Google › Password Manager › Checkup",
            listOf("Run Password Checkup.", "Change any password marked as leaked, reused or weak."), Settings.ACTION_SETTINGS),
        CheckUpStep("protection", "Protection from harmful apps", "Google Play Protect checks your apps for harm, and on Android 16 and later, Advanced Protection is Google's strongest defence for people at risk, such as journalists and activists.",
            "Play Store › your profile picture › Play Protect, then Settings › Security & privacy › Advanced Protection",
            listOf("In Play Protect, tap Scan, and keep Scan apps with Play Protect on.", "If your work could make you a target, turn on Advanced Protection.", "Otherwise, keep your system and apps updated."),
            Settings.ACTION_SECURITY_SETTINGS),
        CheckUpStep("location", "Location", "Your location shows where you live, work and spend time.",
            "$PM › Location", listOf("Choose Don't allow, or Allow only while using the app.", "Turn off Use precise location for apps that only need your area."),
            Settings.ACTION_PRIVACY_SETTINGS),
        CheckUpStep("contacts", "Contacts", "Your contacts include other people's numbers and addresses, not just yours.",
            "$PM › Contacts", listOf("Turn off access for apps that don't need it."), Settings.ACTION_PRIVACY_SETTINGS),
        CheckUpStep("camera-mic", "Camera and microphone", "Only apps you use for calls, video or photos should have these.",
            "$PM › Camera, then Microphone", listOf("Turn off any app you don't use for calls, video or photos."), Settings.ACTION_PRIVACY_SETTINGS),
        CheckUpStep("photos", "Photos and videos", "Full access lets an app see every picture and where each one was taken.",
            "$PM › Photos and videos", listOf("Choose Allow limited access, or Don't allow, for apps that don't need them all."), Settings.ACTION_PRIVACY_SETTINGS),
        CheckUpStep("nearby", "Nearby devices", "Lets apps see devices around you, often named after their owners.",
            "$PM › Nearby devices", listOf("Turn off any app that doesn't connect to a device of yours."), Settings.ACTION_PRIVACY_SETTINGS),
        CheckUpStep("notifications", "Notification access", "Apps here can read every notification, including messages and codes.",
            "Settings › Apps › Special app access › Notification read, reply & control", listOf("Remove any app you don't recognise or no longer use."),
            Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS),
        CheckUpStep("usage", "Usage access", "Apps here can see which apps you use, when and for how long.",
            "Settings › Apps › Special app access › Usage access", listOf("Remove any app that doesn't truly need it."), Settings.ACTION_USAGE_ACCESS_SETTINGS),
        CheckUpStep("accessibility", "Accessibility services", "These can read your screen and act for you: the most powerful access on Android.",
            "Settings › Accessibility", listOf("Keep only services you need and trust."), Settings.ACTION_ACCESSIBILITY_SETTINGS),
        CheckUpStep("device-admin", "Device admin apps", "These apps can lock or erase your device, and can't be uninstalled until you turn them off.",
            "Settings › Security & privacy › More security settings › Device admin apps (on Samsung: Security and privacy › Other security settings › Device admin apps)",
            listOf("Turn off any app you don't recognise. Work and school apps may need it."), Settings.ACTION_SECURITY_SETTINGS),
        CheckUpStep("keyboards", "Keyboards", "A keyboard app can see everything you type in it.",
            "Settings › System › Keyboard", listOf("Turn off keyboards you don't use, especially ones you don't fully trust."), Settings.ACTION_INPUT_METHOD_SETTINGS),
        CheckUpStep("overlay", "Display over other apps", "Apps here can draw on top of other apps, which can be used to trick you.",
            "Settings › Apps › Special app access › Display over other apps", listOf("Turn it off for apps that don't need it."), Settings.ACTION_MANAGE_OVERLAY_PERMISSION),
        CheckUpStep("ads", "Advertising ID", "Unless you delete it, apps can read a shared advertising code that follows you between them.",
            "Settings › Security & privacy › More privacy settings › Ads (on Samsung: Settings › Google › Ads)", listOf("Tap Delete advertising ID."),
            Settings.ACTION_PRIVACY_SETTINGS),
        CheckUpStep("device-name", "Your device's name", "Your device's name is visible to every app and to nearby devices.",
            "Settings › About phone (or About tablet) › Device name", listOf("Choose a name that doesn't include yours."), Settings.ACTION_DEVICE_INFO_SETTINGS),
    )
}
