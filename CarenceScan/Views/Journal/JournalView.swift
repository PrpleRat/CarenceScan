import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @EnvironmentObject private var journal: JournalEngine

    @State private var expandedCategories = Set(CategorieAliment.allCases.map(\.rawValue))
    @State private var showSemaine = false

    private var aliments: [AlimentTrackable] { NutritionDataLoader.alimentsTrackables }

    private var carencesUtilisateur: [String] {
        let scores = vm.scores.isEmpty ? (ResultsStorage.load()?.scores ?? []) : vm.scores
        return NutritionDataLoader.carencesActivesIds(from: scores)
    }

    private var analyse: JourAnalyse {
        journal.calculerCarencesCouvertes(
            date: Date(),
            aliments: aliments,
            carencesUtilisateur: carencesUtilisateur
        )
    }

    var body: some View {
        Group {
            if carencesUtilisateur.isEmpty {
                journalVide
            } else {
                journalContent
            }
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Mon journal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.loadSavedResults() }
        .navigationDestination(isPresented: $showSemaine) {
            SemaineView(
                aliments: aliments,
                carencesUtilisateur: carencesUtilisateur
            )
            .environmentObject(journal)
        }
    }

    private var journalContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Aliments mangés aujourd'hui")
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)

                scoreSection

                if let suggestion = analyse.suggestionDuJour {
                    suggestionCard(suggestion)
                }

                ForEach(CategorieAliment.allCases) { categorie in
                    categorySection(categorie)
                }

                Button {
                    showSemaine = true
                } label: {
                    Label("Voir la semaine", systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CarenceColors.primary)

                Text("Ce journal est indicatif. Il ne mesure pas les quantités exactes ni la biodisponibilité réelle des nutriments.")
                    .font(.caption2)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(20)
        }
    }

    private var scoreSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(CarenceColors.border, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(analyse.scoreJournee) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(analyse.scoreJournee)%")
                    .font(.title.bold())
                    .foregroundStyle(scoreColor)
            }
            .frame(width: 120, height: 120)

            Text("Vous avez couvert \(analyse.carencesCouvertes.count)/\(carencesUtilisateur.count) de vos carences aujourd'hui")
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textPrimary)

            ProgressView(value: Double(analyse.scoreJournee), total: 100)
                .tint(scoreColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scoreColor: Color {
        if analyse.scoreJournee > 70 { return CarenceColors.primary }
        if analyse.scoreJournee >= 40 { return .orange }
        return CarenceColors.alert
    }

    private func suggestionCard(_ aliment: AlimentTrackable) -> some View {
        let carences = aliment.carencesCouvertes
            .filter { analyse.carencesNonCouvertes.contains($0) }
            .compactMap { CarenceDatabase.carence(for: $0)?.label }

        return VStack(alignment: .leading, spacing: 8) {
            Text("💡 Mangez \(aliment.emoji) \(aliment.nom) aujourd'hui")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CarenceColors.primary)
            if !carences.isEmpty {
                Text("→ Couvrirait encore : \(carences.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(CarenceColors.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func categorySection(_ categorie: CategorieAliment) -> some View {
        let items = aliments.filter { $0.categorie == categorie }
        if !items.isEmpty {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedCategories.contains(categorie.rawValue) },
                set: { expanded in
                    if expanded {
                        expandedCategories.insert(categorie.rawValue)
                    } else {
                        expandedCategories.remove(categorie.rawValue)
                    }
                }
            )
        ) {
            LazyVStack(spacing: 8) {
                ForEach(items) { aliment in
                    alimentRow(aliment)
                }
            }
            .padding(.top, 8)
        } label: {
            Text(categorie.label)
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)
        }
        }
    }

    private func alimentRow(_ aliment: AlimentTrackable) -> some View {
        let consomme = journal.estConsomme(aliment.id)
        let carencesLabels = aliment.carencesCouvertes
            .filter { carencesUtilisateur.contains($0) }
            .compactMap { CarenceDatabase.carence(for: $0)?.label }

        return Button {
            journal.toggleAliment(aliment.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: consomme ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(consomme ? CarenceColors.primary : CarenceColors.textSecondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(aliment.emoji) \(aliment.nom)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CarenceColors.textPrimary)
                        Spacer()
                        Text(aliment.portionType)
                            .font(.caption2)
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                    if !carencesLabels.isEmpty {
                        Text("Couvre : \(carencesLabels.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(CarenceColors.primary)
                    }
                }
            }
            .padding(12)
            .background(CarenceColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var journalVide: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(CarenceColors.textSecondary)
            Text("Journal alimentaire")
                .font(.title2.bold())
            Text("Complétez d'abord votre bilan pour suivre quels aliments couvrent vos carences au quotidien.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(CarenceColors.textSecondary)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
