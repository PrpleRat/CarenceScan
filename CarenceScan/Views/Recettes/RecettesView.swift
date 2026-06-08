import SwiftUI

struct RecettesView: View {
    let scores: [ScoreResult]

    @State private var filtreTemps: FiltreTemps = .tous
    @State private var filtreDifficulte: FiltreDifficulte = .tous

    private var recettes: [RecetteScoree] {
        RecettesEngine.suggererRecettes(depuis: scores)
    }

    private var recettesFiltrees: [RecetteScoree] {
        recettes.filter { item in
            let tempsOk = filtreTemps.accepte(item.recette.temps)
            let diffOk = filtreDifficulte.accepte(item.recette.difficulte)
            return tempsOk && diffOk
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sélectionnées pour couvrir vos carences")
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)

                filtresSection

                if recettesFiltrees.isEmpty {
                    ContentUnavailableView(
                        "Aucune recette",
                        systemImage: "fork.knife",
                        description: Text("Affinez vos résultats ou refaites le bilan avec plus de symptômes.")
                    )
                    .padding(.vertical, 24)
                } else {
                    ForEach(recettesFiltrees) { item in
                        NavigationLink {
                            RecetteDetailView(item: item, scores: scores)
                        } label: {
                            recetteCard(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Recettes pour vous")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filtresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Durée")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CarenceColors.textSecondary)
            Picker("Durée", selection: $filtreTemps) {
                ForEach(FiltreTemps.allCases, id: \.self) { f in
                    Text(f.label).tag(f)
                }
            }
            .pickerStyle(.segmented)

            Text("Difficulté")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CarenceColors.textSecondary)
            Picker("Difficulté", selection: $filtreDifficulte) {
                ForEach(FiltreDifficulte.allCases, id: \.self) { f in
                    Text(f.label).tag(f)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func recetteCard(_ item: RecetteScoree) -> some View {
        let r = item.recette
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(r.emoji)
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(r.titre)
                        .font(.headline)
                        .foregroundStyle(CarenceColors.textPrimary)
                    Text("⏱ \(r.temps)  •  👤 \(r.portions) portions  •  ⭐ \(r.difficulte)")
                        .font(.caption)
                        .foregroundStyle(CarenceColors.textSecondary)
                }
            }

            if !item.carencesMatchees.isEmpty {
                Text("Couvre vos carences en :")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CarenceColors.textSecondary)
                FlowLayout(spacing: 6) {
                    ForEach(item.carencesMatchees, id: \.self) { id in
                        Text(RecettesEngine.carenceNom(for: id))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(CarenceColors.primary.opacity(0.15))
                            .foregroundStyle(CarenceColors.primary)
                            .clipShape(Capsule())
                    }
                }
            }

            Text("Ingrédients clés : \(r.ingredientsCles.joined(separator: ", "))")
                .font(.caption2)
                .foregroundStyle(CarenceColors.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CarenceColors.border, lineWidth: 1)
        )
    }
}

private enum FiltreTemps: String, CaseIterable {
    case tous, court, moyen

    var label: String {
        switch self {
        case .tous: return "Tous"
        case .court: return "< 15 min"
        case .moyen: return "< 30 min"
        }
    }

    func accepte(_ temps: String) -> Bool {
        guard let minutes = Int(temps.filter(\.isNumber)) else { return self == .tous }
        switch self {
        case .tous: return true
        case .court: return minutes < 15
        case .moyen: return minutes < 30
        }
    }
}

private enum FiltreDifficulte: String, CaseIterable {
    case tous, facile, moyen

    var label: String {
        switch self {
        case .tous: return "Tous"
        case .facile: return "Facile"
        case .moyen: return "Moyen"
        }
    }

    func accepte(_ difficulte: String) -> Bool {
        switch self {
        case .tous: return true
        case .facile: return difficulte.lowercased() == "facile"
        case .moyen: return difficulte.lowercased() == "moyen"
        }
    }
}
