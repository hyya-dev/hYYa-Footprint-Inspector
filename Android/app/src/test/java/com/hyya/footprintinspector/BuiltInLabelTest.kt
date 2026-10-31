// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package com.hyya.footprintinspector

import com.hyya.footprintinspector.scan.borrowsBuiltIn
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BuiltInLabelTest {
    @Test fun lookAlikeNamesAreCaught() {
        assertTrue(borrowsBuiltIn("Spy · built into your device"))
        assertTrue(borrowsBuiltIn("Spy · BUILT INTO YOUR DEVICE"))
        assertTrue(borrowsBuiltIn("Spy\u00A0·\u00A0Built\u00A0into\u00A0your\u00A0device"))
        assertFalse(borrowsBuiltIn("Weather"))
    }
}
