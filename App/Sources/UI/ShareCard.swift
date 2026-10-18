// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// A picture to send to friends and family. It carries **no values from this phone**: no IDs,
/// dates, names or addresses. Only the score, the counts and the kinds of things found.
struct ShareCardView: View {
    let score: FootprintScore
    let total: Int
    let concerningTitles: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image("Mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("My device's footprint")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(score.value)")
                            .font(.system(size: 52, weight: .heavy))
                        Text("/ 100").font(.title3.weight(.semibold)).opacity(0.7)
                    }
                    .foregroundStyle(.white)
                }
            }
            Text("\(total) things any app could learn about my device, without asking.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            if !concerningTitles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Worth a look")
                        .font(.caption.weight(.heavy))
                        .tracking(1.4)
                        .foregroundStyle(Color(hex: 0x4FE3F0))
                    ForEach(concerningTitles.prefix(4), id: \.self) { title in
                        Label(title, systemImage: "circle.fill")
                            .labelStyle(DotLabelStyle())
                            .font(.body)
                            .foregroundStyle(.white)
                    }
                }
            }
            Divider().overlay(.white.opacity(0.3))
            Text("Check yours with hYYa Footprint Inspector. Free, open source, and nothing leaves your device.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(28)
        .frame(width: 400)
        .background(
            LinearGradient(colors: [Color(hex: 0x1F5BD6), Color(hex: 0x0E1E4A)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}

private struct DotLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: 0xF6B04A)).frame(width: 7, height: 7)
            configuration.title
        }
    }
}

/// The share button: renders the card to an image on the phone and hands it to the share sheet.
struct ShareCardButton: View {
    @Environment(Scanner.self) private var scanner
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        if let image = render() {
            ShareLink(item: image, preview: SharePreview("My device's footprint", image: image)) {
                Label("Share my result", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(GhostButtonStyle())
        }
    }

    @MainActor
    private func render() -> Image? {
        let card = ShareCardView(score: scanner.score,
                                 total: scanner.findingsWithoutAsking.count,
                                 concerningTitles: scanner.concerning.map(\.definition.title))
        let renderer = ImageRenderer(content: card)
        renderer.scale = displayScale
        guard let ui = renderer.uiImage else { return nil }
        return Image(uiImage: ui)
    }
}
