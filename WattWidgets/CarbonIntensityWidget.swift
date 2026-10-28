import SwiftUI
import WattCore
import WattUI
import WidgetKit

struct CarbonEntry: TimelineEntry {
    let date: Date
    /// Last known data, live or cached. `nil` only when nothing was ever fetched.
    let snapshot: GridSnapshot?
    /// The latest fetch failed: we display cached data (if any) with an offline hint.
    let isOffline: Bool

    static func placeholder(now: Date = .now) -> CarbonEntry {
        CarbonEntry(date: now, snapshot: .sample(now: now), isOffline: false)
    }
}

struct CarbonProvider: TimelineProvider {
    private let client = ODREClient()
    private let store = SharedStore()

    func placeholder(in context: Context) -> CarbonEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (CarbonEntry) -> Void) {
        if context.isPreview {
            completion(CarbonEntry(date: .now, snapshot: store.loadSnapshot() ?? .sample(), isOffline: false))
            return
        }
        Task { completion(await entry().0) }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<CarbonEntry>) -> Void) {
        Task {
            let (entry, nextRefresh) = await entry()
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    /// Fetches fresh data, falling back to the App Group cache written by the app.
    private func entry(now: Date = .now) async -> (CarbonEntry, Date) {
        do {
            let snapshot = try await client.snapshot(now: now)
            try? store.save(snapshot)
            return (CarbonEntry(date: now, snapshot: snapshot, isOffline: false), snapshot.nextRefreshDate(after: now))
        } catch {
            let cached = store.loadSnapshot()
            return (CarbonEntry(date: now, snapshot: cached, isOffline: true), now.addingTimeInterval(15 * 60))
        }
    }
}

struct CarbonIntensityWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.carbonIntensity, provider: CarbonProvider()) { entry in
            CarbonSmallView(entry: entry)
                .widgetURL(URL(string: "watt://dashboard"))
        }
        .configurationDisplayName("Intensité carbone")
        .description("L'intensité carbone du réseau électrique français en ce moment.")
        .supportedFamilies([.systemSmall])
    }
}

struct CarbonSmallView: View {
    let entry: CarbonEntry
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        Group {
            if let reading = entry.snapshot?.latest {
                content(reading)
            } else {
                unavailable
            }
        }
        .containerBackground(for: .widget) {
            if let level = entry.snapshot?.latest?.level, renderingMode == .fullColor {
                LinearGradient(colors: [level.color.opacity(0.22), level.color.opacity(0.05)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                Color.clear
            }
        }
    }

    private func content(_ reading: CarbonReading) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                Text("CO₂")
                Spacer(minLength: 0)
                if entry.isOffline || entry.snapshot?.isStale(at: entry.date) == true {
                    Image(systemName: "wifi.slash")
                        .accessibilityLabel("Données non à jour")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(reading.intensity, format: .number)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .widgetAccentable()
            Text(WattStrings.unit)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            CarbonLevelBadge(level: reading.level)
            Text("Mesure de \(reading.date, format: .dateTime.hour().minute())")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reading.accessibilityDescription)
    }

    private var unavailable: some View {
        VStack(spacing: 6) {
            Image(systemName: "wifi.exclamationmark")
                .font(.title2)
            Text("Données indisponibles")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Vérifiez votre connexion")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(as: .systemSmall) {
    CarbonIntensityWidget()
} timeline: {
    CarbonEntry.placeholder()
    CarbonEntry(date: .now, snapshot: GridSnapshot(readings: [CarbonReading(date: .now, intensity: 112)], fetchedAt: .now),
                isOffline: true)
    CarbonEntry(date: .now, snapshot: nil, isOffline: true)
}
