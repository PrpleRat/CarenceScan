import Foundation
import SwiftUI

@MainActor
final class QuestionnaireViewModel: ObservableObject {

    @Published var symptomesSelectionnes: Set<String> = []
    @Published var medicamentsSelectionnes: Set<String> = []
    @Published var aucunMedicament = false
    @Published var scores: [ScoreResult] = []
    @Published var reglesDetectees: [RegleCombination] = []
    @Published var savedPayload: SavedResultsPayload?

    let database = CarenceDatabase.shared

    var selectedSymptomCount: Int { symptomesSelectionnes.count }

    func restoreDraftIfNeeded() {
        guard let draft = ResultsStorage.loadDraft() else { return }
        symptomesSelectionnes = Set(draft.symptomes)
        medicamentsSelectionnes = Set(draft.medicaments)
        aucunMedicament = medicamentsSelectionnes.isEmpty
    }

    func toggleSymptome(_ id: String) {
        if symptomesSelectionnes.contains(id) {
            symptomesSelectionnes.remove(id)
        } else {
            symptomesSelectionnes.insert(id)
        }
        persistDraft()
    }

    func deselectAllSymptomes() {
        symptomesSelectionnes.removeAll()
        persistDraft()
    }

    func toggleMedicament(_ id: String) {
        aucunMedicament = false
        if medicamentsSelectionnes.contains(id) {
            medicamentsSelectionnes.remove(id)
        } else {
            medicamentsSelectionnes.insert(id)
        }
        persistDraft()
    }

    func selectAucunMedicament() {
        medicamentsSelectionnes.removeAll()
        aucunMedicament = true
        persistDraft()
    }

    func analyser() {
        reglesDetectees = ScoringEngine.detecterCombinaisonsSpeciales(
            symptomesSelectionnes: symptomesSelectionnes,
            regles: database.reglesCombinatoiresSpeciales
        )
        scores = ScoringEngine.calculerScores(
            symptomesSelectionnes: symptomesSelectionnes,
            medicamentsSelectionnes: medicamentsSelectionnes
        )
        let payload = SavedResultsPayload(
            date: Date(),
            symptomesSelectionnes: Array(symptomesSelectionnes),
            medicamentsSelectionnes: Array(medicamentsSelectionnes),
            scores: scores,
            reglesDetectees: reglesDetectees.map(\.id)
        )
        savedPayload = payload
        ResultsStorage.save(payload)
    }

    func loadSavedResults() {
        guard let payload = ResultsStorage.load() else { return }
        savedPayload = payload
        symptomesSelectionnes = Set(payload.symptomesSelectionnes)
        medicamentsSelectionnes = Set(payload.medicamentsSelectionnes)
        aucunMedicament = medicamentsSelectionnes.isEmpty
        scores = payload.scores
        reglesDetectees = database.reglesCombinatoiresSpeciales.filter {
            payload.reglesDetectees.contains($0.id)
        }
    }

    func resetQuestionnaire() {
        symptomesSelectionnes.removeAll()
        medicamentsSelectionnes.removeAll()
        aucunMedicament = false
        scores.removeAll()
        reglesDetectees.removeAll()
        savedPayload = nil
        ResultsStorage.clear()
        UserDefaults.standard.removeObject(forKey: AppConstants.questionnaireStorageKey)
    }

    func symptomes(for category: SymptomCategory) -> [Symptome] {
        CarenceDatabase.symptomes(for: category)
    }

    private func persistDraft() {
        ResultsStorage.saveDraft(symptomes: symptomesSelectionnes, medicaments: medicamentsSelectionnes)
    }
}
