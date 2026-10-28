import Charts
import SwiftUI
import WattCore

/// Carbon intensity curve, with the level thresholds drawn as dashed rules.
public struct IntensityChart: View {
    let readings: [CarbonReading]

    public init(readings: [CarbonReading]) {
        self.readings = readings
    }

    public var body: some View {
        Chart {
            ForEach(readings) { reading in
                AreaMark(x: .value("Heure", reading.date), y: .value(WattStrings.unit, reading.intensity))
                    .foregroundStyle(.linearGradient(colors: [.green.opacity(0.35), .green.opacity(0.02)],
                                                     startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Heure", reading.date), y: .value(WattStrings.unit, reading.intensity))
                    .foregroundStyle(.green)
                    .interpolationMethod(.monotone)
            }
            ForEach([CarbonLevel.lowUpperBound, CarbonLevel.moderateUpperBound], id: \.self) { bound in
                RuleMark(y: .value("Seuil", bound))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYScale(domain: 0...max(100, (readings.map(\.intensity).max() ?? 0) + 10))
        .accessibilityLabel(WattStrings.carbonIntensity)
    }
}

#Preview {
    IntensityChart(readings: GridSnapshot.sample().readings)
        .frame(height: 200)
        .padding()
}
