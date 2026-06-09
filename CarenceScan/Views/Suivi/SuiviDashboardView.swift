import SwiftUI

struct SuiviDashboardView: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @State private var showEvolution = false

    private var ids: [String] { tracker.trackedSymptomeIds }
    private var todayDone: Int {
        ids.filter { tracker.isPresentToday(symptomeId: $0) != nil }.count
    }
    private var streak: Int {
        guard !ids.isEmpty else { return 0 }
        var count = 0
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        while true {
            let hasEntry = ids.contains { id in
                tracker.journalEntries.contains {
                    $0.symptomeId == id && cal.isDate($0.date, inSameDayAs: day)
                }
            }
            guard hasEntry else { break }
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statsGrid
                checkInCard
                evolutionCard
                symptomesCard
                settingsCard
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Suivi")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showEvolution) {
            SymptomEvolutionView()
        }
        .onAppear {
            tracker.reloadJournal()
            Task { await SmartNotificationService.evaluateAndSchedule(tracker: tracker) }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statTile(
                valeur: "\(todayDone)/\(max(ids.count, 1))",
                label: "Check-in aujourd'hui",
                icon: "calendar.badge.checkmark",
                color: CarenceColors.primary
            )
            statTile(
                valeur: "\(streak)",
                label: "Jours consécutifs",
                icon: "flame.fill",
                color: CarenceColors.warning
            )
            statTile(
                valeur: "\(ids.count)",
                label: "Symptômes suivis",
                icon: "heart.text.square",
                color: CarenceColors.textSecondary
            )
        }
    }

    private func statTile(valeur: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(valeur)
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)
            Text(label)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }

    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Check-in du jour")
                .font(.headline)
            Text("30 secondes pour noter vos symptômes et suivre l'évolution.")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
            Button {
                tabRouter.openCheckIn()
            } label: {
                Label("Commencer le check-in", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(CarenceColors.primary)
            .disabled(ids.isEmpty)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var evolutionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Évolution")
                .font(.headline)
            Button {
                showEvolution = true
            } label: {
                Label("Voir tous mes symptômes", systemImage: "chart.bar.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)
            .disabled(ids.isEmpty)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var symptomesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Symptômes actifs (7 jours)")
                .font(.headline)

            if ids.isEmpty {
                Text("Complétez un bilan pour activer le suivi automatique.")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
                Button("Aller au bilan") { tabRouter.selectedTab = .bilan }
                    .font(.caption.weight(.semibold))
            } else {
                ForEach(ids.prefix(6), id: \.self) { id in
                    let days = tracker.presentDaysCount(symptomeId: id, lastDays: 7)
                    HStack {
                        Text(CarenceDatabase.symptomeLabel(for: id))
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text("\(days)/7 j")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(days >= 4 ? CarenceColors.alert : CarenceColors.primary)
                    }
                }
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var settingsCard: some View {
        NavigationLink {
            TrackingSettingsView()
        } label: {
            Label("Rappels et notifications", systemImage: "bell.badge")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .tint(CarenceColors.primary)
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
