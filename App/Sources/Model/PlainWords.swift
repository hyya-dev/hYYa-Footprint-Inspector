// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// Each finding said the way people asked for it: a headline that gets straight to the point, and
/// one short line beneath. The fuller explanation stays in the catalogue for "More about this".
/// Findings without an entry here fall back to their title and explanation.
enum PlainWords {
    static let text: [String: (headline: String, brief: String)] = [
        // Device identity
        "idfv": ("One company's apps can link what you do", "Every app from the same company sees the same code on this device, so the company can join up what you do in each of them."),
        "device-name": ("Apps can see your device's name", "Usually it's just the model. A few apps can see the name you gave it, which often includes your first name."),
        "os-version": ("Apps can see your system version", "Common and harmless. Staying up to date keeps you in the biggest crowd."),
        "os-build": ("Apps can see if you run test versions", "Test (beta) versions and rare builds make your device stand out."),
        "model-id": ("Apps can see your exact model", "Millions of people share it, so it says little on its own."),
        "kernel-version": ("Apps can see the system's inner version", "It's the same for everyone on your system version."),

        // System
        "cpu-ram": ("Apps can see your processor and memory", "Every device of your model shares them."),
        "boot-time": ("Your last restart time gives you away", "Apps can read the exact moment you last restarted. It's rare enough to recognise you, until your next restart."),
        "low-power": ("Apps can see if Low Power Mode is on", "A small detail that changes often."),
        "battery": ("Apps can see your battery level", "It changes all the time, but two apps opened minutes apart see almost the same number."),
        "thermal": ("Apps can see if your device is warm", "A passing detail that says little about you."),

        // Storage
        "disk-total": ("Apps can see your storage size", "Shared by everyone with the same size."),
        "disk-free": ("Apps can see your free space, to the byte", "That number is almost unique and changes slowly, so apps can use it to recognise you."),
        "volume-created": ("Apps can see when this device was set up", "The exact second is almost unique and lasts for years. Only Apple can hide it."),

        // Display
        "screen": ("Apps can see your screen settings", "Mostly the same as others with your model. Display Zoom makes you a little rarer."),
        "brightness": ("Apps can see your screen brightness", "It hints at whether you're in a dark room or outdoors, but changes all the time."),
        "text-size": ("Apps can see your text size", "A larger size can hint at eyesight needs. Keep the size you need."),

        // Audio
        "audio-route": ("Apps can see your headphones' name", "Names like \"Sam's AirPods\" give away a first name. Renaming them fixes it."),
        "volume": ("Apps can see your volume level", "It changes slowly, which helps link your visits together."),
        "other-audio": ("Apps can see if something else is playing", "A passing detail."),

        // Language, region, time
        "languages": ("Apps can see your languages", "An unusual mix is rare and can hint at where you're from."),
        "keyboards": ("Apps can see your keyboards", "They show which languages you write in."),
        "region": ("Apps can see your region and formats", "Every change from the usual settings makes you easier to tell apart."),
        "timezone": ("Apps can see your time zone", "It points to roughly where you are, even with a VPN."),

        // Accessibility and appearance
        "accessibility": ("Apps can see your accessibility settings", "Some can hint at a disability. Keep what you need; it's just worth knowing."),
        "appearance": ("Apps can see light or dark mode", "A small detail shared by millions."),

        // Clipboard
        "clip-count": ("Apps can count how often you copy", "Two apps that read the same count can link you. Restarting resets it."),
        "clip-kinds": ("Apps can see what kind of thing you copied", "Not what it says, just whether it's text, a link or a picture."),

        // Motion sensors
        "motion-raw": ("Apps can read your motion sensors", "They can show how you move, and tiny factory differences can single out your device. Only Apple can limit this."),
        "heading": ("Apps can see which way you're facing", "A compass reading, with no location permission."),

        // Network
        "connection": ("Apps can see your connection type", "Wi-Fi or mobile data: a passing detail."),
        "vpn": ("Apps can see that you use a VPN", "A VPN hides your address, but not the fact that it's on."),
        "local-ip": ("Apps can see your device's network addresses", "Some can point to your home network. Private Wi-Fi addresses help."),

        // Fonts and voices
        "fonts": ("Apps can see your fonts", "Fonts you installed make your device stand out."),
        "voices": ("Apps can see your downloaded voices", "They hint at the languages you use or accessibility needs."),

        // Account and App Store
        "storefront": ("Apps can see your App Store country", "A VPN doesn't change it."),
        "install-date": ("Apps can see when you installed them", "It's on the app's own files, and resets if you reinstall."),
        "first-download": ("Apps can see when your account first got them", "It survives deleting the app and moving to a new device."),

        // Graphics and mobile
        "gpu": ("Apps can see your graphics chip", "Every device of your model shares it."),
        "cellular": ("Apps can see your mobile plans", "How many SIMs or eSIMs you have, and whether you're on 4G or 5G."),

        // Security set-up
        "passcode": ("Apps can see if you use a passcode", "Never the passcode itself, only whether one is set."),
        "apple-pay": ("Apps can see if Apple Pay is set up", "Only which card networks, never your cards."),
        "mail-messages": ("Apps can see if Mail and Messages are set up", "Only whether they're set up, nothing inside them."),
        "tracking": ("Apps can see if they may ask to track you", "Turning tracking requests off tells every app no."),
        "managed": ("Apps may see if an organisation manages this device", "Normal on a work device. This check can't see every profile, so look in Settings for any you don't recognise."),
        "location-services": ("Apps can see if Location Services is on", "Only the switch, not where you are."),

        // Clever tricks
        "web-fingerprint": ("Web pages inside apps can fingerprint you", "They read your screen, languages and graphics to tell devices apart. Your browser protects you better."),
        "reinstall-memory": ("Apps can recognise you after you delete them", "They can leave a note that survives deleting the app. Only Apple can stop this."),

        // Once you allow it
        "motion-activity": ("Apps you allow can see your daily routine", "Walking, driving and still, minute by minute for a week, shows when you leave home and go to bed."),
        "motion-steps": ("Apps you allow can see your steps", "Steps, distance and floors climbed, going back several days."),
        "motion-pressure": ("Apps you allow can see your altitude", "Small changes in air pressure show when you go up or down a floor."),
        "loc-where": ("Apps you allow can see where you are", "Often to within a few metres. Checked a few times a day, it shows where you live and work."),
        "loc-altitude": ("Apps you allow can see your altitude and floor", "In some buildings, even which floor you're on."),
        "loc-speed": ("Apps you allow can see your speed", "How fast you move and which way, which tells walking from driving."),
        "loc-precise": ("Apps you allow can see your exact spot", "Turning off Precise Location gives them only a rough area."),
        "cam-list": ("Apps you allow can see your cameras", "The line-up points to your exact model."),
        "ble-nearby": ("Apps you allow can see devices near you", "Names like \"Sam's AirPods\" can show who you live or work with, and where you are."),
        "lan-devices": ("Apps you allow can see devices on your Wi-Fi", "Speakers, TVs and printers, often named, make a mix unique to your home or office."),
        "contact-count": ("Apps you allow can see your address book", "How many people you know, and with full access, every name and number."),
        "contact-labels": ("Apps you allow can see your contact labels", "Labels you typed, such as family roles, hint at who matters to you."),
        "contact-accounts": ("Apps you allow can see where your contacts come from", "A work account suggests where you're employed."),
        "photo-places": ("Apps you allow can map where you've been", "Most photos carry the spot where they were taken, going back years."),
        "photo-home-work": ("Apps you allow can guess your home and work", "The places that appear most often in your photos give them away."),
        "photo-library": ("Apps you allow can see your library size", "How many photos and albums you have, and whether you share albums."),
        "cal-accounts": ("Apps you allow can see your calendar accounts", "Their names often include your email or employer."),
        "cal-busy": ("Apps you allow can see how busy you are", "Your fullest days, and with full access, every event and guest."),
        "rem-lists": ("Apps you allow can see your reminder lists", "List names, such as a pharmacy or a visa, can say a lot about your life."),
        "rem-open": ("Apps you allow can see your to-do list", "How much is on it and how much is overdue."),
        "music-library": ("Apps you allow can see your music library", "How many songs and playlists you have, and what you added lately."),
        "music-taste": ("Apps you allow can see your music taste", "Taste can hint at your age, background or faith."),
        "music-sub": ("Apps you allow can see if you pay for Apple Music", "Advertisers read it as a hint about spending."),

        // On a Mac
        "mac-full-name": ("Apps can see your full name", "The name on your Mac account, exactly as you typed it, with no permission asked."),
        "mac-account-name": ("Apps can see your account name", "It's often your first name or initials, and it's the name of your home folder."),
        "mac-admin": ("Apps can see if you're an administrator", "A small detail on its own."),
        "mac-serial": ("Apps can see your Mac's serial number", "It's unique to this Mac and never changes, so any app can recognise you by it."),
        "mac-hardware-id": ("Apps can see a permanent code for this Mac", "Like the serial number, it's unique and survives erasing the Mac."),
        "mac-model": ("Apps can see your exact model and chip", "It narrows down who you are and roughly what you paid."),
        "mac-system-version": ("Apps can see your macOS version", "Common and harmless. Staying up to date keeps you in the biggest crowd."),
        "mac-computer-name": ("Apps can see your Mac's name", "It often includes your first name, and devices on your Wi-Fi see it too."),
        "mac-graphics": ("Apps can see your graphics chip", "It points to how new your Mac is."),
        "mac-boot-time": ("Your last restart time gives you away", "Apps can read the exact moment your Mac last started. It's rare enough to recognise you, until your next restart."),
        "mac-battery": ("Apps can see your battery level", "Two apps opened minutes apart see almost the same number."),
        "mac-drives": ("Apps can see your drives' names", "Names like a backup drive with your name in it give you away."),
        "mac-screens": ("Apps can see your screens", "An external monitor's model makes your setup rarer."),
        "mac-audio": ("Apps can see your sound devices' names", "Names like \"Sam's AirPods\" give away a first name."),
        "mac-usb": ("Apps can see what's plugged into your Mac", "A connected phone or a work security key says a lot about you."),
        "mac-languages": ("Apps can see your languages", "An unusual mix is rare and can hint at where you're from."),
        "mac-input-sources": ("Apps can see your keyboards", "They show which languages you write in."),
        "mac-region": ("Apps can see your region and formats", "Every change from the usual settings makes you easier to tell apart."),
        "mac-timezone": ("Apps can see your time zone", "It points to roughly where you are, even with a VPN."),
        "mac-accessibility": ("Apps can see your accessibility settings", "Some can hint at a disability. Keep what you need; it's just worth knowing."),
        "mac-appearance": ("Apps can see your theme and accent colour", "A small detail shared by many."),
        "mac-clipboard": ("Apps can see what kind of thing you copied", "And how often you copy, which can link you across apps."),
        "mac-connection": ("Apps can see your connection type", "Wi-Fi, Ethernet or a hotspot: a passing detail."),
        "mac-hardware-addresses": ("Apps can see your Mac's network hardware codes", "They're unique to this Mac and rarely change, so they follow it between networks."),
        "mac-dns": ("Apps can see your router and network names", "Network names often reveal your home or workplace."),
        "mac-fonts": ("Apps can see your fonts", "Fonts that come with other apps reveal what you work with."),
        "mac-installed-apps": ("Apps can see every app on this Mac", "Your apps can reveal your work, health, faith or politics."),
        "mac-running-apps": ("Apps can see what you're running right now", "Such as which banking or messaging app is open."),
        "mac-default-browser": ("Apps can see your default browser", "A less common browser makes you a little easier to tell apart."),
    ]
}

extension PlainWords {
    /// The fix said as the thing to do, for "Fix them with me" and the score's to-do list.
    static let action: [String: String] = [
        "idfv": "Delete apps from companies you no longer use",
        "device-name": "Give your device a name without yours",
        "os-version": "Turn on automatic updates",
        "os-build": "Leave test (beta) updates",
        "boot-time": "Restart once a week",
        "audio-route": "Rename your headphones",
        "languages": "Remove languages you don't use",
        "keyboards": "Remove keyboards you don't use",
        "region": "Set back formats you don't need",
        "clip-count": "Restart once a week",
        "clip-kinds": "Clear the clipboard",
        "local-ip": "Turn on Private Wi-Fi Address",
        "fonts": "Remove fonts you don't use",
        "voices": "Delete voices you don't use",
        "cellular": "Remove eSIMs you don't use",
        "passcode": "Set a passcode",
        "tracking": "Turn off tracking requests",
        "managed": "Check for profiles you don't recognise",
        "web-fingerprint": "Turn on Safari's fingerprinting protection",
        "motion-activity": "Limit which apps see your activity",
        "motion-steps": "Limit which apps see your activity",
        "motion-pressure": "Limit which apps see your activity",
        "loc-where": "Limit which apps see your location",
        "loc-altitude": "Limit which apps see your location",
        "loc-speed": "Limit which apps see your location",
        "loc-precise": "Turn off Precise Location where it's not needed",
        "cam-list": "Limit camera access",
        "ble-nearby": "Limit Bluetooth access",
        "lan-devices": "Limit Local Network access",
        "contact-count": "Limit which apps see your contacts",
        "contact-labels": "Limit which apps see your contacts",
        "contact-accounts": "Limit which apps see your contacts",
        "photo-places": "Give apps only the photos they need",
        "photo-home-work": "Give apps only the photos they need",
        "photo-library": "Give apps only the photos they need",
        "cal-accounts": "Limit which apps see your calendars",
        "cal-busy": "Limit which apps see your calendars",
        "rem-lists": "Limit which apps see your reminders",
        "rem-open": "Limit which apps see your reminders",
        "music-library": "Limit which apps see your music",
        "music-taste": "Limit which apps see your music",
        "music-sub": "Limit which apps see your music",
        "mac-boot-time": "Restart once a week",
        "mac-computer-name": "Give your Mac a name without yours",
        "mac-languages": "Remove languages you don't use",
        "mac-input-sources": "Remove keyboards you don't use",
        "mac-clipboard": "Clear the clipboard",
    ]
}

extension SignalDefinition {
    /// What to do about it, as a short instruction.
    var fixTitle: String { PlainWords.action[id] ?? headline }

    /// Straight to the point: what an app can see.
    var headline: String { PlainWords.text[id]?.headline ?? title }
    /// One short line on why it matters.
    var brief: String { PlainWords.text[id]?.brief ?? reveals }
}
