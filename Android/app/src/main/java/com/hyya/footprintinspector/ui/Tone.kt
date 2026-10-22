// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.ui

import android.view.HapticFeedbackConstants
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * What a card is for, as on iOS (App/Sources/UI/Kit/Tone.swift). Each role has one colour for
 * the card's edge, a faint wash, its icon and its badge; body text stays white or grey. Every
 * tint is at least 6:1 against the panel. Dark only (Quiet Noir).
 */
enum class Tone(val tint: Color) {
    /** Worth a look, concerning notes. */
    ALERT(Color(0xFFEC7F6A)),
    /** What a clue tells an app; the mascot's notes (the mascot's blue). */
    EXPLAIN(Color(0xFF7FB2E5)),
    /** Why the system allows it, details, background. */
    CONTEXT(Color(0xFFD2AE88)),
    /** How to fix it. */
    FIX(Color(0xFF7CD9A8)),
    /** Only Google or the device maker can fix it. */
    LIMIT(Color(0xFFA7AFBF));

    val wash get() = tint.copy(alpha = 0.07f)
    val badge get() = tint.copy(alpha = 0.14f)
}

/** Tips toward the finger and ticks when pressed: the press feel for every tappable card and row. */
@Composable
fun Modifier.pressable(onClick: () -> Unit): Modifier {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.975f else 1f, spring(dampingRatio = 0.62f, stiffness = 900f), label = "press")
    val tilt by animateFloatAsState(if (pressed) 4f else 0f, spring(dampingRatio = 0.62f, stiffness = 900f), label = "tilt")
    val view = LocalView.current
    return this
        .graphicsLayer { scaleX = scale; scaleY = scale; rotationX = tilt; cameraDistance = 12f * density }
        .clickable(interactionSource = source, indication = null, role = Role.Button) {
            view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
            onClick()
        }
}

/**
 * A card with a role: tinted icon and title, optional trailing content, then free content. Depth
 * without glow: a soft shadow underneath and a faint light catch on the top edge. One level only.
 */
@Composable
fun ToneCard(
    tone: Tone,
    title: String? = null,
    icon: ImageVector? = null,
    onClick: (() -> Unit)? = null,
    trailing: @Composable (RowScope.() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val shape = RoundedCornerShape(18.dp)
    Column(
        Modifier.fillMaxWidth()
            .then(if (onClick != null) Modifier.pressable(onClick) else Modifier)
            .shadow(14.dp, shape, ambientColor = Color.Black, spotColor = Color.Black)
            .clip(shape)
            .background(Brand.surface)
            .background(Brush.verticalGradient(listOf(tone.wash, Color.Transparent), endY = 260f))
            .border(BorderStroke(1.dp, Brush.verticalGradient(listOf(tone.tint.copy(alpha = 0.55f), tone.tint.copy(alpha = 0.15f)))), shape)
            .border(BorderStroke(1.dp, Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.10f), Color.Transparent), endY = 40f)), shape)
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (title != null) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (icon != null) {
                    Box(Modifier.size(30.dp).clip(RoundedCornerShape(9.dp)).background(tone.badge), contentAlignment = Alignment.Center) {
                        Icon(icon, null, tint = tone.tint, modifier = Modifier.size(17.dp))
                    }
                    Spacer(Modifier.width(10.dp))
                }
                Text(title, color = Brand.ink, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, lineHeight = 22.sp, modifier = Modifier.weight(1f))
                trailing?.invoke(this)
            }
        }
        content()
    }
}

/** A tinted label: role colour on a faint fill of the same colour. Wraps instead of cutting off. */
@Composable
fun ToneBadge(text: String, tone: Tone, icon: ImageVector? = null) {
    Row(
        Modifier.clip(CircleShape).background(tone.badge).padding(horizontal = 10.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) { Icon(icon, null, tint = tone.tint, modifier = Modifier.size(13.dp)); Spacer(Modifier.width(5.dp)) }
        Text(text, color = tone.tint, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, lineHeight = 15.sp)
    }
}

/** Badges left to right, wrapping to a new line when they don't fit. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun BadgeRow(content: @Composable () -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) { content() }
}

/** The mascot with something to say, inside its own card, the text using the full width. */
@Composable
fun MascotNote(line: String, tone: Tone = Tone.EXPLAIN, title: String? = null, icon: ImageVector? = null) {
    ToneCard(tone, title, icon) {
        Row(verticalAlignment = Alignment.Top) {
            Mascot(60)
            Spacer(Modifier.width(14.dp))
            Text(line, color = Brand.ink, fontSize = 15.sp, lineHeight = 21.sp, modifier = Modifier.weight(1f).padding(top = 2.dp))
        }
    }
}

/** Lets any screen move the person to another tab (set by App). */
val LocalGoTo = androidx.compose.runtime.staticCompositionLocalOf<(Tab) -> Unit> { {} }

/** "Next: …" at the end of a page: the one obvious way forward, as on iOS. */
@Composable
fun NextStepCard(step: Tab) {
    val go = LocalGoTo.current
    val shape = RoundedCornerShape(18.dp)
    Row(
        Modifier.fillMaxWidth().pressable { go(step) }.clip(shape).background(Brand.sand.copy(alpha = 0.06f))
            .border(BorderStroke(1.dp, Brand.sand.copy(alpha = 0.45f)), shape).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(40.dp).clip(CircleShape).background(Brand.sand.copy(alpha = 0.14f)), contentAlignment = Alignment.Center) {
            Text("${step.step}", color = Brand.sand, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(Brand.upper("Next: ${step.label}"), color = Brand.sand, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.3.sp)
            Text(step.pitch, color = Brand.ink, fontSize = 14.sp, lineHeight = 19.sp)
        }
        Icon(androidx.compose.material.icons.Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, tint = Brand.sand)
    }
}
