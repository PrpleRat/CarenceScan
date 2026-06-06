import Foundation

enum ScoringEngine {

    private static let medicamentBonus = 20

    static func calculerScores(
        symptomesSelectionnes: Set<String>,
        medicamentsSelectionnes: Set<String>,
        database: CarenceDatabaseFile = CarenceDatabase.shared
    ) -> [ScoreResult] {
        let reglesActives = detecterCombinaisonsSpeciales(
            symptomesSelectionnes: symptomesSelectionnes,
            regles: database.reglesCombinatoiresSpeciales
        )

        var bonusSpeciauxParCarence: [String: Int] = [:]
        for regle in reglesActives {
            for carenceId in regle.carencesAmplifiees {
                bonusSpeciauxParCarence[carenceId, default: 0] += regle.bonusScore
            }
        }

        var resultats: [ScoreResult] = []

        for carence in database.carences {
            var score = 0
            var bonusCombinations = 0
            var symptomesDetectes: [String] = []
            var alertes: [String] = []

            for symptomeId in symptomesSelectionnes {
                if let scoreSymptome = carence.scoreParSymptome[symptomeId] {
                    score += scoreSymptome
                    symptomesDetectes.append(symptomeId)
                }
            }

            for combo in carence.combinaisonsAmplificatrices {
                let tousPresents = combo.symptomes.allSatisfy { symptomesSelectionnes.contains($0) }
                if tousPresents {
                    bonusCombinations += combo.bonus
                    score += combo.bonus
                }
            }

            if let bonusSpecial = bonusSpeciauxParCarence[carence.id] {
                bonusCombinations += bonusSpecial
                score += bonusSpecial
            }

            for medicamentId in medicamentsSelectionnes {
                guard let medicament = database.medicamentsDepleteurs.first(where: { $0.id == medicamentId }),
                      medicament.carencesInduites.contains(carence.id)
                else { continue }
                score += medicamentBonus
                alertes.append("Induit par \(medicament.label)")
            }

            let niveau = niveauPour(score: score, carence: carence)
            guard niveau != nil else { continue }

            resultats.append(
                ScoreResult(
                    carenceId: carence.id,
                    score: score,
                    niveau: niveau!,
                    symptomesDetectes: symptomesDetectes,
                    alertes: alertes,
                    bonusCombinations: bonusCombinations
                )
            )
        }

        return resultats.sorted { $0.score > $1.score }
    }

    static func detecterCombinaisonsSpeciales(
        symptomesSelectionnes: Set<String>,
        regles: [RegleCombination]
    ) -> [RegleCombination] {
        regles.filter { regle in
            regle.symptomesRequis.allSatisfy { symptomesSelectionnes.contains($0) }
        }
    }

    private static func niveauPour(score: Int, carence: Carence) -> ProbabilityLevel? {
        if score >= carence.seuilQuasiCertain { return .quasiCertaine }
        if score >= carence.seuilTresProbable { return .tresProbable }
        if score >= carence.seuilProbable { return .probable }
        return nil
    }
}
