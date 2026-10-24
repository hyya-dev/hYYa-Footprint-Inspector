// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.catalogue

import android.content.Context
import android.content.pm.PackageManager

data class SensitiveApp(val name: String, val pkg: String)

/**
 * Same categories and wording as iOS. Android checks by package name; each package must also be
 * listed in AndroidManifest.xml `<queries>`, or the system answers "not installed" (the test
 * `SensitiveManifestTest` keeps the two in sync).
 */
data class SensitiveCategory(
    val id: String,
    val title: String,
    val tells: String,
    val risk: String?,
    val apps: List<SensitiveApp>,
    val steps: List<String>,
)

object Sensitive {
    const val OTHERS_LINE = "Any app on this device can run this same check, including banking, government, employer and ID apps."
    const val WEBSITE_LINE = "If you'd rather an organisation couldn't, use its website in your browser instead of its app. A website can't see which apps you have."
    /**
     * The best first step: apps in Private space (or Samsung's Secure Folder) live in a separate,
     * locked profile, so apps outside it can't spot them, and their owner still opens them.
     */
    const val HIDE_STEP = "Best: move it into Private space (Android 15 and later; on Samsung, Secure Folder). Apps outside it can no longer spot it, and you still open it behind your lock. Check again here to see it gone."
    const val DELETE_STEP = "To delete an app: touch and hold its icon, then tap Uninstall."

    val categories = listOf(
        SensitiveCategory("dating", "Dating and LGBTQ+",
            "That tells it you're single or looking, and sometimes who you're attracted to.",
            "In some countries, this alone can put you in danger.",
            listOf(SensitiveApp("Grindr", "com.grindrapp.android"), SensitiveApp("Tinder", "com.tinder"),
                SensitiveApp("Bumble", "com.bumble.app"), SensitiveApp("Hinge", "co.hinge.app"),
                SensitiveApp("Blued", "com.soft.blued"), SensitiveApp("OkCupid", "com.okcupid.okcupid")),
            listOf("Use the website instead, such as tinder.com or bumble.com. Websites can't be spotted this way.",
                "Delete dating apps while you're not using them. Your matches and profile stay in your account.",
                "Travelling somewhere this could be risky? Delete the app before you go and reinstall it when you're back.")),
        SensitiveCategory("faith", "Religion and faith", "That tells it your religion.", null,
            listOf(SensitiveApp("Muslim Pro", "com.bitsmedia.android.muslimpro"), SensitiveApp("Bible (YouVersion)", "com.sirma.mobile.bible.android"),
                SensitiveApp("Hallow", "app.hallow.android")),
            listOf("If you'd rather keep this private, use the website, or a reading app that isn't tied to one faith.")),
        SensitiveCategory("health", "Health and fertility",
            "That tells it you may track your period, be trying for a baby, or see a therapist.", null,
            listOf(SensitiveApp("Flo", "org.iggymedia.periodtracker"), SensitiveApp("Clue", "com.clue.android"),
                SensitiveApp("Talkspace", "com.talkspace.talkspaceapp"), SensitiveApp("Headspace", "com.getsomeheadspace.android"),
                SensitiveApp("Calm", "com.calm.android"), SensitiveApp("BetterHelp", "com.betterhelp")),
            listOf("Choose apps that keep your data on the device, or let you use them without an account.",
                "Delete health apps you no longer use, but first ask the app to delete your data.")),
        SensitiveCategory("recovery", "Addiction and recovery", "That tells it you may be recovering from an addiction.", null,
            listOf(SensitiveApp("I Am Sober", "com.thehappyhealthinc.iamsober"), SensitiveApp("Quitzilla", "com.weightloss.quitzilla")),
            listOf("If you'd rather keep this private, use the service's website instead of the app.")),
        SensitiveCategory("circumvention", "VPN, Tor and censorship tools",
            "That tells it you hide your location or get around blocked websites.",
            "In countries that restrict VPNs, this alone can get you questioned.",
            listOf(SensitiveApp("Psiphon", "com.psiphon3"), SensitiveApp("Tor Browser", "org.torproject.torbrowser"),
                SensitiveApp("Orbot", "org.torproject.android"), SensitiveApp("Proton VPN", "ch.protonvpn.android"),
                SensitiveApp("NordVPN", "com.nordvpn.android"), SensitiveApp("Mullvad VPN", "net.mullvad.mullvadvpn")),
            listOf("Keep it if you need it. It still hides your address from websites and apps.",
                "Travelling somewhere VPNs are restricted? Delete it before you go and reinstall it when you're back. Your account stays.")),
        SensitiveCategory("messaging", "Private and regional messaging",
            "That tells it you care about private chats, or hints at where you're from.", null,
            listOf(SensitiveApp("Signal", "org.thoughtcrime.securesms"), SensitiveApp("Telegram", "org.telegram.messenger"),
                SensitiveApp("Threema", "ch.threema.app"), SensitiveApp("WeChat", "com.tencent.mm"),
                SensitiveApp("Viber", "com.viber.voip")),
            listOf("Nothing urgent. These apps are common, so they say little on their own.",
                "If one hints at where you're from and that worries you, use its computer or web version instead.")),
        SensitiveCategory("money", "Crypto and gambling",
            "That tells it you own crypto or bet, which makes you a target for scams.", null,
            listOf(SensitiveApp("Binance", "com.binance.dev"), SensitiveApp("Coinbase", "com.coinbase.android"),
                SensitiveApp("MetaMask", "io.metamask"), SensitiveApp("bet365", "com.bet365Wrapper.Bet365_Application")),
            listOf("Expect scam messages. Never share your recovery phrase or sign-in codes with anyone.",
                "Turn on two-step sign-in in each app.")),
        SensitiveCategory("work", "Job hunting and workplace",
            "That tells it you may talk anonymously about your job, or be looking for a new one.", null,
            listOf(SensitiveApp("Blind", "com.teamblind.blind"), SensitiveApp("Glassdoor", "com.glassdoor.app")),
            listOf("If your employer manages this device, keep job-hunting and workplace apps on a personal device.")),
        SensitiveCategory("politics", "Politics and news", "That hints at your political views, from the news you read.", null,
            listOf(SensitiveApp("Fox News", "com.foxnews.android"), SensitiveApp("CNN", "com.cnn.mobile.android.phone")),
            listOf("Read the news in your browser instead, if you'd rather keep your views private.")),
    )

    val allPackages: List<String> get() = categories.flatMap { c -> c.apps.map { it.pkg } }

    fun scan(context: Context, ids: Set<String>): Map<String, List<SensitiveApp>> {
        val pm = context.packageManager
        return categories.filter { it.id in ids }.associate { c ->
            c.id to c.apps.filter { app ->
                runCatching { pm.getPackageInfo(app.pkg, PackageManager.PackageInfoFlags.of(0)); true }.getOrDefault(false)
            }
        }
    }
}
