import Foundation

/// One quarter-hour measurement of the French grid (éCO2mix "temps réel").
public struct CarbonReading: Codable, Hashable, Sendable, Identifiable {
    public var date: Date
    /// Carbon intensity in gCO₂eq/kWh.
    public var intensity: Int
    /// Consumption in MW.
    public var consumption: Int?
    public var mix: ProductionMix

    public var id: Date { date }
    public var level: CarbonLevel { CarbonLevel(intensity: intensity) }

    public init(date: Date, intensity: Int, consumption: Int? = nil, mix: ProductionMix = .init()) {
        self.date = date
        self.intensity = intensity
        self.consumption = consumption
        self.mix = mix
    }
}

/// Production by source, in MW.
public struct ProductionMix: Codable, Hashable, Sendable {
    public var nuclear: Int
    public var hydro: Int
    public var wind: Int
    public var solar: Int
    public var bioenergy: Int
    public var gas: Int
    public var coal: Int
    public var oil: Int

    public init(nuclear: Int = 0, hydro: Int = 0, wind: Int = 0, solar: Int = 0,
                bioenergy: Int = 0, gas: Int = 0, coal: Int = 0, oil: Int = 0) {
        self.nuclear = nuclear
        self.hydro = hydro
        self.wind = wind
        self.solar = solar
        self.bioenergy = bioenergy
        self.gas = gas
        self.coal = coal
        self.oil = oil
    }

    public var total: Int { Source.allCases.reduce(0) { $0 + self[$1] } }

    public subscript(source: Source) -> Int {
        switch source {
        case .nuclear: nuclear
        case .hydro: hydro
        case .wind: wind
        case .solar: solar
        case .bioenergy: bioenergy
        case .gas: gas
        case .coal: coal
        case .oil: oil
        }
    }

    /// Share of `source` in total production, between 0 and 1.
    public func share(of source: Source) -> Double {
        let total = total
        guard total > 0 else { return 0 }
        return Double(max(self[source], 0)) / Double(total)
    }

    /// Aggregated shares by family (nuclear / renewables / fossil).
    public func share(ofFamily family: Source.Family) -> Double {
        Source.allCases.filter { $0.family == family }.reduce(0) { $0 + share(of: $1) }
    }

    public enum Source: String, CaseIterable, Codable, Sendable {
        case nuclear, hydro, wind, solar, bioenergy, gas, coal, oil

        public enum Family: String, CaseIterable, Sendable {
            case nuclear, renewable, fossil
        }

        public var family: Family {
            switch self {
            case .nuclear: .nuclear
            case .hydro, .wind, .solar, .bioenergy: .renewable
            case .gas, .coal, .oil: .fossil
            }
        }
    }
}

/// Qualitative bucket for an intensity value. Never conveyed by color alone: always pair with `title`.
public enum CarbonLevel: String, Codable, Sendable, CaseIterable {
    case low, moderate, high

    /// Upper bounds (inclusive) in gCO₂/kWh, tuned for the French grid which usually sits between 20 and 100.
    public static let lowUpperBound = 40
    public static let moderateUpperBound = 80

    public init(intensity: Int) {
        switch intensity {
        case ...Self.lowUpperBound: self = .low
        case ...Self.moderateUpperBound: self = .moderate
        default: self = .high
        }
    }
}
