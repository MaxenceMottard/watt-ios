import Foundation
import Observation
import WattCore
import WidgetKit

@Observable
final class DashboardModel {
    private(set) var snapshot: GridSnapshot?
    private(set) var isLoading = false
    private(set) var lastError: Error?

    private let client: ODREClient
    private let store: SharedStore

    init(client: ODREClient = ODREClient(), store: SharedStore = SharedStore()) {
        self.client = client
        self.store = store
        snapshot = store.loadSnapshot()
    }

    /// Fetches fresh data, caches it in the App Group and asks widgets to reload.
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await client.snapshot()
            self.snapshot = snapshot
            lastError = nil
            try? store.save(snapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.carbonIntensity)
        } catch {
            lastError = error
        }
    }
}
