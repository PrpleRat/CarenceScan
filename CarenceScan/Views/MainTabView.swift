import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tracker: SymptomTrackerViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Accueil", systemImage: "house.fill")
            }
            .tag(AppTab.accueil)

            NavigationStack {
                BilanTabRootView()
            }
            .tabItem {
                Label("Bilan", systemImage: "doc.text.fill")
            }
            .tag(AppTab.bilan)

            NavigationStack {
                SuiviDashboardView()
            }
            .tabItem {
                Label("Suivi", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(AppTab.suivi)

            NavigationStack {
                CoursesTabRootView()
            }
            .tabItem {
                Label("Courses", systemImage: "cart.fill")
            }
            .tag(AppTab.courses)
        }
        .tint(CarenceColors.primary)
        .preferredColorScheme(.light)
        .onChange(of: tracker.openDailyCheckIn) { _, open in
            if open {
                tabRouter.selectedTab = .suivi
            }
        }
        .task {
            await SmartNotificationService.evaluateAndSchedule(tracker: tracker)
        }
    }
}

struct BilanTabRootView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var tabRouter: AppTabRouter
    @State private var showFullResults = false
    @State private var showProfil = false

    var body: some View {
        Group {
            if ResultsStorage.hasSavedResults {
                BilanSummaryView(onVoirDetail: { showFullResults = true })
                    .onAppear {
                        vm.loadSavedResults()
                        if tabRouter.highlightSummaryOnBilan {
                            tabRouter.highlightSummaryOnBilan = false
                        }
                    }
            } else {
                bilanVide
            }
        }
        .navigationDestination(isPresented: $showFullResults) {
            ResultsView(onRestart: {
                vm.resetQuestionnaire()
                showFullResults = false
                showProfil = true
            })
        }
        .navigationDestination(isPresented: $showProfil) {
            ProfilView()
        }
    }

    private var bilanVide: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(CarenceColors.textSecondary)
            Text("Pas encore de bilan")
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)
            Text("Répondez au questionnaire pour obtenir votre résumé personnalisé et le parcours « Et maintenant ? ».")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
                .padding(.horizontal, 32)
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
            .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Bilan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CoursesTabRootView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel

    private var scores: [ScoreResult] {
        vm.scores.isEmpty ? (ResultsStorage.load()?.scores ?? []) : vm.scores
    }

    private var symptomes: [String] {
        vm.symptomesSelectionnes.isEmpty
            ? (ResultsStorage.load()?.symptomeSelections.map(\.symptomeId) ?? [])
            : Array(vm.symptomesSelectionnes)
    }

    var body: some View {
        Group {
            if ResultsStorage.hasSavedResults, !scores.isEmpty {
                ListeCoursesView(scores: scores, symptomesDetectes: symptomes, showHomeButton: false)
            } else {
                coursesVide
            }
        }
        .onAppear { vm.loadSavedResults() }
    }

    private var coursesVide: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "cart")
                .font(.system(size: 48))
                .foregroundStyle(CarenceColors.textSecondary)
            Text("Liste de courses")
                .font(.title2.bold())
            Text("Complétez d'abord votre bilan pour générer une liste adaptée à vos carences.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Courses")
        .navigationBarTitleDisplayMode(.inline)
    }
}
