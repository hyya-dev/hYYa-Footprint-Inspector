// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import StoreKit
import SwiftUI

/// "Rate hYYa Digital Footprint Check". Opens the App Store's write-review page once the app has an
/// App Store id (a tap must always do something visible). Until then it falls back to Apple's
/// in-app rating prompt.
struct ReviewCard: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @AppStorage("reviewCardTapped") private var tapped = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // Mascot beside the text; above it at the largest text sizes, as on the page tops.
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        // The whole card rates the app; the pill is its label, centred across the card.
        Button { rate() } label: {
            VStack(spacing: 14) {
                layout {
                    LivingMascot(mood: .happy, size: 76)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill").font(.caption).foregroundStyle(Brand.sand)
                            }
                        }
                        Text(tapped ? "Thank you for rating" : "Enjoying hYYa Digital Footprint Check?")
                            .font(.headline)
                            .foregroundStyle(Brand.ink)
                        Text("Your reviews keep us smiling while coding, and help others find a privacy app they can trust.")
                            .font(.footnote)
                            .foregroundStyle(Brand.textMuted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                CardPill(title: "Rate the App")
            }
            .padding(16)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .stickyNote(.purple, seed: "rate")
        }
        .buttonStyle(PressableCardStyle())
    }

    private func rate() {
        Haptics.selection()
        tapped = true
        if let url = hYYaLinks.appStoreReview {
            openURL(url)
        } else {
            requestReview()
        }
    }
}

/// The white pill inside a tappable card: it looks like the primary button, but the card is the button.
private struct CardPill: View {
    let title: LocalizedStringKey
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Text(title)
            .font(.body.weight(.semibold))
            .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(Brand.shrinkToFitFloor)
            .foregroundStyle(Brand.onCTA)
            .padding(.vertical, 15)
            .padding(.horizontal, 24)
            .background(Capsule().fill(Brand.cta))
    }
}

/// "More from hYYa": the hYYa website, laid out like the rating card above it.
struct HyyaCard: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        Button { Haptics.selection(); openURL(hYYaLinks.website) } label: {
            VStack(spacing: 14) {
                layout {
                    Image("HyyaDev")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("hYYa \u{2728}").font(.headline).foregroundStyle(Brand.ink)
                        Text("Companions you can trust: private apps that keep everything on your device.")
                            .font(.footnote)
                            .foregroundStyle(Brand.textMuted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                CardPill(title: "Visit hyya.com")
            }
            .padding(16)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .stickyNote(.blue, seed: "hyya")
        }
        .buttonStyle(PressableCardStyle())
    }
}
