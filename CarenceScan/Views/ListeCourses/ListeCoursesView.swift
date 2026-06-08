import SwiftUI

struct ListeCoursesView: View {
    let scores: [ScoreResult]
    let symptomesDetectes: [String]

    @State private var section: ListeCategorie = .pharmacie
    @State private var checkedIds: Set<String> = ListeCoursesStorage.loadCheckedIds()
    @State private var shareText: ShareTextItem?

    private var liste: ListeCourses {
        ListeCoursesEngine.genererListe(
            depuis: scores,
            symptomesDetectes: symptomesDetectes
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $section) {
                Text("💊 Pharmacie").tag(ListeCategorie.pharmacie)
                Text("🛒 Supermarché").tag(ListeCategorie.supermarche)
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if section == .pharmacie {
                        pharmacieContent
                    } else {
                        supermarcheContent
                    }
                }
                .padding(20)
            }

            footerBudget
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle("Ma liste de courses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareText = ShareTextItem(text: ListeCoursesEngine.genererTextePartage(liste: liste))
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Partager la liste")
            }
        }
        .sheet(item: $shareText) { item in
            ShareSheet(items: [item.text])
        }
    }

    private var pharmacieContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compléments alimentaires recommandés")
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textSecondary)

            groupeItems(
                titre: "⚠️ À ne pas acheter seul",
                items: liste.pharmacie.filter { $0.nom.contains("⚠️") }
            )
            groupeItems(
                titre: "Semaine 1 — Priorité haute",
                items: liste.pharmacie.filter { $0.urgence == .urgent && !$0.nom.contains("⚠️") }
            )
            groupeItems(
                titre: "Semaine 2 — Compléter",
                items: liste.pharmacie.filter { $0.urgence == .important }
            )
            groupeItems(
                titre: "Soins locaux & compléments",
                items: liste.pharmacie.filter { $0.urgence == .complementaire }
            )
        }
    }

    private var supermarcheContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aliments à intégrer dans votre alimentation")
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textSecondary)

            ForEach(grouperSupermarche(liste.supermarche), id: \.categorie) { groupe in
                groupeItems(titre: groupe.categorie, items: groupe.items)
            }
        }
    }

    private func groupeItems(titre: String, items: [ListeItem]) -> some View {
        Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(titre)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CarenceColors.textSecondary)
                    ForEach(items) { item in
                        listeItemRow(item)
                    }
                }
            }
        }
    }

    private func listeItemRow(_ item: ListeItem) -> some View {
        Button {
            toggleChecked(item.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: checkedIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checkedIds.contains(item.id) ? CarenceColors.primary : CarenceColors.textSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.nom)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarenceColors.textPrimary)
                        .strikethrough(checkedIds.contains(item.id))
                    if let detail = item.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                    if let prix = item.prix {
                        Text(prix)
                            .font(.caption2)
                            .foregroundStyle(CarenceColors.primary)
                    }
                    if !item.carencesLiees.isEmpty {
                        Text("Pour : \(item.carencesLiees.map { RecettesEngine.carenceNom(for: $0) }.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(CarenceColors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(CarenceColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(CarenceColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var footerBudget: some View {
        VStack(spacing: 0) {
            Divider()
            Text("Budget estimé pharmacie : \(ListeCoursesEngine.budgetPharmacieEstime(liste: liste))")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(CarenceColors.surface)
        }
    }

    private func toggleChecked(_ id: String) {
        if checkedIds.contains(id) {
            checkedIds.remove(id)
        } else {
            checkedIds.insert(id)
        }
        ListeCoursesStorage.saveCheckedIds(checkedIds)
    }

    private func grouperSupermarche(_ items: [ListeItem]) -> [(categorie: String, items: [ListeItem])] {
        let ordre = [
            "Poissons & fruits de mer", "Viandes & œufs", "Légumes verts", "Fruits",
            "Légumineuses", "Oléagineux & graines", "Autres"
        ]
        var dict: [String: [ListeItem]] = [:]
        for item in items {
            let cat = categorieCulinaire(item.nom)
            dict[cat, default: []].append(item)
        }
        return ordre.compactMap { cat in
            guard let group = dict[cat], !group.isEmpty else { return nil }
            return (cat, group)
        }
    }

    private func categorieCulinaire(_ nom: String) -> String {
        let l = nom.lowercased()
        if l.contains("saumon") || l.contains("sardine") || l.contains("thon") || l.contains("maquereau") || l.contains("poisson") || l.contains("huître") {
            return "Poissons & fruits de mer"
        }
        if l.contains("viande") || l.contains("poulet") || l.contains("porc") || l.contains("oeuf") || l.contains("foie") || l.contains("boudin") {
            return "Viandes & œufs"
        }
        if l.contains("épinard") || l.contains("epinard") || l.contains("brocoli") || l.contains("poivron") || l.contains("champignon") || l.contains("carotte") {
            return "Légumes verts"
        }
        if l.contains("kiwi") || l.contains("orange") || l.contains("fraise") || l.contains("banane") || l.contains("citron") {
            return "Fruits"
        }
        if l.contains("lentille") || l.contains("pois chiche") || l.contains("légumineuse") {
            return "Légumineuses"
        }
        if l.contains("noix") || l.contains("amande") || l.contains("graine") || l.contains("chocolat") {
            return "Oléagineux & graines"
        }
        return "Autres"
    }
}

struct ShareTextItem: Identifiable {
    let id = UUID()
    let text: String
}
