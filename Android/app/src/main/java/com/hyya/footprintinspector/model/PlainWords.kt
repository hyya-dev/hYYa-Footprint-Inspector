// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.model

/**
 * Each finding said the way people asked for it, as on iOS (App/Sources/Model/PlainWords.swift):
 * a headline straight to the point, one short line beneath, and the fix as the thing to do. The
 * fuller explanation stays in the catalogue for "More about this".
 */
object PlainWords {
    data class Words(val headline: String, val brief: String, val action: String? = null)

    val text: Map<String, Words> = mapOf(
        // Who can watch you
        "watch-screen" to Words("Some apps can read your screen", "An accessibility service can see everything on screen, including messages, and act for you.", "Turn off services you don't recognise"),
        "watch-notifications" to Words("Some apps can read every notification", "That includes messages and sign-in codes as they arrive.", "Remove notification access you don't need"),
        "watch-admin" to Words("Some apps can lock or erase this device", "Device admin apps can't be uninstalled until you turn this off.", "Turn off device admin you don't recognise"),
        "watch-several" to Words("One app holds several of these powers", "Together they let it see your screen, read your messages and lock you out.", "Check that app, and remove it if you don't know it"),
        // This device
        "device-name" to Words("Apps can see your device's name", "It often includes your first name, and nearby devices can see it too.", "Give your device a name without yours"),
        "model" to Words("Apps can see your exact model", "Millions of people share it, so it says little on its own."),
        "system-version" to Words("Apps can see your system version", "Common and harmless. Staying up to date keeps you in the biggest crowd.", "Install system updates"),
        "build-fingerprint" to Words("Apps can see your exact software build", "It's the same for everyone on your model and update."),
        // System
        "boot-time" to Words("Your last restart time gives you away", "Apps can read the exact moment you last restarted. It's rare enough to recognise you, until your next restart.", "Restart once a week"),
        "boot-count" to Words("Apps can count how often you've restarted", "Together with your last restart, that count is close to unique.", "Restart once a week"),
        "battery" to Words("Apps can see your battery level", "It changes all the time, but two apps opened minutes apart see almost the same number."),
        "developer-options" to Words("Apps can see if developer options are on", "Few people turn them on, so it makes your device stand out.", "Turn off developer options"),
        // Storage
        "disk-total" to Words("Apps can see your storage size", "Shared by everyone with the same size."),
        "disk-free" to Words("Apps can see your free space, to the byte", "That number is almost unique and changes slowly, so apps can use it to recognise you."),
        "memory" to Words("Apps can see your memory and processor", "Every device of your model shares them."),
        // Screen, sound, language
        "screen" to Words("Apps can see your screen settings", "Mostly the same as others with your model."),
        "text-size" to Words("Apps can see your text and display size", "A larger size can hint at eyesight needs. Keep the size you need."),
        "audio-route" to Words("Apps can see your headphones' name", "Names like \"Sam's earbuds\" give away a first name. Renaming them fixes it.", "Rename your headphones"),
        "languages" to Words("Apps can see your languages", "An unusual mix is rare and can hint at where you're from.", "Remove languages you don't use"),
        "keyboards" to Words("Apps can see your keyboards", "They show which languages you write in, and a keyboard app sees what you type.", "Turn off keyboards you don't use"),
        "timezone" to Words("Apps can see your time zone", "It points to roughly where you are, even with a VPN."),
        // Accessibility and appearance
        "accessibility" to Words("Apps can see your accessibility services", "Some can hint at a disability. Keep what you need; it's just worth knowing.", "Turn off services you don't use"),
        "appearance" to Words("Apps can see light or dark theme", "A small detail shared by millions."),
        // Sensors and network
        "sensors" to Words("Apps can read your sensors", "The exact set points to your model, and tiny factory differences can single out a device."),
        "cameras" to Words("Apps can see your cameras", "The line-up points to your exact model."),
        "connection" to Words("Apps can see your connection type", "Wi-Fi or mobile data: a passing detail."),
        "vpn" to Words("Apps can see that you use a VPN", "A VPN hides your address, but not the fact that it's on."),
        "carrier" to Words("Apps can see your mobile carrier and country", "It points to where you live, even with a VPN."),
        "screen-lock" to Words("Apps can see if you use a screen lock", "Never the lock itself, only whether one is set.", "Set a screen lock"),
        // Apps and reinstall
        "default-browser" to Words("Apps can see your default browser", "A less common browser makes you a little easier to tell apart."),
        "android-id" to Words("Apps can recognise you after you delete them", "Each app's code for this device survives deleting and reinstalling it. Only a factory reset clears it."),
        // Once you allow it
        "loc-where" to Words("Apps you allow can see where you are", "Often to within a few metres. Checked a few times a day, it shows where you live and work.", "Limit which apps see your location"),
        "loc-precise" to Words("Apps you allow can see your exact spot", "Turning off precise location gives them only a rough area.", "Turn off precise location where it's not needed"),
        "bt-paired" to Words("Apps you allow can see your paired devices", "Names like \"Sam's earbuds\" can show who you live or work with.", "Limit Nearby devices access"),
        "bt-name" to Words("Apps you allow can see your Bluetooth name", "It's often your name, and nearby devices see it too.", "Limit Nearby devices access"),
        "contact-count" to Words("Apps you allow can see your address book", "How many people you know, and with access, every name and number.", "Limit which apps see your contacts"),
        "contact-labels" to Words("Apps you allow can see your contact labels", "Labels you typed, such as family roles, hint at who matters to you.", "Limit which apps see your contacts"),
        "contact-accounts" to Words("Apps you allow can see where your contacts come from", "A work account suggests where you're employed.", "Limit which apps see your contacts"),
        "cal-accounts" to Words("Apps you allow can see your calendar accounts", "Their names often include your email or employer.", "Limit which apps see your calendars"),
        "cal-busy" to Words("Apps you allow can see how busy you are", "Your fullest days, and with access, every event and guest.", "Limit which apps see your calendars"),
    )
}

/** Straight to the point: what an app can see. */
val Definition.headline: String get() = PlainWords.text[id]?.headline ?: title
/** One short line on why it matters. */
val Definition.brief: String get() = PlainWords.text[id]?.brief ?: reveals
/** What to do about it, as a short instruction. */
val Definition.fixTitle: String get() = PlainWords.text[id]?.action ?: headline
