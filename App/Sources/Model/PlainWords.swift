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
        "boot-time": ("Apps can tell when you last restarted", "That exact moment is rare, so apps can use it to recognise you. Restarting gives it a new value."),
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
        "managed": ("Apps can see if an organisation manages this device", "Normal on a work device. On your own, check for profiles you don't recognise."),
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
    ]
}

extension SignalDefinition {
    /// Straight to the point: what an app can see.
    var headline: String { PlainWords.text[id]?.headline ?? title }
    /// One short line on why it matters.
    var brief: String { PlainWords.text[id]?.brief ?? reveals }
}
