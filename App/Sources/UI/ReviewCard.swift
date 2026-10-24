// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import StoreKit
import SwiftUI

/// "Rate hYYa Footprint Inspector". Opens the App Store's write-review page once the app has an
/// App Store id (a button the user tapped must always do something visible). Until then it falls
/// back to Apple's in-app rating prompt.
struct ReviewCard: View {
    /// When set, the card offers "Not now" and calls this to hide itself.
    var onDismiss: (() -> Void)? = nil

    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @AppStorage("reviewCardTapped") private var tapped = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        // Mascot beside the text; above it at the largest text sizes, as on the page tops.
        let big = typeSize.isAccessibilitySize
        let layout = big ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        let buttons = big ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            LivingMascot(mood: .happy, size: 76)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(Brand.sand)
                    }
                }
                Text(tapped ? "Thank you for rating" : "Enjoying hYYa Footprint Inspector?")
                    .font(.headline)
                    .foregroundStyle(Brand.ink)
                Text("Your reviews keep us smiling while coding, and help others find a privacy app they can trust.")
                    .font(.footnote)
                    .foregroundStyle(Brand.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                buttons {
                    Button("Rate the App") { rate() }
                        .buttonStyle(PrimaryCTAButtonStyle(fullWidth: false))
                    if let onDismiss {
                        Button("Not now") { onDismiss() }
                            .font(.footnote)
                            .foregroundStyle(Brand.textSubtle)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            shape.fill(Brand.surface)
                .overlay(shape.fill(LinearGradient(colors: [Brand.sand.opacity(0.10), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)))
        )
        .overlay(shape.strokeBorder(LinearGradient(colors: [Brand.sand.opacity(0.8), Brand.sandDeep.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75))
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

/// "More from hYYa": the hYYa website, laid out like the rating card above it.
struct HyyaCard: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        Button { Haptics.selection(); openURL(hYYaLinks.website) } label: {
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
                    Text("Visit hyya.com")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Brand.onCTA)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Capsule().fill(Brand.cta))
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                shape.fill(Brand.surface)
                    .overlay(shape.fill(LinearGradient(colors: [Brand.sand.opacity(0.10), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)))
            )
            .overlay(shape.strokeBorder(LinearGradient(colors: [Brand.sand.opacity(0.8), Brand.sandDeep.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75))
        }
        .buttonStyle(PressableCardStyle())
    }
}
