import SwiftUI
import WattCore

extension CarbonLevel {
    public var title: String {
        switch self {
        case .low: String(localized: "Faible", bundle: .module, comment: "Carbon intensity level")
        case .moderate: String(localized: "Modérée", bundle: .module, comment: "Carbon intensity level")
        case .high: String(localized: "Élevée", bundle: .module, comment: "Carbon intensity level")
        }
    }

    public var color: Color {
        switch self {
        case .low: .green
        case .moderate: .orange
        case .high: .red
        }
    }

    /// Distinct shape per level so the information never relies on color alone.
    public var symbolName: String {
        switch self {
        case .low: "leaf.fill"
        case .moderate: "circle.lefthalf.filled"
        case .high: "exclamationmark.triangle.fill"
        }
    }
}

extension ProductionMix.Source {
    public var title: String {
        switch self {
        case .nuclear: String(localized: "Nucléaire", bundle: .module)
        case .hydro: String(localized: "Hydraulique", bundle: .module)
        case .wind: String(localized: "Éolien", bundle: .module)
        case .solar: String(localized: "Solaire", bundle: .module)
        case .bioenergy: String(localized: "Bioénergies", bundle: .module)
        case .gas: String(localized: "Gaz", bundle: .module)
        case .coal: String(localized: "Charbon", bundle: .module)
        case .oil: String(localized: "Fioul", bundle: .module)
        }
    }

    public var color: Color {
        switch self {
        case .nuclear: .yellow
        case .hydro: .blue
        case .wind: .teal
        case .solar: .orange
        case .bioenergy: .green
        case .gas: .gray
        case .coal: .brown
        case .oil: .purple
        }
    }
}

extension ProductionMix.Source.Family {
    public var title: String {
        switch self {
        case .nuclear: String(localized: "Nucléaire", bundle: .module)
        case .renewable: String(localized: "Renouvelables", bundle: .module)
        case .fossil: String(localized: "Fossiles", bundle: .module)
        }
    }

    public var color: Color {
        switch self {
        case .nuclear: .yellow
        case .renewable: .green
        case .fossil: .gray
        }
    }
}

extension CarbonReading {
    /// Full sentence for VoiceOver, e.g. "Intensité carbone : 43 grammes de CO₂ par kilowattheure, niveau faible".
    public var accessibilityDescription: String {
        String(localized: "Intensité carbone : \(intensity) grammes de CO₂ par kilowattheure, niveau \(level.title.lowercased())",
               bundle: .module)
    }
}

public enum WattStrings {
    public static let unit = "gCO₂/kWh"
    public static var carbonIntensity: String { String(localized: "Intensité carbone", bundle: .module) }
    public static var dataSource: String {
        String(localized: "Données : RTE éCO2mix via ODRÉ, Licence Ouverte v2.0 (Etalab).", bundle: .module)
    }
}
