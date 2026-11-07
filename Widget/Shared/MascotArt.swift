// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// The detective. On a dark ground he is the night render: its night scene
/// fades into the page, so he stands in his own red beam. On light paper, such as a sticky note or
/// the light widget, he stays the cut-out, which that scene would only wash out.
struct MascotArt: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Image(scheme == .dark ? "MascotNight" : "MascotCutout").resizable().scaledToFit()
    }
}
