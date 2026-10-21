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
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.Search
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

enum class Tab(val label: String, val icon: ImageVector) {
    SCAN("Scan", Icons.Outlined.Search),
    SENSITIVE("Sensitive apps", Icons.Outlined.VisibilityOff),
    CHECKUP("Check-up", Icons.Outlined.Checklist),
    SETTINGS("Settings", Icons.Outlined.Settings),
}

/** A screen pushed on top of a tab. */
sealed interface Route {
    data class SectionRoute(val section: Section) : Route
    data class FindingRoute(val id: String) : Route
    data class CheckUpRoute(val index: Int) : Route
    data object ScoreRoute : Route
}

class Nav {
    val stack = mutableStateListOf<Route>()
    fun push(r: Route) { stack.add(r) }
    fun pop() { if (stack.isNotEmpty()) stack.removeAt(stack.lastIndex) }
}

@Composable
fun App(startTab: Tab = Tab.SCAN, autoScan: Boolean = false) {
    val scanner: Scanner = viewModel()
    var tab by rememberSaveable { mutableStateOf(startTab) }
    val nav = remember { Nav() }
    if (autoScan && scanner.findings.isEmpty()) androidx.compose.runtime.LaunchedEffect(Unit) { scanner.scan() }

    BackHandler(enabled = nav.stack.isNotEmpty()) { nav.pop() }

    Scaffold(
        containerColor = Color.Black,
        bottomBar = {
            NavigationBar(containerColor = Brand.surface) {
                Tab.entries.forEach { t ->
                    NavigationBarItem(
                        selected = tab == t,
                        onClick = { tab = t; nav.stack.clear() },
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
            when (val top = nav.stack.lastOrNull()) {
                is Route.SectionRoute -> SectionScreen(scanner, top.section, nav)
                is Route.FindingRoute -> FindingScreen(scanner, top.id, nav)
                is Route.CheckUpRoute -> CheckUpStepScreen(top.index, nav)
                Route.ScoreRoute -> ScoreScreen(nav)
                null -> when (tab) {
                    Tab.SCAN -> ScanScreen(scanner, nav)
                    Tab.SENSITIVE -> SensitiveScreen()
                    Tab.CHECKUP -> CheckUpScreen(nav)
                    Tab.SETTINGS -> SettingsScreen(scanner)
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
