// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.material.icons.outlined.PanTool
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Build
import androidx.compose.material.icons.outlined.HelpOutline
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Accessibility
import androidx.compose.material.icons.outlined.Apps
import androidx.compose.material.icons.outlined.PrivacyTip
import androidx.compose.material.icons.outlined.Bluetooth
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Contacts
import androidx.compose.material.icons.outlined.Headphones
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Memory
import androidx.compose.material.icons.outlined.NetworkCheck
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Sensors
import androidx.compose.material.icons.outlined.Smartphone
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hyya.footprintinspector.catalogue.Catalogue
import com.hyya.footprintinspector.model.Finding
import com.hyya.footprintinspector.model.FootprintScore
import com.hyya.footprintinspector.model.Group
import com.hyya.footprintinspector.model.Section
import com.hyya.footprintinspector.model.Severity
import com.hyya.footprintinspector.scan.Phase
import com.hyya.footprintinspector.scan.PermissionKind
import com.hyya.footprintinspector.scan.Scanner

fun Section.icon(): ImageVector = when (this) {
    Section.WATCH -> Icons.Outlined.PrivacyTip
    Section.IDENTITY -> Icons.Outlined.Smartphone
    Section.SYSTEM -> Icons.Outlined.Refresh
    Section.STORAGE -> Icons.Outlined.Storage
    Section.DISPLAY -> Icons.Outlined.PhoneAndroid
    Section.AUDIO -> Icons.Outlined.Headphones
    Section.LANGUAGE -> Icons.Outlined.Language
    Section.ACCESSIBILITY -> Icons.Outlined.Accessibility
    Section.SENSORS -> Icons.Outlined.Sensors
    Section.NETWORK -> Icons.Outlined.NetworkCheck
    Section.SECURITY -> Icons.Outlined.Lock
    Section.APPS -> Icons.Outlined.Apps
    Section.REINSTALL -> Icons.Outlined.Memory
    Section.LOCATION -> Icons.Outlined.LocationOn
    Section.NEARBY -> Icons.Outlined.Bluetooth
    Section.CONTACTS -> Icons.Outlined.Contacts
    Section.CALENDARS -> Icons.Outlined.CalendarMonth
}

@Composable
fun BackBar(title: String, nav: Nav) {
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
        Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Back", tint = Brand.ink,
            modifier = Modifier.padding(end = 12.dp).clickableNoRipple { nav.pop() })
        Text(title, color = Brand.ink, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
fun ScanScreen(scanner: Scanner, nav: Nav) {
    when (scanner.phase) {
        Phase.IDLE -> Page {
            Spacer(Modifier.padding(top = 24.dp))
            Mascot(200, Modifier.align(Alignment.CenterHorizontally))
            Eyebrow("hYYa Footprint Inspector")
            AccentRule()
            Text("What do your apps know about you?", color = Brand.ink, fontSize = 30.sp, fontWeight = FontWeight.Bold, lineHeight = 34.sp)
            Text("A scan reads exactly what any app on this device can read, then shows you how to fix what matters.",
                color = Brand.textMuted, fontSize = 15.sp, lineHeight = 21.sp)
            PrimaryButton("Start scan") { scanner.scan() }
            Text("Nothing leaves your device · Open source", color = Brand.textSubtle, fontSize = 12.sp,
                textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
        }
        Phase.SCANNING -> Page {
            Spacer(Modifier.padding(top = 60.dp))
            Mascot(180, Modifier.align(Alignment.CenterHorizontally))
            Text("Looking for fingerprints…", color = Brand.ink, fontSize = 20.sp, fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
            LinearProgressIndicator(progress = { scanner.progress }, color = Brand.sand, trackColor = Brand.tile, modifier = Modifier.fillMaxWidth())
            Text("Reading only what any app could. Nothing is sent anywhere.", color = Brand.textSubtle, fontSize = 13.sp,
                textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
        }
        Phase.DONE -> Results(scanner, nav)
    }
}

@Composable
private fun Results(scanner: Scanner, nav: Nav) {
    val score = scanner.score
    val concerning = scanner.concerning
    Page {
        Row(verticalAlignment = Alignment.CenterVertically) {
            ScoreOrb(score.value)
            Spacer(Modifier.weight(1f))
            Mascot(96)
        }
        Text(score.level.title, color = Brand.ink, fontSize = 26.sp, fontWeight = FontWeight.Bold)
        AccentRule()
        Text("This scan found ${scanner.findings.size} clues about this device. " +
            (if (concerning.isEmpty()) "Nothing stands out." else "${concerning.size} are worth a look.") + " Higher scores are better.",
            color = Brand.textMuted, fontSize = 15.sp, lineHeight = 21.sp)
        Text("How the score works", color = Brand.sand, fontSize = 13.sp, modifier = Modifier.clickableNoRipple { nav.push(Route.ScoreRoute) })
        val seen = scanner.findings
        SummaryRing(listOf(
            Slice("worth a look", seen.count { it.severity == Severity.HIGH }, Tone.ALERT.tint),
            Slice("worth knowing", seen.count { it.severity == Severity.MEDIUM }, Amber),
            Slice("minor", seen.count { it.severity == Severity.LOW }, Tone.FIX.tint),
        ), "clues")
        PrimaryButton("Scan again") { scanner.scan() }
        ScoreGuide(scanner, nav)
        scanner.comparison?.let { cmp ->
            InfoCard("Since your last scan", Tone.CONTEXT, Icons.Outlined.History) {
                Text("${cmp.previous.score} → ${cmp.current.score}", color = Brand.ink, fontSize = 18.sp)
                val changed = cmp.changedIds.mapNotNull { Catalogue.byId[it]?.title }
                Text(if (changed.isEmpty()) "Nothing changed." else "${changed.size} changed, such as ${changed.take(3).joinToString(", ")}.",
                    color = Brand.textMuted, fontSize = 13.sp)
            }
        }

        if (concerning.isNotEmpty()) {
            SectionTitle("Worth a look", concerning.size.toString())
            Panel { concerning.forEachIndexed { i, f -> ClueRow(f, nav, i < concerning.lastIndex) } }
        }
        for ((group, title) in listOf(Group.PASSIVE to "Seen without asking", Group.ADVANCED to "Clever tricks", Group.PERMISSION to "Seen once you allow it")) {
            val sections = Section.entries.filter { it.group == group }
            if (group == Group.WATCH) {
                // The headline check: its findings sit right on the Scan screen, one tap from the fix.
                val fs = sections.flatMap { scanner.findings(it) }
                if (fs.isEmpty()) continue
                SectionTitle(title, fs.count { it.severity != Severity.LOW }.takeIf { it > 0 }?.toString())
                Panel { fs.forEachIndexed { i, f -> FindingRow(f, nav, i < fs.lastIndex) } }
                continue
            }
            SectionTitle(title)
            Panel {
                sections.forEachIndexed { i, s ->
                    val fs = scanner.findings(s)
                    val worth = fs.count { it.isConcerning }
                    RowCard(s.icon(), s.title, showDivider = i < sections.lastIndex, onClick = { nav.push(Route.SectionRoute(s)) }) {
                        Text(if (fs.isEmpty() && group == Group.PERMISSION) "Show me" else "${fs.size}", color = Brand.textSubtle, fontSize = 13.sp)
                        if (worth > 0) { Spacer(Modifier.width(6.dp)); SeverityDot(Severity.HIGH) }
                        Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, tint = Brand.textSubtle)
                    }
                }
            }
        }
        NextStepCard(Tab.SENSITIVE)
    }
}

@Composable
private fun ClueRow(f: Finding, nav: Nav, divider: Boolean) {
    RowCard(f.definition.section.icon(), f.definition.title,
        subtitle = if (f.definition.fix.fixable) "You can fix this" else "Only Google or the device maker can fix this",
        tint = if (f.isConcerning) Brand.concern else Brand.sand, showDivider = divider,
        onClick = { nav.push(Route.FindingRoute(f.id)) }) {
        SeverityDot(f.severity)
        Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, tint = Brand.textSubtle)
    }
}

@Composable
fun SectionScreen(scanner: Scanner, section: Section, nav: Nav) {
    val context = LocalContext.current
    val kind = PermissionKind.of(section)
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { scanner.refresh() }
    val findings = scanner.findings(section)
    Page {
        BackBar(section.title, nav)
        HeroCard(when (section.group) { Group.PERMISSION -> "Needs your permission"; Group.ADVANCED -> "Clever trick"; Group.WATCH -> "Who can watch you"; else -> "Seen without asking" },
            section.title,
            when {
                kind != null && !kind.granted(context) -> "Here's what any app you allow gets to see."
                findings.isEmpty() -> "Nothing to read here on this device."
                else -> "${findings.size} clue${if (findings.size == 1) "" else "s"}, ${findings.count { it.isConcerning }.let { if (it == 0) "nothing alarming" else "$it worth a look" }}."
            })
        if (kind != null && !kind.granted(context)) {
            InfoCard("See it for yourself", Tone.EXPLAIN, Icons.Outlined.PanTool) {
                Text("Tap below and I'll ask for the same permission an app would, then show you exactly what it gets. Nothing is saved or sent.",
                    color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp)
                PrimaryButton("Show me") { launcher.launch(kind.permissions.toTypedArray()) }
            }
            SectionTitle("What an app would get")
            val defs = Catalogue.definitions(section)
            Panel { defs.forEachIndexed { i, d -> RowCard(section.icon(), d.title, d.reveals, showDivider = i < defs.lastIndex) } }
        } else if (findings.isNotEmpty()) {
            SectionTitle("On this device")
            Panel { findings.forEachIndexed { i, f -> FindingRow(f, nav, i < findings.lastIndex) } }
        }
    }
}

@Composable
private fun FindingRow(f: Finding, nav: Nav, divider: Boolean) {
    Column(Modifier.clickableNoRipple { nav.push(Route.FindingRoute(f.id)) }.padding(horizontal = 14.dp, vertical = 12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(f.definition.title, color = Brand.textMuted, fontSize = 12.sp, modifier = Modifier.weight(1f))
            SeverityDot(f.severity)
        }
        Text(f.reading.value, color = Brand.ink, fontSize = 15.sp)
        f.reading.note?.let { Text(it, color = Brand.concern, fontSize = 11.sp) }
    }
    if (divider) androidx.compose.material3.HorizontalDivider(color = Brand.rule, thickness = 0.5.dp)
}

@Composable
fun FindingScreen(scanner: Scanner, id: String, nav: Nav) {
    val context = LocalContext.current
    val f = scanner.findings.firstOrNull { it.id == id } ?: return
    val d = f.definition
    val head = if (f.isConcerning) Tone.ALERT else Tone.CONTEXT
    var showDetails by remember { mutableStateOf(false) }
    Page {
        BackBar(d.title, nav)
        // The clue itself.
        ToneCard(head) {
            ToneBadge(if (f.isConcerning) "Worth a look" else f.severity.label, head, Icons.Outlined.ErrorOutline)
            Text(d.title, color = Brand.ink, fontSize = 28.sp, fontWeight = FontWeight.Bold, lineHeight = 33.sp)
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(Brand.upper("On your device"), color = Brand.textSubtle, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.3.sp)
                Text(f.reading.value, color = Brand.ink, fontSize = 20.sp, fontWeight = FontWeight.Light, lineHeight = 26.sp)
            }
            f.reading.note?.let { Text(it, color = if (f.isConcerning) Tone.ALERT.tint else Brand.textMuted, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, lineHeight = 19.sp) }
            BadgeRow {
                ToneBadge(d.persistence.label, Tone.LIMIT, Icons.Outlined.Schedule)
                ToneBadge(if (d.section.group == Group.PERMISSION) "Needs permission" else "No permission needed", Tone.LIMIT, Icons.Outlined.Visibility)
            }
            if (f.reading.items.isNotEmpty()) {
                androidx.compose.material3.HorizontalDivider(color = head.tint.copy(alpha = 0.2f), thickness = 0.5.dp)
                Row(Modifier.fillMaxWidth().pressable { showDetails = !showDetails }, verticalAlignment = Alignment.CenterVertically) {
                    Text("All the details (${f.reading.items.size})", color = head.tint, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                    Icon(if (showDetails) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore, null, tint = head.tint)
                }
                if (showDetails) Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    f.reading.items.take(60).forEach { item ->
                        Row(verticalAlignment = Alignment.Top) {
                            Box(Modifier.padding(top = 7.dp).size(5.dp).clip(CircleShape).background(head.tint.copy(alpha = 0.7f)))
                            Spacer(Modifier.width(8.dp))
                            Text(item, color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp)
                        }
                    }
                }
            }
        }
        // How serious: a level, who can read it, how long it lasts and what it lets someone do.
        val sTone = when (f.severity) { com.hyya.footprintinspector.model.Severity.HIGH -> Tone.ALERT; com.hyya.footprintinspector.model.Severity.MEDIUM -> Tone.CONTEXT; else -> Tone.LIMIT }
        ToneCard(sTone, "How serious", Icons.Outlined.Speed, trailing = { ToneBadge(com.hyya.footprintinspector.model.Impact.level(f.severity), sTone) }) {
            com.hyya.footprintinspector.model.Impact.inPractice[d.id]?.let { Text(it, color = Brand.ink, fontSize = 15.sp, fontWeight = FontWeight.Medium, lineHeight = 21.sp) }
            ImpactRow(Icons.Outlined.Visibility, "Who can read it", if (d.section.group == Group.PERMISSION) "Only apps you've given this permission." else "Any app on this device, without asking you.")
            ImpactRow(Icons.Outlined.Schedule, "How long it lasts", com.hyya.footprintinspector.model.Impact.lasting(d.persistence))
            ImpactRow(Icons.Outlined.Link, "What it lets them do", com.hyya.footprintinspector.model.Impact.reach(f.severity))
        }
        MascotNote(d.reveals, Tone.EXPLAIN, "What it tells an app", Icons.Outlined.ChatBubbleOutline)
        InfoCard("Why the system allows it", Tone.CONTEXT, Icons.Outlined.HelpOutline) {
            Text(d.why, color = Brand.textMuted, fontSize = 15.sp, lineHeight = 21.sp)
        }
        val fixTone = if (d.fix.fixable) Tone.FIX else Tone.LIMIT
        ToneCard(fixTone, if (d.fix.fixable) "How to fix it" else "Only Google or the device maker can fix this",
            if (d.fix.fixable) Icons.Outlined.Build else Icons.Outlined.Lock,
            trailing = if (d.fix.fixable && f.isConcerning) ({ ToneBadge("+${FootprintScore.HIGH_WEIGHT} points", Tone.FIX) }) else null) {
            Text(d.fix.summary, color = Brand.textMuted, fontSize = 15.sp, lineHeight = 21.sp)
            if (d.fix.steps.isNotEmpty()) StepList(d.fix.steps, fixTone.tint)
            if (d.fix.fixable) PrimaryButton("Open Settings") { openSettings(context, d.fix.settingsAction) }
        }
    }
}

@Composable
private fun ImpactRow(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, text: String) {
    Row(verticalAlignment = Alignment.Top) {
        Icon(icon, null, tint = Brand.textSubtle, modifier = Modifier.padding(top = 2.dp).size(18.dp))
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(title, color = Brand.ink, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            Text(text, color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp)
        }
    }
}

@Composable
fun ScoreScreen(nav: Nav) {
    Page {
        BackBar("How the score works", nav)
        MascotSays("No secret maths. Here's exactly how I score.", tone = Tone.CONTEXT)
        Text(FootprintScore.explanation, color = Brand.textMuted, fontSize = 15.sp, lineHeight = 22.sp)
    }
}

/** The clues you can fix, most points first. */
private fun fixesOf(scanner: Scanner) =
    scanner.concerning.filter { FootprintScore.points(it) > 0 }.sortedByDescending { FootprintScore.points(it) }

/** What the score means and how to raise it, as on iOS. */
@Composable
private fun ScoreGuide(scanner: Scanner, nav: Nav) {
    val score = scanner.score
    val fixes = fixesOf(scanner)
    val reach = FootprintScore.of(scanner.findings.filter { f -> fixes.none { it.id == f.id } }).value
    val meaning = when (score.level) {
        FootprintScore.Level.LIGHT -> "Higher is better, and you're in good shape: apps learn little that could single out this device."
        FootprintScore.Level.MODERATE -> "Higher is better. You're in the middle: a few clues together could single out this device."
        FootprintScore.Level.HEAVY -> "Higher is better. A low score means apps can easily tell this device apart from others and recognise you."
    }
    ToneCard(if (fixes.isEmpty()) Tone.FIX else Tone.CONTEXT, "What your score means", Icons.Outlined.Speed) {
        Text(meaning, color = Brand.ink, fontSize = 14.sp, lineHeight = 20.sp)
        Row(Modifier.fillMaxWidth().height(10.dp), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            Box(Modifier.weight(50f).fillMaxHeight().clip(CircleShape).background(Tone.ALERT.tint.copy(alpha = if (score.value < 50) 0.9f else 0.35f)))
            Box(Modifier.weight(25f).fillMaxHeight().clip(CircleShape).background(Brand.sand.copy(alpha = if (score.value in 50..74) 0.9f else 0.35f)))
            Box(Modifier.weight(25f).fillMaxHeight().clip(CircleShape).background(Tone.FIX.tint.copy(alpha = if (score.value >= 75) 0.9f else 0.35f)))
        }
        Row(Modifier.fillMaxWidth()) {
            Text("Heavy · 0–49", color = Tone.ALERT.tint, fontSize = 11.sp, modifier = Modifier.weight(1f))
            Text("Moderate · 50–74", color = Brand.sand, fontSize = 11.sp, modifier = Modifier.weight(1f))
            Text("Light · 75+", color = Tone.FIX.tint, fontSize = 11.sp)
        }
        if (fixes.isEmpty()) {
            Text("Nothing left that you can fix. What remains is up to Google or the device maker.", color = Tone.FIX.tint, fontSize = 14.sp, lineHeight = 19.sp)
        } else {
            Text("Fix ${if (fixes.size == 1) "this one thing" else "these ${fixes.size} things"} and your score could reach $reach:",
                color = Brand.ink, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, lineHeight = 19.sp)
            fixes.take(5).forEach { f ->
                Row { Text("+${FootprintScore.points(f)}", color = Tone.FIX.tint, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.width(38.dp))
                    Text(f.definition.title, color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp) }
            }
            PrimaryButton("Fix them with me") { nav.push(Route.FixRoute) }
        }
    }
}

/** "Fix them with me": one clue at a time, each with a button to the exact Settings page. */
@Composable
fun FixScreen(scanner: Scanner, nav: Nav) {
    val context = LocalContext.current
    val fixes = remember(scanner.findings.size) { fixesOf(scanner) }
    var index by remember { mutableStateOf(0) }
    var done by remember { mutableStateOf(0) }
    Page {
        BackBar(if (index < fixes.size) "Fix ${index + 1} of ${fixes.size}" else "All done", nav)
        if (index < fixes.size) {
            val f = fixes[index]
            androidx.compose.material3.LinearProgressIndicator(progress = { index.toFloat() / fixes.size }, color = Tone.FIX.tint, trackColor = Brand.tile, modifier = Modifier.fillMaxWidth())
            Text("Apps can't change these settings for you, so I'll open each page. Come back here after each change.", color = Brand.textSubtle, fontSize = 12.sp, lineHeight = 16.sp)
            ToneCard(Tone.FIX, f.definition.title, Icons.Outlined.Build, trailing = { ToneBadge("+${FootprintScore.points(f)} points", Tone.FIX) }) {
                Text(f.definition.fix.summary, color = Brand.ink, fontSize = 15.sp, lineHeight = 21.sp)
                if (f.definition.fix.steps.isNotEmpty()) StepList(f.definition.fix.steps, Tone.FIX.tint)
                GhostButton("Open Settings") { openSettings(context, f.definition.fix.settingsAction) }
            }
            PrimaryButton("Done, next", fill = Tone.FIX.tint) { done++; index++ }
            GhostButton("Skip this one") { index++ }
        } else {
            MascotNote(if (done == 0) "No changes this time. You can come back whenever you like."
                else "Nice work: you changed $done setting${if (done == 1) "" else "s"}. Scan again to see your new score.", Tone.FIX)
            PrimaryButton("Scan again") { nav.pop(); scanner.scan() }
        }
    }
}
