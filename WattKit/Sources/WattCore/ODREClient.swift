import Foundation

/// Abstraction over the network so the client can be tested with canned responses.
public protocol HTTPDataLoading: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPDataLoading {
    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await data(from: url, delegate: nil)
    }
}

public enum ODREError: Error, Equatable, Sendable {
    case badStatus(Int)
    case noData
}

/// Client for the éCO2mix real-time dataset on the ODRÉ open data platform (Opendatasoft Explore API v2.1).
/// Public, unauthenticated, licensed under Licence Ouverte / Etalab 2.0.
public struct ODREClient: Sendable {
    public static let baseURL = URL(string: "https://odre.opendatasoft.com/api/explore/v2.1/catalog/datasets/eco2mix-national-tr/records")!
    /// Opendatasoft caps `limit` at 100 records per request.
    static let pageSize = 100

    private let loader: HTTPDataLoading

    public init(loader: HTTPDataLoading = URLSession.shared) {
        self.loader = loader
    }

    /// Most recent readings, newest last. 96 quarter-hours = 24 h.
    public func recentReadings(count: Int = 96) async throws -> [CarbonReading] {
        let (data, response) = try await loader.data(from: Self.recentURL(limit: min(count, Self.pageSize)))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ODREError.badStatus(http.statusCode)
        }
        let readings = try Self.decode(data)
        guard !readings.isEmpty else { throw ODREError.noData }
        return readings.sorted { $0.date < $1.date }
    }

    /// The latest snapshot ready to be cached for widgets.
    public func snapshot(now: Date = .now) async throws -> GridSnapshot {
        GridSnapshot(readings: try await recentReadings(), fetchedAt: now)
    }

    static func recentURL(limit: Int) -> URL {
        baseURL.appending(queryItems: [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "order_by", value: "date_heure desc"),
            // Rows for upcoming quarters exist with null values: skip them.
            URLQueryItem(name: "where", value: "taux_co2 is not null"),
            URLQueryItem(name: "select", value: "date_heure,taux_co2,consommation,nucleaire,hydraulique,eolien,solaire,bioenergies,gaz,charbon,fioul"),
        ])
    }

    static func decode(_ data: Data) throws -> [CarbonReading] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Page.self, from: data).results.compactMap(\.reading)
    }

    private struct Page: Decodable {
        let results: [Record]
    }

    private struct Record: Decodable {
        let date_heure: Date
        let taux_co2: LenientInt?
        let consommation: LenientInt?
        let nucleaire, hydraulique, eolien, solaire, bioenergies, gaz, charbon, fioul: LenientInt?

        var reading: CarbonReading? {
            guard let intensity = taux_co2?.value else { return nil }
            return CarbonReading(
                date: date_heure,
                intensity: intensity,
                consumption: consommation?.value,
                mix: ProductionMix(
                    nuclear: nucleaire?.value ?? 0,
                    hydro: hydraulique?.value ?? 0,
                    wind: eolien?.value ?? 0,
                    solar: solaire?.value ?? 0,
                    bioenergy: bioenergies?.value ?? 0,
                    gas: gaz?.value ?? 0,
                    coal: charbon?.value ?? 0,
                    oil: fioul?.value ?? 0
                )
            )
        }
    }
}

/// The dataset sometimes encodes numbers as strings (e.g. `"2465"`) or `null`.
struct LenientInt: Decodable {
    let value: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = Int(double.rounded())
        } else if let string = try? container.decode(String.self) {
            value = Int(string) ?? Double(string).map { Int($0.rounded()) }
        } else {
            value = nil
        }
    }
}
