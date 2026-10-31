// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector.ui

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.layout.height
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.Pets
import androidx.compose.material.icons.outlined.Sensors
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.viewmodel.compose.viewModel
import com.hyya.footprintinspector.model.Section
import com.hyya.footprintinspector.scan.Scanner

/** The Score page, the four steps in order, then Settings, as on iOS (App/Sources/UI/Kit/Journey.swift). */
enum class Tab(val label: String, val icon: ImageVector, val step: Int, val pitch: String) {
    HOME("Score", Icons.Outlined.Speed, 0, ""),
    SCAN("Footprint", Icons.Outlined.Pets, 1, "See what any app can read about this device."),
    SENSITIVE("Sensitive apps", Icons.Outlined.VisibilityOff, 2, "See which of your apps any app can spot, and what that says about you."),
    TRACKER("Tracker", Icons.Outlined.Sensors, 3, "See which apps can watch you, and what apps actually used."),
    CHECKUP("Check-up", Icons.Outlined.Checklist, 4, "Go through Settings one area at a time and take access back."),
    SETTINGS("Settings", Icons.Outlined.Settings, 0, ""),
    ;

    /** One word, for the navigation bar. */
    val short: String get() = if (this == SENSITIVE) "Sensitive" else label

    companion object {
        /** The navigation bar's destinations; Settings opens from the Score page. */
        val bar = listOf(HOME, SCAN, SENSITIVE, TRACKER, CHECKUP, SETTINGS)
    }
}

/** A screen pushed on top of a tab. */
sealed interface Route {
    data class SectionRoute(val section: Section) : Route
    data class FindingRoute(val id: String) : Route
    data class CheckUpRoute(val index: Int) : Route
    data object ScoreRoute : Route
    data object FixRoute : Route
    data object SettingsRoute : Route
}

class Nav {
    val stack = mutableStateListOf<Route>()
    fun push(r: Route) { stack.add(r) }
    fun pop() { if (stack.isNotEmpty()) stack.removeAt(stack.lastIndex) }

    companion object {
        /**
         * The open screens, kept by Android with the activity: it often stops the app in the
         * background while the person changes a setting, and coming back must land on the same
         * screen (owner, 2026-10-28).
         */
        val Saver: androidx.compose.runtime.saveable.Saver<Nav, ArrayList<String>> = androidx.compose.runtime.saveable.Saver(
            save = { nav -> ArrayList(nav.stack.map { encode(it) }) },
            restore = { saved -> Nav().also { n -> saved.mapNotNull(::decode).forEach(n::push) } },
        )
        private fun encode(r: Route) = when (r) {
            is Route.SectionRoute -> "section:${r.section.name}"
            is Route.FindingRoute -> "finding:${r.id}"
            is Route.CheckUpRoute -> "checkup:${r.index}"
            Route.ScoreRoute -> "score"
            Route.FixRoute -> "fix"
            Route.SettingsRoute -> "settings"
        }
        private fun decode(s: String): Route? {
            val (kind, arg) = s.substringBefore(':') to s.substringAfter(':', "")
            return when (kind) {
                "section" -> Section.entries.firstOrNull { it.name == arg }?.let { Route.SectionRoute(it) }
                "finding" -> Route.FindingRoute(arg)
                "checkup" -> arg.toIntOrNull()?.let { Route.CheckUpRoute(it) }
                "score" -> Route.ScoreRoute
                "fix" -> Route.FixRoute
                "settings" -> Route.SettingsRoute
                else -> null
            }
        }
    }
}

@Composable
fun App(startTab: Tab = Tab.HOME, autoScan: Boolean = false, openFinding: String? = null, openFix: Boolean = false) {
    val scanner: Scanner = viewModel()
    var tab by rememberSaveable { mutableStateOf(startTab) }
    val nav = rememberSaveable(saver = Nav.Saver) { Nav().also { n -> openFinding?.let { n.push(Route.FindingRoute(it)) }; if (openFix) n.push(Route.FixRoute) } }
    if (autoScan && scanner.findings.isEmpty()) androidx.compose.runtime.LaunchedEffect(Unit) { scanner.scan() }
    // Store screenshots: a Sensitive check with nothing found, so the score can show three checks.
    if (com.hyya.footprintinspector.scan.Sample.on && scanner.sensitiveFound == null) scanner.recordSensitive(0)

    BackHandler(enabled = nav.stack.isNotEmpty()) { nav.pop() }
    // Keeps the score current: on launch and each time the app comes back to the screen (after
    // changing a setting, say), it re-reads quietly if a scan was done before.
    val owner = androidx.compose.ui.platform.LocalLifecycleOwner.current
    androidx.compose.runtime.DisposableEffect(owner) {
        val obs = androidx.lifecycle.LifecycleEventObserver { _, e ->
            if (e == androidx.lifecycle.Lifecycle.Event.ON_START && !autoScan && scanner.history.latest != null) scanner.scan(quietly = true)
        }
        owner.lifecycle.addObserver(obs)
        onDispose { owner.lifecycle.removeObserver(obs) }
    }
    val view = androidx.compose.ui.platform.LocalView.current
    val goTo: (Tab) -> Unit = { t -> tab = t; nav.stack.clear() }

    // The navbar: Google's standard bar along the bottom upright and rail down the left edge
    // sideways, all six pages with one-word names, Settings included (owner, 2026-10-29).
    val config = androidx.compose.ui.platform.LocalConfiguration.current
    val rail = config.screenWidthDp > config.screenHeightDp
    val shortRail = config.screenHeightDp < 480
    val select: (Tab) -> Unit = { t -> tab = t; nav.stack.clear(); view.performHapticFeedback(android.view.HapticFeedbackConstants.CONTEXT_CLICK) }

    Scaffold(
        containerColor = Color.Black,
        bottomBar = {
            // Google's standard navigation bar: Score, the four checks and Settings (owner,
            // 2026-10-29: Settings stays in the bar).
            if (!rail) NavigationBar(containerColor = Brand.surface) {
                Tab.bar.forEach { t ->
                    NavigationBarItem(
                        selected = tab == t, onClick = { select(t) },
                        icon = { Icon(t.icon, contentDescription = null) },
                        // Six names on a narrow phone: a size smaller so "Check-up" isn't clipped.
                        label = { Text(t.short, maxLines = 1, softWrap = false, fontSize = if (config.screenWidthDp < 400) 11.sp else 12.sp) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Brand.sand, selectedTextColor = Brand.sand,
                            indicatorColor = Brand.tile, unselectedIconColor = Brand.textMuted, unselectedTextColor = Brand.textMuted,
                        ),
                    )
                }
            }
        },
    ) { inner ->
        androidx.compose.foundation.layout.Row(Modifier.fillMaxSize().background(Color.Black).padding(inner)) {
        // Sideways, Google's standard navigation rail down the left edge.
        if (rail) androidx.compose.material3.NavigationRail(containerColor = Brand.surface) {
            Tab.bar.forEach { t ->
                androidx.compose.material3.NavigationRailItem(
                    selected = tab == t, onClick = { select(t) },
                    // On a short screen six labelled items don't fit, so they show icons only (the
                    // selected one keeps its highlight) and are a little shorter: all six, Settings
                    // included, stay on screen. The names are still read out by TalkBack.
                    modifier = if (shortRail) Modifier.height(44.dp) else Modifier,
                    icon = { Icon(t.icon, contentDescription = if (shortRail) t.short else null) },
                    label = if (shortRail) null else ({ Text(t.short, maxLines = 1, softWrap = false) }),
                    colors = androidx.compose.material3.NavigationRailItemDefaults.colors(
                        selectedIconColor = Brand.sand, selectedTextColor = Brand.sand,
                        indicatorColor = Brand.tile, unselectedIconColor = Brand.textMuted, unselectedTextColor = Brand.textMuted,
                    ),
                )
            }
        }
        Box(Modifier.weight(1f).fillMaxSize()) {
            androidx.compose.runtime.CompositionLocalProvider(LocalGoTo provides goTo) {
                // Pushing a page slides it in from the side; switching tabs cross-fades with a slight
                // lift. Android scales both by the system's animation setting (off when Remove
                // animations is on).
                val screen = nav.stack.lastOrNull() to tab
                androidx.compose.animation.AnimatedContent(
                    targetState = screen,
                    transitionSpec = {
                        val pushing = targetState.first != null && (initialState.first == null || nav.stack.size > 0 && targetState.first != initialState.first)
                        val tween = androidx.compose.animation.core.tween<androidx.compose.ui.unit.IntOffset>(320, easing = androidx.compose.animation.core.FastOutSlowInEasing)
                        if (targetState.second != initialState.second && targetState.first == null && initialState.first == null) {
                            (androidx.compose.animation.fadeIn(androidx.compose.animation.core.tween(260)) + androidx.compose.animation.slideInVertically(tween) { it / 40 }) togetherWith
                                androidx.compose.animation.fadeOut(androidx.compose.animation.core.tween(180))
                        } else if (pushing) {
                            androidx.compose.animation.slideInHorizontally(tween) { it } togetherWith
                                (androidx.compose.animation.slideOutHorizontally(tween) { -it / 4 } + androidx.compose.animation.fadeOut(androidx.compose.animation.core.tween(220)))
                        } else {
                            androidx.compose.animation.slideInHorizontally(tween) { -it / 4 } + androidx.compose.animation.fadeIn(androidx.compose.animation.core.tween(220)) togetherWith
                                androidx.compose.animation.slideOutHorizontally(tween) { it }
                        }
                    },
                    label = "screen",
                ) { (top, t) ->
                    when (top) {
                        is Route.SectionRoute -> SectionScreen(scanner, top.section, nav)
                        is Route.FindingRoute -> FindingScreen(scanner, top.id, nav)
                        is Route.CheckUpRoute -> CheckUpStepScreen(top.index, nav)
                        Route.ScoreRoute -> ScoreScreen(nav)
                        Route.SettingsRoute -> SettingsScreen(scanner, nav)
                        Route.FixRoute -> FixScreen(scanner, nav)
                        null -> when (t) {
                            Tab.HOME -> HomeScreen(scanner, nav)
                            Tab.SCAN -> ScanScreen(scanner, nav)
                            Tab.SENSITIVE -> SensitiveScreen(scanner)
                            Tab.TRACKER -> TrackerScreen(scanner, nav)
                            Tab.CHECKUP -> CheckUpScreen(nav)
                            Tab.SETTINGS -> SettingsScreen(scanner, nav)
                        }
                    }
                }
            }
        }
        }
    }
}

/** Opens a Settings page; falls back to the Settings home where a device doesn't have it. */
fun openSettings(context: Context, action: String?) {
    val intents = listOfNotNull(action?.let { Intent(it) }, Intent(Settings.ACTION_SETTINGS))
    for (i in intents) {
        try {
            // Only the system's own Settings, never another app registered for the same action.
            context.packageManager.resolveActivity(i, android.content.pm.PackageManager.MATCH_SYSTEM_ONLY)
                ?.activityInfo?.packageName?.let(i::setPackage)
            context.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); return
        } catch (_: ActivityNotFoundException) { } catch (_: SecurityException) { }
    }
}

fun openUrl(context: Context, url: String) {
    try { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } catch (_: ActivityNotFoundException) { }
}

