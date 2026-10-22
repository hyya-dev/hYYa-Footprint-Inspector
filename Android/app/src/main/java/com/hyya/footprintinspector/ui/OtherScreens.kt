// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.ui

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.AccountBalance
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.NotificationsNone
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.PanTool
import androidx.compose.material.icons.outlined.RadioButtonUnchecked
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.hyya.footprintinspector.BuildConfig
import com.hyya.footprintinspector.R
import com.hyya.footprintinspector.remind.ScanReminder
import com.hyya.footprintinspector.catalogue.CheckUp
import com.hyya.footprintinspector.catalogue.Sensitive
import com.hyya.footprintinspector.catalogue.SensitiveApp
import com.hyya.footprintinspector.catalogue.SensitiveCategory
import com.hyya.footprintinspector.scan.Scanner

fun Modifier.clickableNoRipple(onClick: () -> Unit): Modifier =
    this.clickable(interactionSource = MutableInteractionSource(), indication = null, onClick = onClick)

private fun prefs(c: Context) = c.getSharedPreferences("app", Context.MODE_PRIVATE)

// MARK: Sensitive apps

@Composable
fun SensitiveScreen() {
    val context = LocalContext.current
    var chosen by remember { mutableStateOf(prefs(context).getStringSet("sensitiveCategories", emptySet())!!.toSet()) }
    var results by remember { mutableStateOf<Map<String, List<SensitiveApp>>?>(null) }
    var revealed by remember { mutableStateOf(false) }

    // Results never outlive the screen: cleared as soon as the app goes to the background.
    val owner = LocalLifecycleOwner.current
    DisposableEffect(owner) {
        val obs = LifecycleEventObserver { _, e -> if (e == Lifecycle.Event.ON_STOP) { results = null; revealed = false } }
        owner.lifecycle.addObserver(obs)
        onDispose { owner.lifecycle.removeObserver(obs) }
    }

    Page {
        HeroCard("Sensitive apps", "Which apps give you away?",
            "Any app can ask whether certain apps are installed, one by one, without asking you. Pick the kinds to check.", 104)
        results?.let { r ->
            val found = Sensitive.categories.flatMap { c -> (r[c.id] ?: emptyList()).map { c to it } }
            val checked = Sensitive.categories.filter { it.id in chosen }.sumOf { it.apps.size }
            SummaryRing(listOf(Slice(if (found.size == 1) "app any app can spot" else "apps any app can spot", found.size, Tone.ALERT.tint),
                Slice("not on this device", (checked - found.size).coerceAtLeast(0), Tone.FIX.tint)), "checked")
            if (found.isEmpty()) {
                MascotSays("None of these apps answered. Any app asking the same would find nothing.", tone = Tone.FIX)
            } else {
                Text(if (found.size == 1) "1 app gives you away" else "${found.size} apps give you away",
                    color = Brand.ink, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                Box(contentAlignment = Alignment.Center) {
                    Column(Modifier.blur(if (revealed) 0.dp else 14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        found.forEach { (c, app) -> FoundAppCard(c, app) }
                    }
                    if (!revealed) GhostButton("Tap to reveal", Modifier) { revealed = true }
                }
                Text("Rarely, a different app answers to the same name.", color = Brand.textSubtle, fontSize = 12.sp)
            }
            OthersCanCheckCard()
        }
        if (results != null) {
            // The result replaces the set-up: one thing on screen, then the way forward.
            GhostButton("Check different kinds") { results = null; revealed = false }
            NextStepCard(Tab.TRACKER)
        } else {
            SectionTitle("Kinds of apps", "${chosen.size} on")
            Panel {
                Sensitive.categories.forEachIndexed { i, c ->
                    val on = c.id in chosen
                    RowCard(Icons.Outlined.Visibility, c.title, c.apps.joinToString(", ") { it.name },
                        tint = if (on) Brand.ink else Brand.textSubtle, showDivider = i < Sensitive.categories.lastIndex,
                        onClick = {
                            chosen = if (on) chosen - c.id else chosen + c.id
                            prefs(context).edit().putStringSet("sensitiveCategories", chosen).apply()
                            results = null; revealed = false
                        }) {
                        Icon(if (on) Icons.Outlined.CheckCircle else Icons.Outlined.RadioButtonUnchecked, null,
                            tint = if (on) Brand.ink else Brand.textSubtle)
                    }
                }
            }
            Text("Android has no fixed limit: any app can list specific apps in its set-up and check for them. These are the ones that say the most about a person.",
                color = Brand.textSubtle, fontSize = 12.sp, lineHeight = 16.sp)
            Row(verticalAlignment = Alignment.Top) {
                Icon(Icons.Outlined.Lock, null, tint = Brand.sand, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(8.dp))
                Text("Runs only on this device. The result stays hidden until you tap it, and is gone when you leave. Nothing is saved or sent.",
                    color = Brand.textSubtle, fontSize = 12.sp, lineHeight = 16.sp)
            }
            PrimaryButton(if (chosen.isEmpty()) "Pick at least one kind" else "Check ${chosen.size} kind${if (chosen.size == 1) "" else "s"}") {
                if (chosen.isNotEmpty()) { results = Sensitive.scan(context, chosen); revealed = false }
            }
        }
    }
}

@Composable
private fun FoundAppCard(c: SensitiveCategory, app: SensitiveApp) {
    InfoCard("Any app can see you have ${app.name}", Tone.ALERT, Icons.Outlined.ErrorOutline) {
        Pill("Worth a look", Brand.concern, Brand.concernSoft)
        Text(listOfNotNull(c.tells, c.risk).joinToString(" "), color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp)
        Eyebrow("What to do")
        StepList(c.steps + Sensitive.DELETE_STEP)
    }
}

/**
 * Shown after every check: apps people trust with their identity can ask the same question, and
 * the browser is the way out. No organisation is named: we can't see which apps check.
 */
@Composable
private fun OthersCanCheckCard() {
    InfoCard("Who else can check this?", Tone.CONTEXT, Icons.Outlined.AccountBalance) {
        Text(Sensitive.OTHERS_LINE, color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp)
        Text(Sensitive.WEBSITE_LINE, color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp)
    }
}

/**
 * Off, weekly or monthly. Choosing one asks for notification permission first; if declined it
 * stays Off and says how to allow it.
 */
@Composable
private fun ReminderRow() {
    val context = LocalContext.current
    var choice by remember { mutableStateOf(ScanReminder.current(context)) }
    var open by remember { mutableStateOf(false) }
    var pending by remember { mutableStateOf<ScanReminder?>(null) }
    var declined by remember { mutableStateOf(false) }
    val ask = androidx.activity.compose.rememberLauncherForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.RequestPermission()) { granted ->
        val want = pending ?: return@rememberLauncherForActivityResult
        if (granted) { ScanReminder.apply(context, want); choice = want; declined = false } else declined = true
        pending = null
    }
    Box {
        RowCard(Icons.Outlined.NotificationsNone, "Re-scan reminder",
            if (declined) "Notifications are off. Allow them for this app in Settings, then choose again." else "A reminder on this device to check again.",
            onClick = { open = true }) { Text(choice.title, color = Brand.textSubtle) }
        androidx.compose.material3.DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            ScanReminder.entries.forEach { r ->
                androidx.compose.material3.DropdownMenuItem(text = { Text(r.title) }, onClick = {
                    open = false
                    if (r == ScanReminder.OFF || ScanReminder.canNotify(context)) { ScanReminder.apply(context, r); choice = r; declined = false }
                    else { pending = r; ask.launch(android.Manifest.permission.POST_NOTIFICATIONS) }
                })
            }
        }
    }
}

// MARK: Tracker

/**
 * Step 3 on Android: who holds the access watching someone needs (read with no permission, see
 * WatchReaders), and the system's own record of what apps used, in Privacy dashboard.
 */
@Composable
fun TrackerScreen(scanner: com.hyya.footprintinspector.scan.Scanner, nav: Nav) {
    val context = LocalContext.current
    val watch = scanner.findings(com.hyya.footprintinspector.model.Section.WATCH)
    Page {
        HeroCard("Tracker", "Who can watch you?",
            "Some apps hold access that lets them read your screen, every notification, or lock your device. Here's who, and Android's own record of what apps used.", 96)
        if (watch.isEmpty()) {
            InfoCard("Run a scan first", Tone.EXPLAIN, Icons.Outlined.Search) {
                Text("The Footprint scan checks who holds this access.", color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp)
                PrimaryButton("Start scan") { scanner.scan() }
            }
        } else {
            SummaryRing(listOf(
                Slice("worth a look", watch.count { it.isConcerning }, Tone.ALERT.tint),
                Slice("worth knowing", watch.count { it.severity == com.hyya.footprintinspector.model.Severity.MEDIUM }, Amber),
                Slice("all clear", watch.count { it.severity == com.hyya.footprintinspector.model.Severity.LOW }, Tone.FIX.tint),
            ), "checks")
            SectionTitle("Who can watch you", watch.count { it.isConcerning }.takeIf { it > 0 }?.toString())
            Panel { watch.forEachIndexed { i, f -> TrackerRow(f, nav, i < watch.lastIndex) } }
            Text("Apps built into your device, like Google's and the home screen, are listed but not counted. Parental-control and work apps hold this access too.",
                color = Brand.textSubtle, fontSize = 12.sp, lineHeight = 16.sp)
        }
        InfoCard("What apps actually used", Tone.EXPLAIN, Icons.Outlined.VisibilityOff) {
            Text("Android keeps a record of which apps used your location, camera and microphone. Open Privacy dashboard to see it, then turn off anything you didn't expect.",
                color = Brand.textMuted, fontSize = 14.sp, lineHeight = 20.sp)
            Text("It covers the last 24 hours to 7 days, depending on your device. Apps that only send things now and then may not appear.",
                color = Brand.textSubtle, fontSize = 13.sp, lineHeight = 18.sp)
            PrimaryButton("Open Privacy dashboard") {
                openSettings(context, if (android.os.Build.VERSION.SDK_INT >= 31) "android.intent.action.REVIEW_PERMISSION_USAGE" else android.provider.Settings.ACTION_PRIVACY_SETTINGS)
            }
        }
        if (watch.isNotEmpty()) NextStepCard(Tab.CHECKUP)
    }
}

@Composable
private fun TrackerRow(f: com.hyya.footprintinspector.model.Finding, nav: Nav, divider: Boolean) {
    RowCard(Icons.Outlined.Visibility, f.definition.title, f.reading.value,
        tint = if (f.isConcerning) Tone.ALERT.tint else Brand.sand, showDivider = divider,
        onClick = { nav.push(Route.FindingRoute(f.id)) }) {
        Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, tint = Brand.textSubtle)
    }
}

// MARK: Check-up

@Composable
fun CheckUpScreen(nav: Nav) {
    val context = LocalContext.current
    val done = prefs(context).getStringSet("checkUpDone", emptySet())!!
    Page {
        HeroCard("Permission check-up", if (done.size == CheckUp.steps.size) "All checked!" else "${done.size} of ${CheckUp.steps.size} checked",
            "Android never tells one app which other apps can reach your location, contacts or notifications. Only Settings knows, so let's look together.")
        SummaryRing(listOf(Slice("checked", done.size, Tone.FIX.tint), Slice("still to check", CheckUp.steps.size - done.size, Amber)),
            centre = "${done.size}/${CheckUp.steps.size}")
        Panel {
            CheckUp.steps.forEachIndexed { i, s ->
                RowCard(if (s.id in done) Icons.Outlined.CheckCircle else Icons.Outlined.Security, s.title, s.path.substringBefore(" (on Samsung").let { if (it.length > 60) "Permission manager › " + s.path.substringAfterLast("› ") else it },
                    tint = if (s.id in done) Brand.green else Brand.sand, showDivider = i < CheckUp.steps.lastIndex,
                    onClick = { nav.push(Route.CheckUpRoute(i)) }) {
                    Text("${i + 1}", color = Brand.textSubtle, fontSize = 12.sp)
                }
            }
        }
    }
}

@Composable
fun CheckUpStepScreen(index: Int, nav: Nav) {
    val context = LocalContext.current
    val step = CheckUp.steps[index]
    var done by remember { mutableStateOf(step.id in prefs(context).getStringSet("checkUpDone", emptySet())!!) }
    Page {
        BackBar(step.title, nav)
        HeroCard("Step ${index + 1}", step.title, step.why)
        InfoCard("Where to go", Tone.CONTEXT, Icons.Outlined.Settings) { Text(step.path, color = Tone.CONTEXT.tint, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, lineHeight = 20.sp) }
        InfoCard("What to do", Tone.FIX, Icons.Outlined.Checklist) { StepList(step.actions, Tone.FIX.tint) }
        GhostButton("Open Settings") { openSettings(context, step.action) }
        PrimaryButton(if (done) "Checked ✓" else "I've checked this", fill = if (done) Brand.green else androidx.compose.ui.graphics.Color.White) {
            done = !done
            val set = prefs(context).getStringSet("checkUpDone", emptySet())!!.toMutableSet()
            if (done) set.add(step.id) else set.remove(step.id)
            prefs(context).edit().putStringSet("checkUpDone", set).apply()
            if (done) nav.pop()
        }
    }
}

// MARK: Settings

object Links {
    const val PLAY = "https://play.google.com/store/apps/details?id=com.hyya.footprintinspector"
    const val CONTACT = "https://hyya.com/#contact"
    const val PRIVACY = "https://hyya.com/privacypolicy/hyya-footprint-inspector.html"
    const val SECURITY = "mailto:security@hyya.com?subject=Security%20report%20%E2%80%94%20hYYa%20Footprint%20Inspector"
    const val SOURCE = "https://github.com/hyya-dev/hYYa-Footprint-Inspector"
    const val HYYA_AI = "https://play.google.com/store/apps/details?id=com.hyya.hyyaai"
    const val HYYA = "https://hyya.com"
    const val SHARE = "hYYa Footprint Inspector shows what any app can learn about your device, and how to fix it. Free, open source, nothing leaves your device.\n$PLAY"
}

@Composable
fun SettingsScreen(scanner: Scanner) {
    val context = LocalContext.current
    var count by remember { mutableIntStateOf(scanner.history.snapshots.size) }
    Page {
        HeroCard("Settings", "hYYa Footprint Inspector", "Everything here stays on this device.")
        // Rating card, as on iOS.
        InfoCard("Enjoying hYYa Footprint Inspector?") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Mascot(72)
                Spacer(Modifier.width(12.dp))
                Text("Your reviews keep us smiling while coding, and help others find a privacy app they can trust.",
                    color = Brand.textMuted, fontSize = 13.sp, lineHeight = 18.sp, modifier = Modifier.weight(1f))
            }
            PrimaryButton("Rate the App", Modifier) { openUrl(context, Links.PLAY) }
        }
        SectionTitle("Your scans")
        Panel {
            RowCard(Icons.Outlined.History, "Scan history") { Text("$count", color = Brand.textSubtle) }
            ReminderRow()
            RowCard(Icons.Outlined.Delete, "Clear history", tint = Brand.concern, showDivider = false,
                onClick = { scanner.history.clear(); count = 0 })
        }
        Text("Sensitive-app results are never saved.", color = Brand.textSubtle, fontSize = 12.sp)
        SectionTitle("Support hYYa")
        Panel {
            RowCard(Icons.Outlined.Share, "Share", "Help your friends take back their digital privacy.", onClick = {
                context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, Links.SHARE), null)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            })
            RowCard(Icons.Outlined.Star, "Rate the App", "Your reviews keep us smiling while coding.", onClick = { openUrl(context, Links.PLAY) })
            RowCard(Icons.Outlined.Email, "Contact hYYa", onClick = { openUrl(context, Links.CONTACT) }) { OutIcon() }
            RowCard(Icons.Outlined.PanTool, "Privacy Policy", onClick = { openUrl(context, Links.PRIVACY) }) { OutIcon() }
            RowCard(Icons.Outlined.Security, "Report a Security Issue", showDivider = false, onClick = { openUrl(context, Links.SECURITY) }) { OutIcon() }
        }
        SectionTitle("More from hYYa")
        Panel {
            PromoRow(R.drawable.promo_hyya_ai, "hYYa ai", "Two engines. Offline & Online.", true) { openUrl(context, Links.HYYA_AI) }
            PromoRow(R.drawable.promo_hyya_dev, "hYYa ✨", "Companions you can trust.", false) { openUrl(context, Links.HYYA) }
        }
        Column(Modifier.fillMaxWidth().padding(top = 8.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Mascot(82)
            Text(Brand.upper("hYYa Footprint Inspector"), color = Brand.textSubtle, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.4.sp)
            Text("Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE}) · Open source, MPL 2.0", color = Brand.textSubtle, fontSize = 12.sp,
                textAlign = TextAlign.Center)
            Text("View the source code ↗", color = Brand.sand, fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickableNoRipple { openUrl(context, Links.SOURCE) })
        }
    }
}

@Composable
private fun OutIcon() = Icon(Icons.AutoMirrored.Outlined.OpenInNew, null, tint = Brand.textSubtle, modifier = Modifier.size(16.dp))

@Composable
private fun PromoRow(image: Int, title: String, tagline: String, divider: Boolean, onClick: () -> Unit) {
    Column {
        Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 14.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Image(painterResource(image), null, Modifier.size(44.dp).clip(RoundedCornerShape(11.dp)))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, color = Brand.ink, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text(tagline, color = Brand.textSubtle, fontSize = 12.sp)
            }
            Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, tint = Brand.textSubtle)
        }
        if (divider) androidx.compose.material3.HorizontalDivider(Modifier.padding(start = 70.dp), color = Brand.rule, thickness = 0.5.dp)
    }
}
