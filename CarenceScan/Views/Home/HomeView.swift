import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @State private var showProfil = false
    @State private var showResults = false
    @State private var showDailyCheckIn = false
    @State private var showEvolution = false
    @State private var showEncyclopedie = false

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
                    showProfil = true
                } label: {
                    Text("Commencer le questionnaire")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(CarenceColors.primary)
                .accessibilityLabel("Commencer le questionnaire")

                if ResultsStorage.hasSavedResults || !tracker.trackedSymptomeIds.isEmpty {
                    suiviSection
                }

                if ResultsStorage.hasSavedResults {
                    Button("Voir mes derniers résultats") {
                        vm.loadSavedResults()
                        showResults = true
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CarenceColors.primary)
                    .accessibilityLabel("Voir mes derniers résultats")
                }

                NavigationLink {
                    SymptomesEncyclopedieView()
                } label: {
                    Label("Encyclopédie des symptômes", systemImage: "book.pages")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)

                Text(AppConstants.disclaimerPrincipal)
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationDestination(isPresented: $showProfil) {
            ProfilView()
        }
        .navigationDestination(isPresented: $showResults) {
            ResultsView(onRestart: {
                vm.resetQuestionnaire()
                showResults = false
                showProfil = true
            })
        }
        .navigationDestination(isPresented: $showDailyCheckIn) {
            DailyCheckInView()
        }
        .navigationDestination(isPresented: $showEvolution) {
            SymptomEvolutionView()
        }
        .onChange(of: tracker.openDailyCheckIn) { _, open in
            if open {
                showDailyCheckIn = true
                tracker.openDailyCheckIn = false
            }
        }
        .onAppear {
            if tracker.openDailyCheckIn {
                showDailyCheckIn = true
                tracker.openDailyCheckIn = false
            }
        }
    }

    private var suiviSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suivi dans le temps")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)

            Button {
                showDailyCheckIn = true
            } label: {
                Label("Check-in du jour", systemImage: "calendar.badge.checkmark")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)

            Button {
                showEvolution = true
            } label: {
                Label("Voir l'évolution", systemImage: "chart.bar.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)

            NavigationLink {
                TrackingSettingsView()
            } label: {
                Label("Rappels quotidiens", systemImage: "bell.badge")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(CarenceColors.primary)
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
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
            .environmentObject(SymptomTrackerViewModel.shared)
    }
}
