import Foundation
import Testing
@testable import WattCore

struct StubLoader: HTTPDataLoading {
    var data: Data
    var statusCode = 200

    func data(from url: URL) async throws -> (Data, URLResponse) {
        (data, HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!)
    }
}

func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Suite struct ODREClientTests {
    @Test func decodesRealResponseSkippingNullRows() async throws {
        let client = ODREClient(loader: StubLoader(data: try fixture("eco2mix-recent")))
        let readings = try await client.recentReadings()

        #expect(readings.count == 3)
        #expect(readings.map(\.date) == readings.map(\.date).sorted(), "readings are sorted oldest first")

        let latest = try #require(readings.last)
        #expect(latest.intensity == 43)
        #expect(latest.consumption == 49_798)
        #expect(latest.mix.nuclear == 41_645)
        #expect(latest.mix.hydro == 4_249, "string-encoded numbers are accepted")
        #expect(latest.date == ISO8601DateFormatter().date(from: "2026-10-28T15:30:00Z"))
    }

    @Test func throwsOnHTTPError() async throws {
        let client = ODREClient(loader: StubLoader(data: Data(), statusCode: 503))
        await #expect(throws: ODREError.badStatus(503)) { try await client.recentReadings() }
    }

    @Test func throwsWhenEveryRowIsEmpty() async throws {
        let body = #"{"total_count":1,"results":[{"date_heure":"2026-10-29T22:45:00+00:00","taux_co2":null}]}"#
        let client = ODREClient(loader: StubLoader(data: Data(body.utf8)))
        await #expect(throws: ODREError.noData) { try await client.recentReadings() }
    }

    @Test func requestFiltersNullRowsAndCapsLimit() throws {
        let url = ODREClient.recentURL(limit: 96)
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(items.contains(URLQueryItem(name: "where", value: "taux_co2 is not null")))
        #expect(items.contains(URLQueryItem(name: "order_by", value: "date_heure desc")))
        #expect(items.contains(URLQueryItem(name: "limit", value: "96")))
    }
}
