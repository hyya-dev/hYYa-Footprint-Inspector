// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector

import com.hyya.footprintinspector.scan.RecentRestart
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Owner's test, 2026-10-28: a restart within the last week counts as done. */
class RecentRestartTest {
    @Test fun aRestartWithinAWeekCounts() {
        val day = 24L * 3600 * 1000
        assertTrue(RecentRestart.isRecent(2 * day))
        assertFalse(RecentRestart.isRecent(8 * day))
    }
}
