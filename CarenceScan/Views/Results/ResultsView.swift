import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @Environment(\.dismiss) private var dismiss
    var onRestart: () -> Void = {}

    private var payload: SavedResultsPayload? {
        vm.savedPayload
    }

    private var soinsLocaux: [SoinLocal] {
        CarenceDatabase.soinsLocaux(for: vm.symptomesSelectionnes)
    }

    private var bilans: [BilanSanguin] {
        guard let payload else { return [] }
        return CarenceDatabase.bilansSuggeres(scores: payload.scores, regles: vm.reglesDetectees)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if !vm.reglesDetectees.isEmpty {
                    alertesSection
                }

                if vm.medicamentsSelectionnes.contains("sertraline")
                    || vm.scores.contains(where: { $0.carenceId == "tryptophane" }) {
                    AlerteBanner(message: AppConstants.alerte5HTP, style: .alert)
                }

                if vm.scores.contains(where: { $0.carenceId == "fer" }) {
                    AlerteBanner(message: AppConstants.alerteFer, style: .alert)
                }

                if vm.scores.isEmpty {
                    emptyState
                } else {
                    carencesSection
                }

                if !soinsLocaux.isEmpty {
                    soinsSection
                }

                if !bilans.isEmpty {
                    bilansSection
                }

                if let payload {
                    ExportButton(payload: payload)
                }

                Button("Refaire le test") {
                    onRestart()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)
                .accessibilityLabel("Refaire le test")

                Text(AppConstants.disclaimerPrincipal)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Résultats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Votre bilan personnalisé")
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)

            if let date = payload?.date {
                Text(date, format: .dateTime.day().month().year().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
        }
    }

    private var alertesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Alertes détectées")
                .font(.headline)
                .foregroundStyle(CarenceColors.alert)

            ForEach(vm.reglesDetectees) { regle in
                AlerteBanner(message: regle.messageAlerte, style: .alert)
            }
        }
    }

    private var carencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carences probables")
                .font(.headline)

            ForEach(vm.scores) { score in
                if let carence = CarenceDatabase.carence(for: score.carenceId) {
                    CarenceCard(score: score, carence: carence)
                }
            }
        }
    }

    private var soinsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Soins locaux recommandés")
                .font(.headline)

            ForEach(soinsLocaux) { soin in
                VStack(alignment: .leading, spacing: 4) {
                    Text(soin.nom)
                        .font(.subheadline.weight(.semibold))
                    Text(soin.utilisation)
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                    Text(soin.prix)
                        .font(.caption2)
                        .foregroundStyle(CarenceColors.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CarenceColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var bilansSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bilan sanguin suggéré")
                .font(.headline)

            ForEach(bilans) { bilan in
                VStack(alignment: .leading, spacing: 6) {
                    Text(bilan.label)
                        .font(.subheadline.weight(.semibold))
                    Text(bilan.indication)
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                    Text(bilan.analyses.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(CarenceColors.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CarenceColors.warningBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(CarenceColors.textSecondary)
            Text("Aucune carence au-dessus du seuil avec ces symptômes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    NavigationStack {
        ResultsView()
            .environmentObject(QuestionnaireViewModel())
    }
}
