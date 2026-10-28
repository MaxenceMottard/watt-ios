import SwiftUI
import WattCore
import WattUI

struct DashboardView: View {
    @State private var model = DashboardModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let snapshot = model.snapshot, let latest = snapshot.latest {
                        if model.lastError != nil || snapshot.isStale() {
                            OfflineBanner(fetchedAt: snapshot.fetchedAt)
                        }
                        CurrentIntensityCard(reading: latest)
                        MixCard(mix: latest.mix)
                        Card(title: "Dernières 24 heures") {
                            IntensityChart(readings: snapshot.readings(within: 24 * 3600))
                                .frame(height: 180)
                        }
                    } else if model.isLoading {
                        ProgressView().padding(.top, 80)
                    } else {
                        ContentUnavailableView {
                            Label("Données indisponibles", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text("Impossible de joindre RTE éCO2mix. Vérifiez votre connexion.")
                        } actions: {
                            Button("Réessayer") { Task { await model.refresh() } }
                                .buttonStyle(.borderedProminent)
                        }
                    }

                    Text(WattStrings.dataSource)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Watt")
            .refreshable { await model.refresh() }
        }
        .task(id: scenePhase) {
            if scenePhase == .active { await model.refresh() }
        }
    }
}

private struct Card<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

private struct CurrentIntensityCard: View {
    let reading: CarbonReading

    var body: some View {
        Card(title: "Intensité carbone") {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(reading.intensity, format: .number)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(WattStrings.unit)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            HStack {
                CarbonLevelBadge(level: reading.level)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Mesure de \(reading.date.formatted(date: .omitted, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MixCard: View {
    let mix: ProductionMix

    var body: some View {
        Card(title: "Mix de production") {
            MixBar(mix: mix)
            ForEach(ProductionMix.Source.allCases.filter { mix[$0] > 0 }, id: \.self) { source in
                HStack {
                    Circle().fill(source.color).frame(width: 10, height: 10)
                    Text(source.title)
                    Spacer()
                    Text(Measurement(value: Double(mix[source]), unit: UnitPower.megawatts),
                         format: .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
                        .foregroundStyle(.secondary)
                    Text(mix.share(of: source), format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .frame(minWidth: 44, alignment: .trailing)
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct OfflineBanner: View {
    let fetchedAt: Date

    var body: some View {
        Label {
            Text("Données hors ligne, mises à jour \(fetchedAt, style: .relative)")
        } icon: {
            Image(systemName: "wifi.slash")
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.yellow.opacity(0.2), in: .rect(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
}
