// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.hyya.footprintinspector.scan.Sample
import com.hyya.footprintinspector.ui.App
import com.hyya.footprintinspector.ui.FootprintTheme
import com.hyya.footprintinspector.ui.Tab

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(statusBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT))
        // Screenshot switches (adb shell am start … --ez sampleData true --es startTab sensitive --ez autoScan true).
        // Debug builds only: this activity is exported (it's the launcher), so in a store build any
        // installed app could otherwise start it with made-up, reassuring results.
        val dev = BuildConfig.DEBUG
        Sample.on = dev && intent.getBooleanExtra("sampleData", false)
        val startTab = (if (dev) intent.getStringExtra("startTab") else null)?.let { name -> Tab.entries.firstOrNull { it.name.equals(name, true) } } ?: Tab.HOME
        val autoScan = dev && intent.getBooleanExtra("autoScan", false)
        if (dev) intent.getStringExtra("sensitiveCategories")?.let { ids ->
            getSharedPreferences("app", MODE_PRIVATE).edit().putStringSet("sensitiveCategories", ids.split(",").toSet()).apply()
        }
        // Shows the re-scan reminder now, to check it without waiting a week.
        if (dev && intent.getBooleanExtra("testReminder", false)) com.hyya.footprintinspector.remind.ScanReminder.post(this)
        val openFinding = if (dev) intent.getStringExtra("openFinding") else null
        val openFix = dev && intent.getBooleanExtra("openFix", false)
        setContent { FootprintTheme { App(startTab, autoScan, openFinding, openFix) } }
    }
}
