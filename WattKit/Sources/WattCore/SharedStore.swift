import Foundation

public enum AppGroup {
    public static let identifier = "group.com.mtm-capital.watt"
}

/// JSON file cache shared between the app and its extensions through the App Group container.
public struct SharedStore: Sendable {
    private let directory: URL

    /// Falls back to the caches directory when the App Group isn't provisioned (unit tests, misconfigured signing).
    public init(groupIdentifier: String = AppGroup.identifier) {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
        self.init(directory: container ?? URL.cachesDirectory)
    }

    public init(directory: URL) {
        self.directory = directory
    }

    private var snapshotURL: URL { directory.appending(path: "grid-snapshot.json") }

    public func loadSnapshot() -> GridSnapshot? {
        guard let data = try? Data(contentsOf: snapshotURL) else { return nil }
        return try? Self.decoder.decode(GridSnapshot.self, from: data)
    }

    public func save(_ snapshot: GridSnapshot) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Self.encoder.encode(snapshot).write(to: snapshotURL, options: .atomic)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

/// Widget kinds, shared so the app can reload specific timelines.
public enum WidgetKind {
    public static let carbonIntensity = "CarbonIntensityWidget"
}
