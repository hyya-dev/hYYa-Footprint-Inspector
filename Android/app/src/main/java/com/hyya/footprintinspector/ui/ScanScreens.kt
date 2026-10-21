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
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Accessibility
import androidx.compose.material.icons.outlined.Apps
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
            Text("A scan reads exactly what any app on this device can read, then shows you how to hide what matters.",
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
        Text("Any app can read ${scanner.findingsWithoutAsking.size} things about this device. " +
            if (concerning.isEmpty()) "Nothing stands out." else "${concerning.size} are worth a look.",
            color = Brand.textMuted, fontSize = 15.sp, lineHeight = 21.sp)
        Text("How the score works", color = Brand.sand, fontSize = 13.sp, modifier = Modifier.clickableNoRipple { nav.push(Route.ScoreRoute) })
        PrimaryButton("Scan again") { scanner.scan() }

        scanner.comparison?.let { cmp ->
            InfoCard("Since your last scan") {
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
        HeroCard(when (section.group) { Group.PERMISSION -> "Needs your permission"; Group.ADVANCED -> "Clever trick"; else -> "Seen without asking" },
            section.title,
            when {
                kind != null && !kind.granted(context) -> "Here's what any app you allow gets to see."
                findings.isEmpty() -> "Nothing to read here on this device."
                else -> "${findings.size} clue${if (findings.size == 1) "" else "s"}, ${findings.count { it.isConcerning }.let { if (it == 0) "nothing alarming" else "$it worth a look" }}."
            })
        if (kind != null && !kind.granted(context)) {
            InfoCard("See it for yourself") {
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
    Page {
        BackBar(d.title, nav)
        if (f.isConcerning) Pill("Worth a look", Brand.concern, Brand.concernSoft)
        Text(d.title, color = Brand.ink, fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("On your device", color = Brand.textSubtle, fontSize = 12.sp)
        Text(f.reading.value, color = Brand.ink, fontSize = 18.sp)
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Pill(d.persistence.label)
            Pill(if (d.section.group == Group.PERMISSION) "Needs permission" else "No permission needed")
        }
        f.reading.note?.let { Text(it, color = Brand.concern, fontSize = 13.sp) }
        MascotSays(d.reveals)
        if (f.reading.items.isNotEmpty()) InfoCard("All the details (${f.reading.items.size})") {
            f.reading.items.take(60).forEach { Text(it, color = Brand.textMuted, fontSize = 13.sp) }
        }
        InfoCard("Why the system allows it") { Text(d.why, color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp) }
        InfoCard(if (d.fix.fixable) "How to fix it" else "Only Google or the device maker can fix this") {
            Text(d.fix.summary, color = Brand.textMuted, fontSize = 14.sp, lineHeight = 19.sp)
            if (d.fix.steps.isNotEmpty()) StepList(d.fix.steps)
            if (d.fix.fixable) {
                if (d.fix.settingsAction != null) PrimaryButton("Open Settings") { openSettings(context, d.fix.settingsAction) }
                else GhostButton("Open Settings") { openSettings(context, null) }
            }
        }
    }
}

@Composable
fun ScoreScreen(nav: Nav) {
    Page {
        BackBar("How the score works", nav)
        MascotSays("No secret maths. Here's exactly how I score.")
        Text(FootprintScore.explanation, color = Brand.textMuted, fontSize = 15.sp, lineHeight = 22.sp)
    }
}
