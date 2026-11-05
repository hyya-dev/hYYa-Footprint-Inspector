// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxWidth

import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.shape.GenericShape
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

/** The Mac Stickies colours (owner, 2026-11-05); every ink on them is measured to WCAG 2.2 AA. */
enum class Paper(val colour: Color) {
    YELLOW(Color(0xFFFBEB61)), PINK(Color(0xFFF3B6B3)), GREEN(Color(0xFFA2FC90)),
    BLUE(Color(0xFFA1EEFD)), PURPLE(Color(0xFFA1B5F8)), GRAY(Color(0xFFDADADB));

    companion object {
        /** Green when well protected, purple in the middle, pink when heavy; yellow before any check. */
        fun forScore(score: Int?) = when {
            score == null -> YELLOW
            score >= 75 -> GREEN
            score >= 50 -> PURPLE
            else -> PINK
        }
    }
}

private enum class Wear { TORN, CUT_CORNER, CURL, DOG_EAR, COFFEE, AGED }

/**
 * A detective's sticky note: the content on light paper in dark ink (LocalOnPaper), pinned or
 * taped, slightly askew, with its own wear. Tilt, fixing and wear come from the seed, so a page
 * never shows two the same, yet a note looks the same every time. It grows with its content.
 */
@Composable
fun StickyNote(paper: Paper, seed: String, onClick: (() -> Unit)? = null, content: @Composable BoxScope.() -> Unit) {
    val h = seed.fold(1469598103934665603uL) { acc, c -> (acc xor c.code.toULong()) * 1099511628211uL }
    val tilts = floatArrayOf(-1.2f, -0.9f, -0.6f, -0.35f, 0.35f, 0.6f, 0.9f, 1.2f)
    val tilt = tilts[(h % 8uL).toInt()]
    val tape = (h shr 8) % 4uL == 3uL
    val pins = listOf(Color(0xFFB22222), Color(0xFF2B5AA8), Color(0xFF2E8A4E), Color(0xFFD8B020))
    val pin = pins[((h shr 16) % 4uL).toInt()]
    val wear = Wear.entries[((h shr 24) % 6uL).toInt()]
    val shape = GenericShape { size, _ ->
        val w = size.width; val ht = size.height; val c = 64f
        when (wear) {
            Wear.TORN -> {
                moveTo(0f, 0f); lineTo(w, 0f); lineTo(w, ht - 8f)
                var x = w; var i = 0
                while (x > 0f) { i++; x -= 18f + ((h shr (i % 40)) % 20uL).toFloat(); lineTo(maxOf(x, 0f), ht - ((h shr ((i * 3) % 50)) % 16uL).toFloat()) }
                lineTo(0f, ht - 6f)
            }
            Wear.CUT_CORNER -> { moveTo(c, 0f); lineTo(w, 0f); lineTo(w, ht); lineTo(0f, ht); lineTo(0f, c) }
            Wear.CURL -> { moveTo(0f, 0f); lineTo(w, 0f); lineTo(w, ht - 80f); lineTo(w - 80f, ht); lineTo(0f, ht) }
            Wear.DOG_EAR -> { moveTo(0f, 0f); lineTo(w - c, 0f); lineTo(w, c); lineTo(w, ht); lineTo(0f, ht) }
            else -> addRect(androidx.compose.ui.geometry.Rect(0f, 0f, w, ht))
        }
        close()
    }
    // A tall note tilts less, so no corner swings more than 6 dp out.
    var height by androidx.compose.runtime.remember { androidx.compose.runtime.mutableIntStateOf(0) }
    val density = androidx.compose.ui.platform.LocalDensity.current
    val limit = if (height > 0) Math.toDegrees(kotlin.math.asin(kotlin.math.min(1.0, with(density) { 6.dp.toPx() } / (height / 2.0)))).toFloat() else kotlin.math.abs(tilt)
    val angle = kotlin.math.min(kotlin.math.abs(tilt), limit) * kotlin.math.sign(tilt)
    Box(Modifier.fillMaxWidth().padding(vertical = 4.dp).onSizeChanged { height = it.height }.rotate(angle)) {
        Box(
            Modifier.fillMaxWidth()
                .then(if (onClick != null) Modifier.pressable(onClick) else Modifier)
                .shadow(10.dp, shape, ambientColor = Color.Black, spotColor = Color.Black)
                .clip(shape)
                .background(paper.colour),
        ) {
            // Wear marked on the paper itself, kept light so text keeps its contrast.
            Canvas(Modifier.matchParentSize()) {
                drawRect(Color.Black.copy(alpha = 0.03f), size = Size(size.width, 36f))
                when (wear) {
                    Wear.COFFEE -> drawCircle(Color(0x296E4618), radius = 100f, center = Offset(size.width - 90f, size.height - 80f), style = Stroke(12f))
                    Wear.AGED -> {
                        drawRect(Color(0x2E7A5420), style = Stroke(22f))
                        drawLine(Color.Black.copy(alpha = 0.07f), Offset(size.width * 0.64f, 0f), Offset(size.width * 0.58f, size.height), 3f)
                    }
                    Wear.CURL -> {
                        val p = Path().apply { moveTo(size.width, size.height - 80f); lineTo(size.width - 80f, size.height); lineTo(size.width - 92f, size.height - 92f); close() }
                        drawPath(p, paper.colour.copy(alpha = 0.95f))
                    }
                    Wear.DOG_EAR -> {
                        val p = Path().apply { moveTo(size.width - 64f, 0f); lineTo(size.width, 64f); lineTo(size.width - 64f, 64f); close() }
                        drawPath(p, Color.Black.copy(alpha = 0.16f))
                    }
                    else -> Unit
                }
            }
            CompositionLocalProvider(LocalOnPaper provides true) { content() }
        }
        if (tape) {
            Box(Modifier.align(Alignment.TopCenter).offset(y = (-8).dp).size(64.dp, 18.dp).rotate(-4f).background(Color(0x8CF3EEDC)))
        } else {
            Box(Modifier.align(Alignment.TopCenter).offset(y = 4.dp).size(14.dp).shadow(2.dp, CircleShape).clip(CircleShape).background(pin))
        }
    }
}
