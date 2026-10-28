import Foundation
import Testing
@testable import WattCore

@Suite struct GridSnapshotTests {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    @Test(arguments: [(0, CarbonLevel.low), (40, .low), (41, .moderate), (80, .moderate), (81, .high), (400, .high)])
    func levelThresholds(intensity: Int, expected: CarbonLevel) {
        #expect(CarbonLevel(intensity: intensity) == expected)
    }

    @Test func mixShares() {
        let mix = ProductionMix(nuclear: 70, hydro: 10, wind: 5, solar: 5, gas: 10)
        #expect(mix.total == 100)
        #expect(mix.share(of: .nuclear) == 0.7)
        #expect(abs(mix.share(ofFamily: .renewable) - 0.2) < 1e-9)
        #expect(abs(mix.share(ofFamily: .fossil) - 0.1) < 1e-9)
        #expect(ProductionMix().share(of: .nuclear) == 0, "no division by zero")
    }

    @Test func sortsReadingsAndExposesLatest() {
        let snapshot = GridSnapshot(readings: [
            CarbonReading(date: t0.addingTimeInterval(900), intensity: 30),
            CarbonReading(date: t0, intensity: 50),
        ], fetchedAt: t0)
        #expect(snapshot.latest?.intensity == 30)
    }

    @Test func staleness() {
        let snapshot = GridSnapshot(readings: [CarbonReading(date: t0, intensity: 30)], fetchedAt: t0)
        #expect(!snapshot.isStale(at: t0.addingTimeInterval(30 * 60)))
        #expect(snapshot.isStale(at: t0.addingTimeInterval(61 * 60)))
        #expect(GridSnapshot(readings: [], fetchedAt: t0).isStale(at: t0))
    }

    @Test func nextRefreshNeverExceedsBudget() {
        let snapshot = GridSnapshot(readings: [CarbonReading(date: t0, intensity: 30)], fetchedAt: t0)
        // Fresh data: wait for the next quarter to be published.
        #expect(snapshot.nextRefreshDate(after: t0.addingTimeInterval(5 * 60)) == t0.addingTimeInterval(35 * 60))
        // Late data: retry in 15 min, never sooner.
        let now = t0.addingTimeInterval(60 * 60)
        #expect(snapshot.nextRefreshDate(after: now) == now.addingTimeInterval(15 * 60))
    }

    @Test func sharedStoreRoundTrip() throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SharedStore(directory: directory)
        #expect(store.loadSnapshot() == nil)

        let snapshot = GridSnapshot.sample(now: t0)
        try store.save(snapshot)
        #expect(store.loadSnapshot() == snapshot)
    }

    @Test func sampleCovers24Hours() {
        let snapshot = GridSnapshot.sample(now: t0)
        #expect(snapshot.readings.count == 96)
        #expect(snapshot.readings(within: 6 * 3600).count == 25)
    }
}
