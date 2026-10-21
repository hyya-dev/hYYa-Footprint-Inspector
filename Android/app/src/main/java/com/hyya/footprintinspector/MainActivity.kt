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
        Sample.on = intent.getBooleanExtra("sampleData", false)
        val startTab = intent.getStringExtra("startTab")?.let { name -> Tab.entries.firstOrNull { it.name.equals(name, true) } } ?: Tab.SCAN
        val autoScan = intent.getBooleanExtra("autoScan", false)
        setContent { FootprintTheme { App(startTab, autoScan) } }
    }
}
