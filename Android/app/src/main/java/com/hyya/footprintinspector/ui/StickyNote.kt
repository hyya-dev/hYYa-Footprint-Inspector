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
        /** Green when well protected, blue in the middle, purple when heavy; gray before any check (owner, 2026-11-06: no pink, little yellow). */
        fun forScore(score: Int?) = when {
            score == null -> GRAY
            score >= 75 -> GREEN
            score >= 50 -> BLUE
            else -> PURPLE
        }
    }
}


/** What an ink is for, on a sticky note. */
enum class InkRole { TEXT, MUTED, SUBTLE, ACCENT, CONCERN, FIX, EDGE, AMBER, RULE }

/** The paper the content sits on; null on the dark page. */
val LocalPaper = androidx.compose.runtime.staticCompositionLocalOf<Paper?> { null }

/**
 * The ink for each role on this paper (owner, 2026-11-06: "the best colour for clear reading"), the same
 * table as iOS Ink.swift: body text in the paper's own hue, almost black (9 to 13:1); secondary 7:1 (AAA);
 * hints, headings and meaning colours 6:1; "worth knowing" marks 3.3:1, lighter so ring segments differ
 * in lightness as well as hue. Gray paper takes a warm charcoal.
 */
fun Paper.ink(role: InkRole): Color = Color(when (role) {
        InkRole.TEXT -> when (this) { Paper.YELLOW -> 0xFF25230E; Paper.PINK -> 0xFF251010; Paper.GREEN -> 0xFF162414; Paper.BLUE -> 0xFF042025; Paper.PURPLE -> 0xFF111526; Paper.GRAY -> 0xFF1A1511 }
        InkRole.MUTED -> when (this) { Paper.YELLOW -> 0xFF504D30; Paper.PINK -> 0xFF4C2E2D; Paper.GREEN -> 0xFF3D5039; Paper.BLUE -> 0xFF284E55; Paper.PURPLE -> 0xFF242B43; Paper.GRAY -> 0xFF49433E }
        InkRole.SUBTLE -> when (this) { Paper.YELLOW -> 0xFF59573D; Paper.PINK -> 0xFF553938; Paper.GREEN -> 0xFF485944; Paper.BLUE -> 0xFF36575E; Paper.PURPLE -> 0xFF2F364C; Paper.GRAY -> 0xFF534C47 }
        InkRole.ACCENT -> when (this) { Paper.YELLOW -> 0xFF7E4921; Paper.PINK -> 0xFF653205; Paper.GREEN -> 0xFF7D4820; Paper.BLUE -> 0xFF7A451D; Paper.PURPLE -> 0xFF582A00; Paper.GRAY -> 0xFF744017 }
        InkRole.CONCERN -> when (this) { Paper.YELLOW -> 0xFF9E2D23; Paper.PINK -> 0xFF830D09; Paper.GREEN -> 0xFF9C2C22; Paper.BLUE -> 0xFF99291F; Paper.PURPLE -> 0xFF740001; Paper.GRAY -> 0xFF93231A }
        InkRole.FIX -> when (this) { Paper.YELLOW -> 0xFF0D6332; Paper.PINK -> 0xFF014B23; Paper.GREEN -> 0xFF0B6231; Paper.BLUE -> 0xFF045F2E; Paper.PURPLE -> 0xFF023F1D; Paper.GRAY -> 0xFF005A2B }
        InkRole.EDGE -> when (this) { Paper.YELLOW -> 0xFF275792; Paper.PINK -> 0xFF0D4079; Paper.GREEN -> 0xFF255691; Paper.BLUE -> 0xFF23538E; Paper.PURPLE -> 0xFF01366E; Paper.GRAY -> 0xFF1D4E88 }
        InkRole.AMBER -> when (this) { Paper.YELLOW -> 0xFFAD721C; Paper.PINK -> 0xFF905B00; Paper.GREEN -> 0xFFAC701B; Paper.BLUE -> 0xFFA86D15; Paper.PURPLE -> 0xFF835201; Paper.GRAY -> 0xFFA3680A }
        InkRole.RULE -> when (this) { Paper.YELLOW -> 0xFFA19F82; Paper.PINK -> 0xFF9B7B79; Paper.GREEN -> 0xFF8EA28A; Paper.BLUE -> 0xFF7C9FA6; Paper.PURPLE -> 0xFF707891; Paper.GRAY -> 0xFF99928C }
})

/** How a note is held on the page: a note that holds a list of rows is taped across the top, a single note is pinned (owner, 2026-11-06). */
enum class Fixing { PIN, TAPE }

/** How a note has aged. No coffee ring (owner, 2026-11-06: it read as dirt). */
private enum class Wear { TORN, CUT_CORNER, CURL, DOG_EAR, AGED }

/**
 * A detective's sticky note: the content on light paper in dark ink (LocalOnPaper), pinned or
 * taped, slightly askew, with its own wear. Tilt, fixing and wear come from the seed, so a page
 * never shows two the same, yet a note looks the same every time. It grows with its content.
 */
@Composable
fun StickyNote(paper: Paper, seed: String, fixing: Fixing = Fixing.PIN, onClick: (() -> Unit)? = null, content: @Composable BoxScope.() -> Unit) {
    val h = seed.fold(1469598103934665603uL) { acc, c -> (acc xor c.code.toULong()) * 1099511628211uL }
    val tilts = floatArrayOf(-1.2f, -0.9f, -0.6f, -0.35f, 0.35f, 0.6f, 0.9f, 1.2f)
    val tilt = tilts[(h % 8uL).toInt()]
    val tape = fixing == Fixing.TAPE
    val pins = listOf(Color(0xFFB22222), Color(0xFF2B5AA8), Color(0xFF2E8A4E), Color(0xFFD8B020))
    val pin = pins[((h shr 16) % 4uL).toInt()]
    val wear = Wear.entries[((h shr 24) % Wear.entries.size.toULong()).toInt()]
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
            CompositionLocalProvider(LocalOnPaper provides true, LocalPaper provides paper) { content() }
        }
        if (tape) {
            Box(Modifier.align(Alignment.TopCenter).offset(y = (-8).dp).size(64.dp, 18.dp).rotate(-4f).background(Color(0x8CF3EEDC)))
        } else {
            Box(Modifier.align(Alignment.TopCenter).offset(y = 4.dp).size(14.dp).shadow(2.dp, CircleShape).clip(CircleShape).background(pin))
        }
    }
}
