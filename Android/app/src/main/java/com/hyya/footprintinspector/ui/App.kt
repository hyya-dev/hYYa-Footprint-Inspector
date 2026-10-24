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
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.Pets
import androidx.compose.material.icons.outlined.Sensors
import androidx.compose.material.icons.outlined.Settings
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

/** The four steps in order, then Settings, as on iOS (App/Sources/UI/Kit/Journey.swift). */
enum class Tab(val label: String, val icon: ImageVector, val step: Int, val pitch: String) {
    SCAN("Footprint", Icons.Outlined.Pets, 1, "See what any app can read about this device."),
    SENSITIVE("Sensitive apps", Icons.Outlined.VisibilityOff, 2, "See which of your apps any app can spot, and what that says about you."),
    TRACKER("Tracker", Icons.Outlined.Sensors, 3, "See which apps can watch you, and what apps actually used."),
    CHECKUP("Check-up", Icons.Outlined.Checklist, 4, "Go through Settings one area at a time and take access back."),
    SETTINGS("Settings", Icons.Outlined.Settings, 0, ""),
}

/** A screen pushed on top of a tab. */
sealed interface Route {
    data class SectionRoute(val section: Section) : Route
    data class FindingRoute(val id: String) : Route
    data class CheckUpRoute(val index: Int) : Route
    data object ScoreRoute : Route
    data object FixRoute : Route
}

class Nav {
    val stack = mutableStateListOf<Route>()
    fun push(r: Route) { stack.add(r) }
    fun pop() { if (stack.isNotEmpty()) stack.removeAt(stack.lastIndex) }
}

@Composable
fun App(startTab: Tab = Tab.SCAN, autoScan: Boolean = false, openFinding: String? = null, openFix: Boolean = false) {
    val scanner: Scanner = viewModel()
    var tab by rememberSaveable { mutableStateOf(startTab) }
    val nav = remember { Nav().also { n -> openFinding?.let { n.push(Route.FindingRoute(it)) }; if (openFix) n.push(Route.FixRoute) } }
    if (autoScan && scanner.findings.isEmpty()) androidx.compose.runtime.LaunchedEffect(Unit) { scanner.scan() }
    // Store screenshots: a Sensitive check with nothing found, so the score can show three checks.
    if (com.hyya.footprintinspector.scan.Sample.on && scanner.sensitiveFound == null) scanner.sensitiveFound = 0

    BackHandler(enabled = nav.stack.isNotEmpty()) { nav.pop() }
    // The sensitive-app result counts in the score only while the app is on screen, like the
    // result itself; it's never saved.
    val owner = androidx.compose.ui.platform.LocalLifecycleOwner.current
    androidx.compose.runtime.DisposableEffect(owner) {
        val obs = androidx.lifecycle.LifecycleEventObserver { _, e -> if (e == androidx.lifecycle.Lifecycle.Event.ON_STOP) scanner.sensitiveFound = null }
        owner.lifecycle.addObserver(obs)
        onDispose { owner.lifecycle.removeObserver(obs) }
    }
    val view = androidx.compose.ui.platform.LocalView.current
    val goTo: (Tab) -> Unit = { t -> tab = t; nav.stack.clear() }

    Scaffold(
        containerColor = Color.Black,
        bottomBar = {
            NavigationBar(containerColor = Brand.surface) {
                Tab.entries.forEach { t ->
                    NavigationBarItem(
                        selected = tab == t,
                        onClick = { tab = t; nav.stack.clear(); view.performHapticFeedback(android.view.HapticFeedbackConstants.CONTEXT_CLICK) },
                        icon = { Icon(t.icon, contentDescription = null) },
                        label = { Text(t.label) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Brand.sand, selectedTextColor = Brand.sand,
                            indicatorColor = Brand.tile, unselectedIconColor = Brand.textMuted, unselectedTextColor = Brand.textMuted,
                        ),
                    )
                }
            }
        },
    ) { inner ->
        Box(Modifier.fillMaxSize().background(Color.Black).padding(inner)) {
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
                        Route.FixRoute -> FixScreen(scanner, nav)
                        null -> when (t) {
                            Tab.SCAN -> ScanScreen(scanner, nav)
                            Tab.SENSITIVE -> SensitiveScreen(scanner)
                            Tab.TRACKER -> TrackerScreen(scanner, nav)
                            Tab.CHECKUP -> CheckUpScreen(nav)
                            Tab.SETTINGS -> SettingsScreen(scanner)
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
            context.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); return
        } catch (_: ActivityNotFoundException) { } catch (_: SecurityException) { }
    }
}

fun openUrl(context: Context, url: String) {
    try { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } catch (_: ActivityNotFoundException) { }
}
