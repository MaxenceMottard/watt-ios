import Foundation

/// What the app caches in the App Group and what widgets render.
public struct GridSnapshot: Codable, Hashable, Sendable {
    /// Readings sorted oldest first.
    public var readings: [CarbonReading]
    public var fetchedAt: Date

    public init(readings: [CarbonReading], fetchedAt: Date) {
        self.readings = readings.sorted { $0.date < $1.date }
        self.fetchedAt = fetchedAt
    }

    public var latest: CarbonReading? { readings.last }

    /// Readings within the last `interval` before the latest one.
    public func readings(within interval: TimeInterval) -> [CarbonReading] {
        guard let latest else { return [] }
        let start = latest.date.addingTimeInterval(-interval)
        return readings.filter { $0.date >= start }
    }

    /// éCO2mix publishes a new quarter roughly 15 min after its timestamp. Data older than this is considered stale.
    public static let staleAfter: TimeInterval = 60 * 60

    public func isStale(at date: Date = .now) -> Bool {
        guard let latest else { return true }
        return date.timeIntervalSince(latest.date) > Self.staleAfter
    }

    /// When the next quarter-hour reading should be available, used to schedule widget reloads.
    /// Never earlier than 15 min from `now` to stay within the WidgetKit refresh budget.
    public func nextRefreshDate(after now: Date = .now) -> Date {
        let minimum = now.addingTimeInterval(15 * 60)
        guard let latest else { return minimum }
        // New data typically lands ~20 min after the measured quarter starts.
        let expected = latest.date.addingTimeInterval(35 * 60)
        return max(expected, minimum)
    }
}

extension GridSnapshot {
    /// Realistic sample data for previews, placeholders and tests.
    public static func sample(now: Date = .now) -> GridSnapshot {
        let quarter: TimeInterval = 15 * 60
        let end = Date(timeIntervalSinceReferenceDate: (now.timeIntervalSinceReferenceDate / quarter).rounded(.down) * quarter)
        let readings = (0..<96).map { index -> CarbonReading in
            let date = end.addingTimeInterval(-Double(95 - index) * quarter)
            let phase = Double(index) / 96 * 2 * .pi
            let intensity = Int(38 + 14 * sin(phase - 0.6))
            let solar = max(0, Int(7_000 * sin(phase - .pi / 2)))
            return CarbonReading(
                date: date,
                intensity: intensity,
                consumption: 48_000,
                mix: ProductionMix(nuclear: 41_000, hydro: 4_200, wind: 2_500, solar: solar,
                                   bioenergy: 1_000, gas: 2_000 + intensity * 40, coal: 0, oil: 40)
            )
        }
        return GridSnapshot(readings: readings, fetchedAt: now)
    }
}
