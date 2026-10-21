// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

// MARK: - Needs permission
//
// What an app can see once you say yes to one of its requests. Same wording rules as the
// passive catalogue: calm, plain English, and always a way to give less.
//
// Every fix here is a guided step. Officially we can only open our own Settings page, so we walk
// people to Settings › Privacy & Security › [category], where every app with access is listed.

extension SignalCatalogue {
    static let permission: [SignalDefinition] = [
        // Motion & Fitness
        .init(id: "motion-activity", section: .motion, title: "What you're doing",
              reveals: "Whether you were still, walking, running, cycling or in a car, minute by minute, for up to the past week. From that an app could work out your daily routine and when you commute.",
              why: "So fitness and travel apps can follow your activity without draining the battery.",
              persistence: .changesOften, severity: .high, fix: motionFix),
        .init(id: "motion-steps", section: .motion, title: "Steps, distance and floors",
              reveals: "How many steps you've taken, how far you've gone and how many floors you've climbed, going back several days.",
              why: "So step counters and fitness apps work without a separate device.",
              persistence: .changesOften, severity: .medium, fix: motionFix),
        .init(id: "motion-pressure", section: .motion, title: "Air pressure and altitude",
              reveals: "The air pressure around you and roughly how high above sea level you are. Over time, small changes show when you go up or down a floor.",
              why: "So fitness apps can count climbs and weather apps can sense pressure changes.",
              persistence: .changesOften, severity: .medium, fix: motionFix),

        // Location
        .init(id: "loc-where", section: .location, title: "Where you are",
              reveals: "Your position on a map, often to within a few metres, and how sure the device is about it. Checked a few times a day, it shows where you live, work and spend your time.",
              why: "So maps, delivery and weather apps can work where you are.",
              persistence: .changesOften, severity: .high, fix: locationFix),
        .init(id: "loc-altitude", section: .location, title: "Altitude and floor",
              reveals: "How high you are and, in some mapped buildings, which floor you're on.",
              why: "So indoor maps and outdoor apps can place you correctly.",
              persistence: .changesOften, severity: .medium, fix: locationFix),
        .init(id: "loc-speed", section: .location, title: "Speed and direction",
              reveals: "How fast you're moving and which way you're heading, which tells walking from driving.",
              why: "So navigation apps can follow you along a route.",
              persistence: .changesOften, severity: .medium, fix: locationFix),
        .init(id: "loc-precise", section: .location, title: "Precise Location",
              reveals: "Whether an app gets your exact spot or only a rough area of a few kilometres.",
              why: "Apple added the choice so apps that only need your town don't get your street.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .guided("Turn off Precise Location for any app that only needs to know your area, such as weather or news.", [
                  "Open Settings › Privacy & Security › Location Services.",
                  "Tap the app.",
                  "Turn off Precise Location.",
              ])),

        // Camera
        .init(id: "cam-list", section: .camera, title: "Your cameras",
              reveals: "Which cameras and depth sensors your device has and which way they face. The line-up points to your exact model, for example whether it's a Pro.",
              why: "So camera apps can offer the right lenses.",
              persistence: .hardware, severity: .low,
              fix: .guided("The list itself only reflects your model. What matters more is which apps can use the camera at all.", [
                  "Open Settings › Privacy & Security › Camera.",
                  "Turn off any app that doesn't need to take photos or scan codes.",
              ])),

        // Bluetooth
        .init(id: "ble-nearby", section: .bluetooth, title: "Nearby devices",
              reveals: "Headphones, watches, cars, TVs and trackers within range, often by name. Names like \"Sam's AirPods\" can reveal who you live or work with, and a familiar set of devices can reveal where you are.",
              why: "So apps can connect to accessories such as fitness bands, speakers and smart locks.",
              persistence: .changesOften, severity: .medium,
              fix: .guided("Only apps that connect to an accessory need Bluetooth. Renaming your own devices also helps.", [
                  "Open Settings › Privacy & Security › Bluetooth.",
                  "Turn off any app that doesn't work with an accessory you own.",
                  "To rename one of your devices, open Settings › Bluetooth, tap ⓘ next to it, then tap Name.",
              ])),

        // Local Network
        .init(id: "lan-devices", section: .localNetwork, title: "Devices on your Wi-Fi",
              reveals: "Speakers, TVs, printers, computers and smart-home hubs on the same network, usually with the names they were given. The mix is often unique to one home or office.",
              why: "So apps can cast to a TV, print, or control smart-home devices.",
              persistence: .changesOften, severity: .medium,
              fix: .guided("Only apps that cast, print or control devices need this. Device names without your name help too.", [
                  "Open Settings › Privacy & Security › Local Network.",
                  "Turn off any app that doesn't need to find things on your Wi-Fi.",
                  "Rename devices that carry your name in their own app or settings, for example a Mac in System Settings › General › About.",
              ])),

        // Contacts
        .init(id: "contact-count", section: .contacts, title: "Size of your address book",
              reveals: "How many people you have saved, and how many phone numbers, emails and addresses. With full access an app can also read every name, number, address and photo.",
              why: "So messaging and calling apps can show you who you already know.",
              persistence: .changesOften, severity: .medium, fix: contactsFix),
        .init(id: "contact-labels", section: .contacts, title: "Labels on numbers",
              reveals: "The labels on numbers and emails. Standard ones like Mobile or Home say little, but labels you typed yourself, such as family roles, can hint at who matters to you.",
              why: "Labels come along with each number so apps can show them.",
              // Low by default: standard labels say little. The reader raises it when it finds
              // labels the user typed.
              persistence: .untilYouChangeIt, severity: .low, fix: contactsFix),
        .init(id: "contact-accounts", section: .contacts, title: "Contact accounts",
              reveals: "Where your contacts come from, such as iCloud, Google or a work email account. A work account suggests where you're employed.",
              why: "So apps can save new contacts to the right place.",
              persistence: .untilYouChangeIt, severity: .medium, fix: contactsFix),

        // Photos
        .init(id: "photo-places", section: .photos, title: "Places in your photos",
              reveals: "Most photos carry the spot where they were taken. Read together, they make a map of where you've been, going back years.",
              why: "So photo apps can sort pictures by place.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .guided("Give apps only the photos they need, and stop new photos from recording where they were taken.", [
                  "Open Settings › Privacy & Security › Photos.",
                  "For each app, choose Limited Access (only the photos you pick) or None.",
                  "To stop new location tags, open Settings › Privacy & Security › Location Services › Camera and choose Never.",
                  "When sharing a photo, tap Options at the top of the Share screen and turn off Location.",
              ])),
        .init(id: "photo-home-work", section: .photos, title: "Likely home and work",
              reveals: "The places that appear most often in your photos. Photos taken on weekday working hours or in the evenings make it easy to guess which is work and which is home.",
              why: "It comes from the photo locations alone; no extra permission is needed.",
              persistence: .untilYouChangeIt, severity: .medium, fix: photosFix),
        .init(id: "photo-library", section: .photos, title: "Library size",
              reveals: "How many photos, videos and albums you have, and whether you use shared albums with family or friends.",
              why: "So photo apps can show your library.",
              persistence: .changesOften, severity: .low, fix: photosFix),

        // Calendars
        .init(id: "cal-accounts", section: .calendars, title: "Calendar accounts",
              reveals: "The accounts your calendars come from. Their names are often email addresses or work domains, which can give away your name and employer.",
              why: "So apps can add events to the right calendar.",
              persistence: .untilYouChangeIt, severity: .high, fix: calendarsFix),
        .init(id: "cal-busy", section: .calendars, title: "How busy you are",
              reveals: "How many events you have, which days are fullest, and how many include other people. With full access an app can also read every title, place and guest.",
              why: "So scheduling apps can find free time and show your plans.",
              persistence: .changesOften, severity: .medium, fix: calendarsFix),

        // Reminders
        .init(id: "rem-lists", section: .reminders, title: "Reminder lists",
              reveals: "The names of your lists. Names such as a pharmacy, a baby or a visa application can say a lot about what's going on in your life.",
              why: "So to-do apps can show and sync your lists.",
              persistence: .untilYouChangeIt, severity: .medium, fix: remindersFix),
        .init(id: "rem-open", section: .reminders, title: "Open reminders",
              reveals: "How many things are on your to-do list and how many are overdue. With access an app can read every reminder too.",
              why: "So to-do apps can show what's left.",
              persistence: .changesOften, severity: .low, fix: remindersFix),

        // Media & Apple Music
        .init(id: "music-library", section: .music, title: "Library size",
              reveals: "How many songs, albums, artists and playlists you have, and how much you've added lately.",
              why: "So music apps can play what you own.",
              persistence: .changesOften, severity: .low, fix: musicFix),
        .init(id: "music-taste", section: .music, title: "Your taste",
              reveals: "Your most common genres and artists. Taste can hint at your age, background or faith.",
              why: "So music apps can make suggestions.",
              persistence: .changesOften, severity: .medium, fix: musicFix),
        .init(id: "music-sub", section: .music, title: "Apple Music subscription",
              reveals: "Whether you pay for Apple Music, which advertisers read as a hint about spending.",
              why: "So apps know whether they can play full songs from the catalogue.",
              persistence: .untilYouChangeIt, severity: .low, fix: musicFix),
    ]
}

// MARK: - Fix wording for permission categories

private extension SignalCatalogue {
    static let motionFix = Fix.guided("Only fitness and health apps need this. Turn it off for the rest.", [
        "Open Settings › Privacy & Security › Motion & Fitness.",
        "Turn off any app that isn't a fitness or health app.",
        "If you don't use step counting at all, you can turn off Fitness Tracking at the top.",
    ])

    static let locationFix = Fix.guided("Give each app the least it needs: Never, or While Using with Precise Location off.", [
        "Open Settings › Privacy & Security › Location Services.",
        "Tap an app.",
        "Choose Never, or While Using the App. Avoid Always unless the app truly needs it.",
        "Turn off Precise Location unless the app needs your exact spot, as maps and delivery apps do.",
    ])

    static let contactsFix = Fix.guided("Share only the people an app needs with Limited Access.", [
        "Open Settings › Privacy & Security › Contacts.",
        "Tap an app.",
        "Choose Limited Access and pick only the people it needs, or choose None.",
    ])

    static let photosFix = Fix.guided("Give apps only the photos you pick with Limited Access.", [
        "Open Settings › Privacy & Security › Photos.",
        "Tap an app.",
        "Choose Limited Access and select the photos it needs, or choose None.",
    ])

    static let calendarsFix = Fix.guided("Most apps only need to add events. Add Events Only lets them do that without reading your calendar.", [
        "Open Settings › Privacy & Security › Calendars.",
        "Tap an app.",
        "Choose Add Events Only, or None.",
    ])

    static let remindersFix = Fix.guided("Only to-do apps need your reminders. Turn it off for the rest.", [
        "Open Settings › Privacy & Security › Reminders.",
        "Turn off any app that isn't a to-do or planning app you use.",
    ])

    static let musicFix = Fix.guided("Only music and fitness apps that play your songs need this.", [
        "Open Settings › Privacy & Security › Media & Apple Music.",
        "Turn off any app that doesn't play music from your library.",
    ])
}
