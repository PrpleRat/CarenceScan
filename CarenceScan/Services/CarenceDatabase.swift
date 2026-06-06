import Foundation

enum CarenceDatabase {

    static let shared: CarenceDatabaseFile = {
        guard let url = Bundle.main.url(forResource: "carences_base", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("carences_base.json introuvable dans le bundle")
        }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(CarenceDatabaseFile.self, from: data)
        } catch {
            fatalError("Impossible de décoder carences_base.json : \(error)")
        }
    }()

    static func symptomeLabel(for id: String) -> String {
        shared.symptomes.first(where: { $0.id == id })?.label ?? id
    }

    static func carence(for id: String) -> Carence? {
        shared.carences.first(where: { $0.id == id })
    }

    static func symptomes(for category: SymptomCategory) -> [Symptome] {
        shared.symptomes.filter { $0.categorie == category.rawValue }
    }

    static func soinsLocaux(for symptomes: Set<String>) -> [SoinLocal] {
        shared.soinsLocaux.filter { soin in
            soin.symptomesCibles.contains { symptomes.contains($0) }
        }
    }

    static func bilansSuggeres(scores: [ScoreResult], regles: [RegleCombination]) -> [BilanSanguin] {
        var ids = Set<String>()
        if regles.contains(where: { $0.bilanMedicalRequis == true }) {
            ids.insert("bilan_complet")
        }
        if scores.contains(where: { $0.carenceId == "fer" && $0.score >= 30 }) {
            ids.insert("bilan_base")
        }
        if scores.contains(where: { ["iode", "selenium"].contains($0.carenceId) && $0.score >= 40 }) {
            ids.insert("bilan_thyroide")
        }
        if ids.isEmpty, scores.count >= 3 {
            ids.insert("bilan_base")
        }
        return shared.bilansSanguinsRecommandes.filter { ids.contains($0.id) }
    }
}
