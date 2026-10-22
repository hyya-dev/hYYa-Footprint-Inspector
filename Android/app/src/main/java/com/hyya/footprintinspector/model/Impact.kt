// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.model

/** How serious a finding is, said plainly, as on iOS (App/Sources/Model/SignalImpact.swift). */
object Impact {
    fun level(s: Severity) = when (s) { Severity.HIGH -> "Serious"; Severity.MEDIUM -> "Worth knowing"; Severity.LOW -> "Minor" }

    fun reach(s: Severity) = when (s) {
        Severity.HIGH -> "Enough on its own to tell this device apart from almost every other, so apps and the companies behind them can recognise you."
        Severity.MEDIUM -> "Narrows down who you are. Combined with two or three other clues, it can single out this device."
        Severity.LOW -> "Shared by many devices, so it says little on its own. It only matters alongside other clues."
    }

    fun lasting(p: Persistence) = when (p) {
        Persistence.UNTIL_RESTART -> "It stays the same until you restart, so it can link what you do across apps in the meantime."
        Persistence.UNTIL_REINSTALL -> "It stays until you delete and reinstall the app."
        Persistence.UNTIL_RESET -> "It stays until you reset the device: for most people, the life of the device."
        Persistence.HARDWARE -> "It's fixed for this model, so it can't be changed, only blended in with others like it."
        Persistence.UNTIL_YOU_CHANGE_IT -> "It stays until you change it, which you can do now."
        Persistence.CHANGES_OFTEN -> "It changes often, which makes it weaker for tracking."
        Persistence.UNTIL_UPDATE -> "It stays until you update the system."
        Persistence.PERMANENT -> "It never changes, even if you reset the device, so it can recognise you for as long as you own it."
    }

    val inPractice = mapOf(
        "boot-time" to "Two unrelated apps that both read it can work out they're on the same device, without any account or login.",
        "disk-free" to "Your free space to the byte is almost unique and changes slowly, so ad companies use it to match you across apps within the same hour.",
        "device-name" to "A device name that includes your first name hands it to every app and to nearby devices.",
        "accessibility" to "A service here can read everything on screen, including messages and passwords as you type them.",
        "android-id" to "Deleting an app and installing it again doesn't make you a new person to its company: the code stays the same.",
        "loc-where" to "A precise location reveals your home and workplace within metres.",
        "cal-accounts" to "Calendar account names often include your work email, which names your employer.",
        "watch-several" to "One app with several of these can see your screen, read your messages and lock you out.",
        "watch-screen" to "An app that can read your screen sees your messages, banking and passwords as you use them.",
        "watch-notifications" to "Every message, login code and email preview passes through apps with notification access.",
        "watch-admin" to "A device admin app can lock you out or erase everything, and you can't uninstall it until you turn that off.",
    )
}
