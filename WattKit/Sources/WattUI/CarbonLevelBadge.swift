import SwiftUI
import WidgetKit
import WattCore

/// Icon + label for a carbon level. The text always carries the meaning; color is a hint.
public struct CarbonLevelBadge: View {
    let level: CarbonLevel

    public init(level: CarbonLevel) {
        self.level = level
    }

    public var body: some View {
        Label {
            Text(level.title)
        } icon: {
            Image(systemName: level.symbolName)
                .foregroundStyle(level.color)
                .widgetAccentable()
        }
        .font(.caption.weight(.semibold))
    }
}

/// Horizontal stacked bar showing nuclear / renewable / fossil shares.
public struct MixBar: View {
    let mix: ProductionMix

    public init(mix: ProductionMix) {
        self.mix = mix
    }

    public var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(ProductionMix.Source.Family.allCases, id: \.self) { family in
                    let share = mix.share(ofFamily: family)
                    if share > 0 {
                        Capsule()
                            .fill(family.color)
                            .frame(width: max(2, (proxy.size.width - 4) * share))
                    }
                }
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        ProductionMix.Source.Family.allCases
            .map { "\($0.title) \(mix.share(ofFamily: $0).formatted(.percent.precision(.fractionLength(0))))" }
            .joined(separator: ", ")
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(CarbonLevel.allCases, id: \.self) { CarbonLevelBadge(level: $0) }
        MixBar(mix: GridSnapshot.sample().latest!.mix)
    }
    .padding()
}
