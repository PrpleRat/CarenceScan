import SwiftUI

struct RecetteDetailView: View {
    let item: RecetteScoree
    let scores: [ScoreResult]

    @State private var ajouteConfirmation = false

    private var liste: ListeCourses {
        ListeCoursesEngine.genererListe(
            depuis: scores,
            symptomesDetectes: scores.flatMap(\.symptomesDetectes)
        )
    }

    private var ingredientsDansListe: Set<String> {
        Set(liste.supermarche.map { AlimentNormalizer.normaliser($0.nom) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                carencesSection
                ingredientsSection
                etapesSection
                conseilSection

                Button {
                    ajouterAListe()
                } label: {
                    Label("Ajouter les ingrédients à ma liste", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CarenceColors.primary)
            }
            .padding(20)
        }
        .background(CarenceColors.background.ignoresSafeArea())
        .navigationTitle(item.recette.titre)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ajouté à la liste", isPresented: $ajouteConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Les ingrédients manquants ont été ajoutés à votre liste supermarché.")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(item.recette.emoji)
                .font(.system(size: 56))
            Text(item.recette.titre)
                .font(.title2.bold())
                .foregroundStyle(CarenceColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("⏱ \(item.recette.temps)  •  👤 \(item.recette.portions) portions  •  ⭐ \(item.recette.difficulte)")
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var carencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Couvre vos carences")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)
            Text("Cette recette couvre \(item.carencesMatchees.count) de vos carences identifiées.")
                .font(.caption)
                .foregroundStyle(CarenceColors.textSecondary)
            FlowLayout(spacing: 6) {
                ForEach(item.carencesMatchees, id: \.self) { id in
                    Text(RecettesEngine.carenceNom(for: id))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(CarenceColors.primary.opacity(0.15))
                        .foregroundStyle(CarenceColors.primary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingrédients")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)
            ForEach(item.recette.ingredientsComplets, id: \.self) { ingredient in
                let dansListe = ingredientDansListe(ingredient)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: dansListe ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(dansListe ? CarenceColors.primary : CarenceColors.textSecondary)
                        .font(.caption)
                    Text(ingredient)
                        .font(.subheadline)
                        .foregroundStyle(dansListe ? CarenceColors.primary : CarenceColors.textPrimary)
                }
            }
        }
        .padding(14)
        .background(CarenceColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var etapesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Préparation")
                .font(.headline)
                .foregroundStyle(CarenceColors.textPrimary)
            ForEach(Array(item.recette.etapes.enumerated()), id: \.offset) { index, etape in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(CarenceColors.primary)
                        .clipShape(Circle())
                    Text(etape)
                        .font(.subheadline)
                        .foregroundStyle(CarenceColors.textPrimary)
                }
            }
        }
    }

    private var conseilSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("💡")
            Text(item.recette.conseilNutrition)
                .font(.subheadline)
                .foregroundStyle(CarenceColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarenceColors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func ingredientDansListe(_ ingredient: String) -> Bool {
        let cle = AlimentNormalizer.normaliser(ingredient)
        if ingredientsDansListe.contains(cle) { return true }
        return item.ingredientsMatches.contains { cle.contains($0) || $0.contains(cle) }
    }

    private func ajouterAListe() {
        let manquants = item.recette.ingredientsComplets.filter { !ingredientDansListe($0) }
        ListeCoursesStorage.ajouterIngredientsRecette(manquants, carencesLiees: item.carencesMatchees)
        ajouteConfirmation = true
    }
}
