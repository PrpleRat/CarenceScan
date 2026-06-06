import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @State private var showQuestionnaire = false
    @State private var showResults = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                BrandHeader()

                VStack(spacing: 12) {
                    Text("Identifiez vos carences en 2 minutes")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(CarenceColors.textPrimary)

                    Text("Basé sur vos symptômes. Gratuit. Confidentiel.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(CarenceColors.textSecondary)
                }

                Button {
                    vm.restoreDraftIfNeeded()
                    showQuestionnaire = true
                } label: {
                    Text("Commencer le questionnaire")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(CarenceColors.primary)
                .accessibilityLabel("Commencer le questionnaire")

                if ResultsStorage.hasSavedResults {
                    Button("Voir mes derniers résultats") {
                        vm.loadSavedResults()
                        showResults = true
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CarenceColors.primary)
                    .accessibilityLabel("Voir mes derniers résultats")
                }

                Text(AppConstants.disclaimerPrincipal)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationDestination(isPresented: $showQuestionnaire) {
            QuestionnaireView(onContinue: { showResults = false })
        }
        .navigationDestination(isPresented: $showResults) {
            ResultsView(onRestart: {
                vm.resetQuestionnaire()
                showResults = false
                showQuestionnaire = true
            })
        }
    }
}

struct BrandHeader: View {
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: compact ? 28 : 56))
                .foregroundStyle(CarenceColors.primary)
                .accessibilityHidden(true)

            Text(AppConstants.appName)
                .font(compact ? .headline.bold() : .largeTitle.bold())
                .foregroundStyle(CarenceColors.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(AppConstants.appName), application de bilan carences")
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(QuestionnaireViewModel())
    }
}
