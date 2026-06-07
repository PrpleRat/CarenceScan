import SwiftUI

struct SymptomEvolutionView: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @EnvironmentObject private var vm: QuestionnaireViewModel

    @State private var selectedSymptomeId: String?
    private let lastDays = 14

    private var symptomeIds: [String] {
        let tracked = tracker.trackedSymptomeIds
        return tracked.isEmpty ? (ResultsStorage.load()?.symptomeSelections.map(\.symptomeId) ?? []) : tracked
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Visualisez la fréquence de vos symptômes sur les \(lastDays) derniers jours (check-ins quotidiens).")
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)

                if symptomeIds.isEmpty {
                    ContentUnavailableView(
                        "Pas encore de données",
                        systemImage: "chart.bar",
                        description: Text("Faites un bilan puis enregistrez vos symptômes chaque jour.")
                    )
                } else {
                    Picker("Symptôme", selection: Binding(
                        get: { selectedSymptomeId ?? symptomeIds[0] },
                        set: { selectedSymptomeId = $0 }
                    )) {
                        ForEach(symptomeIds, id: \.self) { id in
                            Text(CarenceDatabase.symptomeLabel(for: id)).tag(id)
                        }
                    }
                    .pickerStyle(.menu)

                    if let id = selectedSymptomeId ?? symptomeIds.first {
                        evolutionChart(symptomeId: id)
                        bilanHistorySection
                    }
                }
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Évolution")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedSymptomeId = symptomeIds.first
            tracker.reloadJournal()
        }
    }

    private func evolutionChart(symptomeId: String) -> some View {
        let entries = SymptomJournalStorage.entries(for: symptomeId, lastDays: lastDays)
        let entryByDay = Dictionary(uniqueKeysWithValues: entries.map {
            (Calendar.current.startOfDay(for: $0.date), $0.present)
        })
        let presentCount = entries.filter(\.present).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(CarenceDatabase.symptomeLabel(for: symptomeId))
                    .font(.headline)
                    .foregroundStyle(CarenceColors.textPrimary)
                Spacer()
                Text("\(presentCount)/\(lastDays) j")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CarenceColors.primary)
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(tracker.daysWithData(lastDays: lastDays), id: \.self) { day in
                    let present = entryByDay[day]
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor(present: present))
                            .frame(width: 14, height: present == nil ? 8 : (present == true ? 44 : 16))
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 9))
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(CarenceColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 16) {
                legendDot(color: CarenceColors.alert, label: "Oui")
                legendDot(color: CarenceColors.primary.opacity(0.35), label: "Non")
                legendDot(color: CarenceColors.border, label: "Non renseigné")
            }
            .font(.caption2)
        }
    }

    private var bilanHistorySection: some View {
        let history = SymptomJournalStorage.loadBilanHistory()
        return Group {
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Historique des bilans")
                        .font(.headline)
                        .foregroundStyle(CarenceColors.textPrimary)

                    ForEach(history.suffix(5).reversed(), id: \.date) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CarenceColors.textPrimary)
                            Text("\(entry.symptomeSelections.count) symptômes · \(entry.scores.count) carences détectées")
                                .font(.caption2)
                                .foregroundStyle(CarenceColors.textSecondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CarenceColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func barColor(present: Bool?) -> Color {
        guard let present else { return CarenceColors.border }
        return present ? CarenceColors.alert : CarenceColors.primary.opacity(0.35)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(CarenceColors.textSecondary)
        }
    }
}
