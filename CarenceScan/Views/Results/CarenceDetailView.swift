import SwiftUI

struct CarenceDetailView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    let carenceId: String

    private var carence: Carence? {
        CarenceDatabase.carence(for: carenceId)
    }

    private var score: ScoreResult? {
        vm.scores.first(where: { $0.carenceId == carenceId })
            ?? ResultsStorage.load()?.scores.first(where: { $0.carenceId == carenceId })
    }

    private var hasMedicationInteraction: Bool {
        guard let carence, let interactions = carence.interactionsMedicaments else { return false }
        let meds = vm.medicamentsSelectionnes.isEmpty
            ? Set(ResultsStorage.load()?.medicamentsSelectionnes ?? [])
            : vm.medicamentsSelectionnes
        return meds.contains { med in
            interactions.contains { $0.contains(med) || med.contains("sertraline") && $0.contains("ISRS") }
        } || (carenceId == "tryptophane" && meds.contains("sertraline"))
    }

    var body: some View {
        Group {
            if let carence {
                detailContent(carence: carence, score: score)
            } else {
                ContentUnavailableView(
                    "Carence introuvable",
                    systemImage: "questionmark.circle",
                    description: Text("Ce résultat n'est plus disponible.")
                )
            }
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle(carence?.nom ?? "Détail")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailContent(carence: Carence, score: ScoreResult?) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(carence.description)
                    .font(.body)
                    .foregroundStyle(CarenceColors.textSecondary)

                urgenceBadge(carence: carence)

                if let score {
                    ProbabilityBar(level: score.niveau, score: score.score)
                }

                sectionTitle("Quand s'inquiéter ?")
                Text(carence.quandSinquieterText)
                    .font(.subheadline)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CarenceColors.warningBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                sectionTitle("Signes d'alerte")
                ForEach(carence.signesAlerteItems, id: \.self) { signe in
                    Label(signe, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.alert)
                }

                symptomTiersSection(carence: carence, highlighted: Set(score?.symptomesDetectes ?? []))

                if let score, !score.symptomesDetectes.isEmpty {
                    sectionTitle("Vos symptômes déclencheurs")
                    ForEach(score.symptomesDetectes, id: \.self) { id in
                        NavigationLink {
                            SymptomeFicheView(symptomeId: id)
                        } label: {
                            Label(CarenceDatabase.symptomeLabel(for: id), systemImage: "checkmark.seal.fill")
                                .font(.subheadline)
                                .foregroundStyle(CarenceColors.primary)
                        }
                    }
                }

                if let score, !score.notesContexte.isEmpty {
                    sectionTitle("Notes contexte")
                    ForEach(score.notesContexte.groupedByContexte) { groupe in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(groupe.emoji) \(groupe.label)")
                                .font(.caption.bold())
                                .foregroundStyle(CarenceColors.textPrimary)
                            ForEach(groupe.notesConfusion + groupe.notesAggravation, id: \.id) { note in
                                ContexteNoteView(
                                    icon: note.type == .confusion ? "⚠️" : "↗️",
                                    note: note,
                                    background: CarenceColors.surface
                                )
                            }
                        }
                    }
                }

                sectionTitle("Aliments clés")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                    ForEach(carence.alimentsCles, id: \.self) { aliment in
                        Text(foodEmoji(for: aliment) + " " + aliment)
                            .font(.caption)
                            .foregroundStyle(CarenceColors.textPrimary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(CarenceColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                sectionTitle("Complément recommandé")
                complementBlock(carence.complement)

                AlerteBanner(message: carence.complement.precautions, style: .warning)

                if hasMedicationInteraction {
                    AlerteBanner(message: AppConstants.alerte5HTP, style: .alert)
                }

                if carence.prescriptionObligatoire == true {
                    AlerteBanner(message: AppConstants.alerteFer, style: .alert)
                }

                if let score {
                    ForEach(score.alertes, id: \.self) { alerte in
                        AlerteBanner(message: alerte, style: .warning)
                    }
                }
            }
            .padding(20)
        }
    }

    private func urgenceBadge(carence: Carence) -> some View {
        Text(carence.urgenceLabel)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(carence.urgenceColor.opacity(0.15))
            .foregroundStyle(carence.urgenceColor)
            .clipShape(Capsule())
    }

    private func symptomTiersSection(carence: Carence, highlighted: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Symptômes par importance")
            tierGroup(title: "Caractéristiques", ids: carence.symptomesPrimaires, highlighted: highlighted)
            tierGroup(title: "Fréquents", ids: carence.symptomesSecondaires, highlighted: highlighted)
            tierGroup(title: "Contextuels", ids: carence.symptomesContextuels, highlighted: highlighted)
        }
    }

    private func tierGroup(title: String, ids: [String], highlighted: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CarenceColors.textSecondary)
            ForEach(ids, id: \.self) { id in
                NavigationLink {
                    SymptomeFicheView(symptomeId: id)
                } label: {
                    HStack {
                        Text(CarenceDatabase.symptomeLabel(for: id))
                            .font(.caption)
                            .foregroundStyle(highlighted.contains(id) ? CarenceColors.primary : CarenceColors.textPrimary)
                        Spacer()
                        if highlighted.contains(id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(CarenceColors.primary)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(CarenceColors.textPrimary)
            .padding(.top, 4)
    }

    private func complementBlock(_ c: ComplementInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            row("Nom", c.nom)
            row("Posologie", c.posologie)
            row("Forme", c.formeRecommandee)
            row("Prix / mois", c.prixMois)
            row("Où acheter", c.ouAcheter)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CarenceColors.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textPrimary)
        }
    }

    private func foodEmoji(for aliment: String) -> String {
        let lower = aliment.lowercased()
        if lower.contains("kiwi") || lower.contains("orange") || lower.contains("citron") { return "🍊" }
        if lower.contains("poivron") || lower.contains("brocoli") || lower.contains("épinard") { return "🥦" }
        if lower.contains("viande") || lower.contains("porc") || lower.contains("poulet") { return "🥩" }
        if lower.contains("poisson") || lower.contains("saumon") || lower.contains("sardine") { return "🐟" }
        if lower.contains("oeuf") { return "🥚" }
        if lower.contains("noix") || lower.contains("amande") || lower.contains("graine") { return "🌰" }
        if lower.contains("banane") { return "🍌" }
        if lower.contains("chocolat") { return "🍫" }
        if lower.contains("lentille") || lower.contains("légumineuse") { return "🫘" }
        return "🥗"
    }
}

#Preview {
    NavigationStack {
        CarenceDetailView(carenceId: "vitamine_c")
            .environmentObject(QuestionnaireViewModel())
    }
}
