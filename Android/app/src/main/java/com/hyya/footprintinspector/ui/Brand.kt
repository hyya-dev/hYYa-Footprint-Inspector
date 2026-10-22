// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hyya.footprintinspector.R
import com.hyya.footprintinspector.model.Severity

/** Quiet Noir, the same tokens as the iOS Brand.swift. Dark only. */
object Brand {
    val sand = Color(0xFFD2AE88)
    val sandDeep = Color(0xFF8F7560)
    val concern = Color(0xFFEC7F6A)
    val concernSoft = Color(0xFF2A1714)
    val green = Color(0xFF7CD9A8)
    val ink = Color(0xFFF5F5F7)
    val textMuted = Color(0xFFA1A1A8)
    val textSubtle = Color(0xFF6C6C73)
    val surface = Color(0xFF111113)
    val tile = Color(0xFF1D1915)
    val rule = sandDeep.copy(alpha = 0.35f)

    fun color(s: Severity) = when (s) {
        Severity.HIGH -> concern
        Severity.MEDIUM -> sand
        Severity.LOW -> textSubtle
    }

    /** "hYYa" keeps its own casing inside uppercased labels. */
    fun upper(s: String) = s.uppercase().replace("HYYA", "hYYa")
}

@Composable
fun FootprintTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Brand.sand, onPrimary = Color.Black, background = Color.Black, surface = Brand.surface,
            onBackground = Brand.ink, onSurface = Brand.ink, secondary = Brand.sand,
        ),
        content = content,
    )
}

/** A black scrolling page with a 720dp column, like the iOS Page. */
@Composable
fun Page(content: @Composable ColumnScope.() -> Unit) {
    Box(Modifier.fillMaxSize().background(Color.Black), contentAlignment = Alignment.TopCenter) {
        Column(
            Modifier.widthIn(max = 720.dp).fillMaxWidth().verticalScroll(rememberScrollState())
                .statusBarsPadding().padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
            content = content,
        )
    }
}

@Composable
fun Mascot(size: Int, modifier: Modifier = Modifier) {
    Image(painterResource(R.drawable.mascot_cutout), contentDescription = null, modifier = modifier.size(size.dp))
}

@Composable
fun Eyebrow(text: String) {
    Text(Brand.upper(text), color = Brand.sand, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.4.sp)
}

@Composable
fun AccentRule() {
    Box(Modifier.width(36.dp).height(3.dp).clip(RoundedCornerShape(2.dp)).background(Brand.sand))
}

/** Title, mascot, rule and subtitle, with no box around it. */
@Composable
fun HeroCard(eyebrow: String, title: String, subtitle: String, mascotSize: Int = 96) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Eyebrow(eyebrow)
                Text(title, color = Brand.ink, fontSize = 28.sp, fontWeight = FontWeight.Bold, lineHeight = 32.sp)
            }
            Mascot(mascotSize)
        }
        AccentRule()
        Text(subtitle, color = Brand.textMuted, fontSize = 15.sp, lineHeight = 21.sp)
    }
}

@Composable
fun SectionTitle(title: String, trailing: String? = null) {
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = 4.dp)) {
        Box(Modifier.width(2.dp).height(12.dp).background(Brand.sand))
        Spacer(Modifier.width(8.dp))
        Text(Brand.upper(title), color = Brand.sand, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.3.sp)
        Spacer(Modifier.width(10.dp))
        HorizontalDivider(Modifier.weight(1f), color = Brand.rule, thickness = 0.5.dp)
        if (trailing != null) {
            Spacer(Modifier.width(8.dp))
            Text(trailing, color = Brand.sand, fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clip(CircleShape).background(Brand.tile).padding(horizontal = 8.dp, vertical = 2.dp))
        }
    }
}

/** A near-black panel with a hairline sand border; rows inside are separated by hairlines. */
@Composable
fun Panel(content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Brand.surface)
            .border(BorderStroke(0.5.dp, Brand.sandDeep.copy(alpha = 0.6f)), RoundedCornerShape(16.dp)),
        content = content,
    )
}

@Composable
fun IconTile(icon: ImageVector, tint: Color = Brand.sand) {
    Box(Modifier.size(32.dp).clip(RoundedCornerShape(8.dp)).background(Brand.tile), contentAlignment = Alignment.Center) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(18.dp))
    }
}

@Composable
fun RowCard(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    tint: Color = Brand.sand,
    showDivider: Boolean = true,
    onClick: (() -> Unit)? = null,
    trailing: @Composable (() -> Unit)? = null,
) {
    Column {
        Row(
            (if (onClick != null) Modifier.pressable(onClick) else Modifier)
                .fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconTile(icon, tint)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, color = Brand.ink, fontSize = 16.sp)
                if (subtitle != null) Text(subtitle, color = Brand.textSubtle, fontSize = 12.sp, lineHeight = 16.sp)
            }
            trailing?.invoke()
        }
        if (showDivider) HorizontalDivider(Modifier.padding(start = 58.dp), color = Brand.rule, thickness = 0.5.dp)
    }
}

@Composable
fun SeverityDot(s: Severity) {
    Box(Modifier.size(7.dp).clip(CircleShape).background(Brand.color(s)))
}

@Composable
fun Pill(text: String, fg: Color = Brand.textMuted, bg: Color = Color.White.copy(alpha = 0.06f)) {
    Text(text, color = fg, fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
        modifier = Modifier.clip(CircleShape).background(bg).padding(horizontal = 9.dp, vertical = 3.dp))
}

/** White capsule with black text: the one primary action on a screen. */
@Composable
fun PrimaryButton(text: String, modifier: Modifier = Modifier.fillMaxWidth(), fill: Color = Color.White, onClick: () -> Unit) {
    Text(
        text, color = Color.Black, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
        modifier = modifier.pressable(onClick).clip(CircleShape).background(fill)
            .padding(vertical = 15.dp, horizontal = 22.dp),
    )
}

/** Sand hairline outline. */
@Composable
fun GhostButton(text: String, modifier: Modifier = Modifier.fillMaxWidth(), onClick: () -> Unit) {
    Text(
        text, color = Brand.sand, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
        modifier = modifier.pressable(onClick).clip(CircleShape).border(BorderStroke(1.dp, Brand.sandDeep), CircleShape)
            .padding(vertical = 13.dp, horizontal = 20.dp),
    )
}

/** Kept for call sites that just want a titled card; it's a context-role ToneCard. */
@Composable
fun InfoCard(title: String, tone: Tone = Tone.CONTEXT, icon: ImageVector? = null, content: @Composable ColumnScope.() -> Unit) {
    ToneCard(tone, title, icon, content = content)
}

@Composable
fun StepList(steps: List<String>, tint: Color = Brand.sand) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        steps.forEachIndexed { i, s ->
            Row {
                Box(Modifier.size(22.dp).clip(CircleShape).background(tint.copy(alpha = 0.10f)).border(BorderStroke(1.dp, tint.copy(alpha = 0.5f)), CircleShape),
                    contentAlignment = Alignment.Center) {
                    Text("${i + 1}", color = tint, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                }
                Spacer(Modifier.width(10.dp))
                Text(s, color = Brand.ink, fontSize = 15.sp, lineHeight = 20.sp)
            }
        }
    }
}

@Composable
fun MascotSays(line: String, mascotSize: Int = 72, tone: Tone = Tone.EXPLAIN) {
    MascotNote(line, tone)
}

@Composable
fun ScoreOrb(value: Int, size: Int = 110) {
    Box(Modifier.size(size.dp).clip(CircleShape).border(BorderStroke(2.dp, Brush.sweepGradient(listOf(Brand.sand, Brand.sandDeep, Brand.sand))), CircleShape),
        contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("$value", color = Brand.ink, fontSize = 40.sp, fontWeight = FontWeight.Light)
            Text("of 100", color = Brand.textSubtle, fontSize = 10.sp)
        }
    }
}
