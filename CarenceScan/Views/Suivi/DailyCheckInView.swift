import SwiftUI

struct DailyCheckInView: View {
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var answers: [String: Bool] = [:]

    private var symptomeIds: [String] {
        tracker.trackedSymptomeIds
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Check-in du jour")
                        .font(.title2.bold())
                        .foregroundStyle(CarenceColors.textPrimary)
                    Text("Avez-vous eu ces symptômes aujourd'hui ? Vos réponses alimentent le suivi dans le temps.")
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textSecondary)
                }

                if symptomeIds.isEmpty {
                    ContentUnavailableView(
                        "Aucun symptôme à suivre",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Faites d'abord un bilan complet pour sélectionner les symptômes à suivre.")
                    )
                } else {
                    ForEach(symptomeIds, id: \.self) { id in
                        checkInRow(symptomeId: id)
                    }

                    Button {
                        saveAll()
                        dismiss()
                    } label: {
                        Text("Enregistrer")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CarenceColors.primary)
                    .disabled(answers.count < symptomeIds.count)
                }
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Aujourd'hui")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            for id in symptomeIds {
                if let value = tracker.isPresentToday(symptomeId: id) {
                    answers[id] = value
                }
            }
        }
    }

    private func checkInRow(symptomeId: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(CarenceDatabase.symptomeLabel(for: symptomeId))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CarenceColors.textPrimary)

            HStack(spacing: 10) {
                toggleButton(title: "Oui", selected: answers[symptomeId] == true) {
                    answers[symptomeId] = true
                }
                toggleButton(title: "Non", selected: answers[symptomeId] == false) {
                    answers[symptomeId] = false
                }
                Spacer()
                NavigationLink {
                    SymptomeFicheView(symptomeId: symptomeId)
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(CarenceColors.primary)
                }
                .accessibilityLabel("Fiche symptôme")
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }

    private func toggleButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(selected ? CarenceColors.primary : CarenceColors.border.opacity(0.35))
                .foregroundStyle(selected ? Color.white : CarenceColors.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func saveAll() {
        for (id, present) in answers {
            tracker.record(symptomeId: id, present: present)
        }
    }
}
