// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.catalogue

import android.provider.Settings
import com.hyya.footprintinspector.model.Definition
import com.hyya.footprintinspector.model.Fix
import com.hyya.footprintinspector.model.Persistence.CHANGES_OFTEN
import com.hyya.footprintinspector.model.Persistence.HARDWARE
import com.hyya.footprintinspector.model.Persistence.UNTIL_RESET
import com.hyya.footprintinspector.model.Persistence.UNTIL_RESTART
import com.hyya.footprintinspector.model.Persistence.UNTIL_UPDATE
import com.hyya.footprintinspector.model.Persistence.UNTIL_YOU_CHANGE_IT
import com.hyya.footprintinspector.model.Section
import com.hyya.footprintinspector.model.Severity.HIGH
import com.hyya.footprintinspector.model.Severity.LOW
import com.hyya.footprintinspector.model.Severity.MEDIUM

/**
 * Every Android finding. Same rules as iOS: plain words, "could" rather than "will", every entry
 * says what an app learns, why the system allows it, how long it lasts and what to do.
 * Device-neutral: "device", never a brand of phone.
 */
object Catalogue {
    private val restart = Fix.guided("Restarting your device gives this a new value.",
        "Press and hold the power button (on some devices, power and volume up together).",
        "Tap Restart.")

    val list: List<Definition> = listOf(
        // Who can watch you. Never "spyware": holding the access is the fact we can show.
        Definition("watch-screen", Section.WATCH, "Apps that can read your screen",
            "Apps you've given accessibility access can read everything on your screen, including messages and what you type, and can tap for you.",
            "Accessibility services exist for people who need help using their device, like screen readers. The same access works for any app you turn it on for.",
            UNTIL_YOU_CHANGE_IT, MEDIUM,
            Fix.settings("Turn off any service you don't know or no longer use. Screen readers and tools you rely on are fine to keep.",
                Settings.ACTION_ACCESSIBILITY_SETTINGS,
                "Open Settings › Accessibility.", "Look under Downloaded apps (or Installed apps).", "Tap any service you don't recognise and turn it off.")),
        Definition("watch-notifications", Section.WATCH, "Apps that can read every notification",
            "Apps with notification access can read every notification as it arrives: messages, codes, emails and who they're from.",
            "So watches, car systems and similar apps can show your notifications.",
            UNTIL_YOU_CHANGE_IT, MEDIUM,
            Fix.settings("Remove notification access from any app you don't recognise. A watch or car app you set up yourself needs it.",
                Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS,
                "Open Settings › Apps › Special app access › Notification read, reply & control.", "Turn off any app you don't recognise.")),
        Definition("watch-admin", Section.WATCH, "Apps that can lock or erase this device",
            "A device admin app can lock your device, change your screen-lock rules or erase everything, and can't be uninstalled until you turn it off.",
            "For work and school devices, and for finding a lost device.",
            UNTIL_YOU_CHANGE_IT, MEDIUM,
            Fix.settings("Turn off device admin for any app you don't recognise. Work and school apps may need it.",
                Settings.ACTION_SECURITY_SETTINGS,
                "Open Settings › Security & privacy › More security settings › Device admin apps.",
                "Turn off any app you don't recognise. After that you can uninstall it.")),
        Definition("watch-several", Section.WATCH, "Apps with more than one of these",
            "One app holding two or more of these can see what's on your screen, read your messages or lock you out. That combination is how monitoring apps work. Parental-control and work apps hold it too, so check you know each one.",
            "Each access has a real use on its own, and Android doesn't warn you when one app gathers several.",
            UNTIL_YOU_CHANGE_IT, HIGH,
            Fix.settings("If you don't know the app, remove it.",
                Settings.ACTION_APPLICATION_SETTINGS,
                "If it's a device admin app, turn that off first (Settings › Security & privacy › More security settings › Device admin apps).",
                "Open Settings › Apps, find the app and tap Uninstall.",
                "If someone else set up this device and you don't feel safe, Safety Check in Settings › Security & privacy can help you review who has access.")),

        // This device
        Definition("device-name", Section.IDENTITY, "Device name",
            "The name you gave your device, readable by any app without asking. Names like \"Sam's Pixel\" hand over a first name.",
            "So you can tell your devices apart when sharing or connecting.",
            UNTIL_YOU_CHANGE_IT, HIGH,
            Fix.settings("Give your device a name that doesn't include yours.", Settings.ACTION_DEVICE_INFO_SETTINGS,
                "Open Settings › About phone (or About tablet).", "Tap Device name and choose something generic.")),
        Definition("model", Section.IDENTITY, "Exact model and chip",
            "The maker, exact model and chip of your device. It narrows down who you are and roughly what you paid.",
            "So apps can adjust to your hardware.", HARDWARE, LOW,
            Fix.onlyMaker("This comes with the hardware. There's nothing to change.")),
        Definition("system-version", Section.IDENTITY, "System version",
            "Exactly which Android version and security update you have.",
            "So apps can turn features on or off.", UNTIL_UPDATE, LOW,
            Fix.settings("Keeping up to date puts you in the biggest crowd and gets you the latest privacy fixes.", Settings.ACTION_DEVICE_INFO_SETTINGS,
                "Open Settings › System › Software updates (on Samsung: Software update).", "Install any update waiting.")),
        Definition("build-fingerprint", Section.IDENTITY, "Build fingerprint",
            "A long label naming your device's maker, model and exact software build. Few devices share it on any given day.",
            "So developers can match problem reports to the right software.", UNTIL_UPDATE, MEDIUM,
            Fix.onlyMaker("It changes only with a system update. Google could hide the detail from apps.")),

        // System
        Definition("boot-time", Section.SYSTEM, "Last restart",
            "The exact second your device last started. Few devices share it, so it can link you across apps until you restart.",
            "So apps can measure time that has passed.", UNTIL_RESTART, HIGH, restart),
        Definition("boot-count", Section.SYSTEM, "How many times it has started",
            "A count of every time your device has started since it was set up. Combined with the last restart, it's close to unique.",
            "It's a system setting any app can read.", UNTIL_RESET, MEDIUM,
            Fix.onlyMaker("No setting changes it, and only a factory reset clears it. Google could hide it.")),
        Definition("battery", Section.SYSTEM, "Battery level",
            "Your exact charge and whether you're charging. Two apps opened minutes apart see almost the same number, which can link them.",
            "So apps can put off heavy work when the battery is low.", CHANGES_OFTEN, LOW,
            Fix.leaveIt("Not worth changing. It's a small detail.")),
        Definition("developer-options", Section.SYSTEM, "Developer options",
            "Whether developer options and USB debugging are on. It marks you as technical, and some apps treat it as a risk signal.",
            "So apps can warn about debugging tools.", UNTIL_YOU_CHANGE_IT, MEDIUM,
            Fix.settings("Turn developer options off if you don't use them.", Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS,
                "Open Settings › System › Developer options.", "Turn off Use developer options at the top.")),

        // Storage and memory
        Definition("disk-total", Section.STORAGE, "Total storage", "Your storage size (128 GB, 256 GB…).",
            "So apps can plan downloads.", HARDWARE, LOW, Fix.onlyMaker("This comes with the hardware. There's nothing to change.")),
        Definition("disk-free", Section.STORAGE, "Free space, to the byte",
            "Exactly how much space is free. It changes slowly, so two apps that read the same number at about the same time can tell they're on the same device.",
            "So apps can check there's room before downloading.", CHANGES_OFTEN, HIGH,
            Fix.onlyMaker("No setting rounds it off. Google could give apps a rounded number instead.")),
        Definition("memory", Section.STORAGE, "Memory and processor",
            "How much memory your device has and how many processor cores.", "So apps can size their work to your hardware.",
            HARDWARE, LOW, Fix.onlyMaker("This comes with the hardware. There's nothing to change.")),

        // Screen
        Definition("screen", Section.DISPLAY, "Screen details",
            "Your screen's size, sharpness and smoothness. Together they point to your model.",
            "So apps can lay out and draw correctly.", HARDWARE, LOW, Fix.onlyMaker("This comes with the hardware. There's nothing to change.")),
        Definition("text-size", Section.DISPLAY, "Text and display size",
            "The text and display size you chose. A larger size can hint at eyesight needs.",
            "So apps can show text at the size you need.", UNTIL_YOU_CHANGE_IT, MEDIUM,
            Fix.leaveIt("These settings are there for you. Keep the ones you need; we're only pointing out that apps can see them.")),

        // Sound and accessories
        Definition("audio-route", Section.AUDIO, "Connected headphones and speakers",
            "What's playing your audio, by name. Earbuds are often named after their owner, such as \"Sam's Buds\", which hands over a first name.",
            "So apps can play sound on the right device.", CHANGES_OFTEN, MEDIUM,
            Fix.settings("Rename your headphones so the name doesn't include yours.", Settings.ACTION_BLUETOOTH_SETTINGS,
                "Open Settings › Connected devices (on Samsung: Connections › Bluetooth).",
                "Tap the settings icon next to your headphones, then Rename.")),

        // Language, region and time
        Definition("languages", Section.LANGUAGE, "Preferred languages",
            "Your languages, in order. An unusual mix is rare and can hint at where you're from.",
            "So apps can show the right language.", UNTIL_YOU_CHANGE_IT, MEDIUM,
            Fix.settings("Remove languages you don't use.", Settings.ACTION_LOCALE_SETTINGS,
                "Open Settings › System › Languages.", "Remove any language you don't use.")),
        Definition("keyboards", Section.LANGUAGE, "Keyboards",
            "Every keyboard app and language you've turned on. Extra keyboards can see everything you type in them, and their languages show which languages you write in.",
            "So apps can adapt text input.", UNTIL_YOU_CHANGE_IT, MEDIUM,
            Fix.settings("Turn off keyboards you don't use, especially ones you don't fully trust.", Settings.ACTION_INPUT_METHOD_SETTINGS,
                "Open Settings › System › Keyboard (on Samsung: General management › Keyboard list).",
                "Turn off keyboards you don't use.")),
        Definition("timezone", Section.LANGUAGE, "Time zone and clock",
            "Your time zone, close to your city, and whether you use a 24-hour clock. A VPN doesn't hide it.",
            "So times show correctly.", UNTIL_YOU_CHANGE_IT, LOW,
            Fix.leaveIt("Setting the time zone by hand hides it, but breaks alarms and reminders when you travel. Most people should leave it.")),

        // Accessibility and appearance
        Definition("accessibility", Section.ACCESSIBILITY, "Accessibility services",
            "Which accessibility services are on. They're the most powerful thing you can allow: they can read your screen and act for you. Some can also hint at a disability.",
            "So apps can adapt to what you need.", UNTIL_YOU_CHANGE_IT, HIGH,
            Fix.settings("Keep only services you need and trust. Turn off any you don't recognise.", Settings.ACTION_ACCESSIBILITY_SETTINGS,
                "Open Settings › Accessibility.", "Under Downloaded apps (or Installed apps), turn off what you don't use.")),
        Definition("appearance", Section.ACCESSIBILITY, "Light or dark theme",
            "Whether you use the light or dark theme.", "So apps match your look.", UNTIL_YOU_CHANGE_IT, LOW,
            Fix.leaveIt("Not worth changing. It's a small detail.")),

        // Sensors
        Definition("sensors", Section.SENSORS, "Sensors",
            "Every sensor in your device, with its maker and model. The list points to your exact model, and tiny factory differences in sensors can single out one device.",
            "For games, screen rotation and fitness. Apps don't need to ask.", HARDWARE, MEDIUM,
            Fix.onlyMaker("This comes with the hardware. Google could limit what apps see.")),
        Definition("cameras", Section.SENSORS, "Cameras",
            "How many cameras you have, which way they face and how sharp they are, without the camera permission.",
            "So camera apps can offer the right lenses.", HARDWARE, LOW,
            Fix.onlyMaker("This comes with the hardware. There's nothing to change.")),

        // Network and mobile
        Definition("connection", Section.NETWORK, "Connection type",
            "Whether you're on Wi-Fi or mobile data, and whether it counts as costly.", "So apps can save data on expensive connections.",
            CHANGES_OFTEN, LOW, Fix.leaveIt("Not worth changing. It's a small detail.")),
        Definition("vpn", Section.NETWORK, "VPN in use",
            "Whether a VPN is running. A VPN hides your address from websites, but apps can still see that you use one.",
            "It's visible in the network status any app can read.", CHANGES_OFTEN, LOW,
            Fix.leaveIt("Nothing to fix: a VPN can't hide that it's on. Keep using it if it helps you.")),
        Definition("carrier", Section.NETWORK, "Mobile carrier and country",
            "Your mobile carrier and your SIM's home country, even while you're travelling.",
            "So apps can adapt to your network.", UNTIL_YOU_CHANGE_IT, MEDIUM,
            Fix.onlyMaker("It comes from your SIM. Nothing in Settings hides it.")),

        // Security set-up
        Definition("screen-lock", Section.SECURITY, "Screen lock",
            "Whether a screen lock is set, and whether you use fingerprint or face unlock.",
            "So apps can offer biometric sign-in.", UNTIL_YOU_CHANGE_IT, LOW,
            Fix.settings("A screen lock protects everything else here. If yours isn't set, set one.", Settings.ACTION_SECURITY_SETTINGS,
                "Open Settings › Security & privacy (on Samsung: Lock screen).", "Set a screen lock.")),

        // Apps
        Definition("default-browser", Section.APPS, "Default browser", "Which browser opens your links.",
            "So apps can open links the way you expect.", UNTIL_YOU_CHANGE_IT, LOW,
            Fix.leaveIt("Not worth changing. It's a small detail.")),

        // Remembered after deleting
        Definition("android-id", Section.REINSTALL, "Recognised after you delete an app",
            "A code that's the same every time you install an app from the same company. Delete the app and install it again, and it knows you're back.",
            "It's Android's ID for one company's apps on one device.", UNTIL_RESET, HIGH,
            Fix.onlyMaker("Only a factory reset changes it. Google could make it reset when you delete the app.")),

        // Permission sections
        Definition("loc-where", Section.LOCATION, "Where you are",
            "Your position on a map, often to within a few metres. Checked a few times a day, it shows where you live, work and spend your time.",
            "So maps, delivery and weather apps can work where you are.", CHANGES_OFTEN, HIGH, locationFix),
        Definition("loc-precise", Section.LOCATION, "Precise location",
            "Whether an app gets your exact spot or only a rough area of a few kilometres.",
            "Android added the choice so apps that only need your town don't get your street.", UNTIL_YOU_CHANGE_IT, MEDIUM, locationFix),
        Definition("bt-paired", Section.NEARBY, "Paired devices",
            "Every Bluetooth device you've paired, by name: earbuds, cars, watches. Names like \"Sam's car\" can reveal who you are and what you own.",
            "So apps can connect to accessories.", UNTIL_YOU_CHANGE_IT, MEDIUM, nearbyFix),
        Definition("bt-name", Section.NEARBY, "Bluetooth name",
            "The name your device shows to other Bluetooth devices nearby.", "So nearby devices can find yours.",
            UNTIL_YOU_CHANGE_IT, MEDIUM, nearbyFix),
        Definition("contact-count", Section.CONTACTS, "Size of your address book",
            "How many people you have saved, and how many phone numbers and emails. With this access an app can also read every name, number and address.",
            "So messaging and calling apps can show you who you already know.", CHANGES_OFTEN, MEDIUM, contactsFix),
        Definition("contact-labels", Section.CONTACTS, "Labels you typed",
            "The labels you typed on numbers, such as family roles. They can hint at who matters to you.",
            "Labels come along with each number so apps can show them.", UNTIL_YOU_CHANGE_IT, MEDIUM, contactsFix),
        Definition("contact-accounts", Section.CONTACTS, "Contact accounts",
            "Where your contacts come from, such as Google or a work email account. A work account suggests where you're employed.",
            "So apps can save new contacts to the right place.", UNTIL_YOU_CHANGE_IT, LOW, contactsFix),
        Definition("cal-accounts", Section.CALENDARS, "Calendar accounts",
            "The accounts your calendars come from. Their names are often email addresses, which give away your name and employer.",
            "So apps can add events to the right calendar.", UNTIL_YOU_CHANGE_IT, HIGH, calendarsFix),
        Definition("cal-busy", Section.CALENDARS, "How busy you are",
            "How many events you have. With this access an app can also read every title, place and guest.",
            "So scheduling apps can show your plans.", CHANGES_OFTEN, MEDIUM, calendarsFix),
    )

    private val permissionManagerSteps get() = arrayOf(
        "Open Settings › Security & privacy › Privacy controls › Permission manager (on Samsung: Security and privacy › Permission manager).",
    )
    private val locationFix get() = Fix.settings("Give each app the least it needs, and turn off precise location for apps that only need your area.",
        Settings.ACTION_PRIVACY_SETTINGS, *permissionManagerSteps, "Tap Location, then each app: choose Don't allow, or Allow only while using the app with Use precise location off.")
    private val nearbyFix get() = Fix.settings("Only apps that connect to an accessory need Nearby devices.",
        Settings.ACTION_PRIVACY_SETTINGS, *permissionManagerSteps, "Tap Nearby devices and turn off apps that don't need it.")
    private val contactsFix get() = Fix.settings("Only apps that really need your contacts should have them.",
        Settings.ACTION_PRIVACY_SETTINGS, *permissionManagerSteps, "Tap Contacts and turn off apps that don't need it.")
    private val calendarsFix get() = Fix.settings("Only apps that really need your calendar should have it.",
        Settings.ACTION_PRIVACY_SETTINGS, *permissionManagerSteps, "Tap Calendar and turn off apps that don't need it.")

    val byId: Map<String, Definition> by lazy { list.associateBy { it.id } }
    fun definitions(section: Section) = list.filter { it.section == section }
}
