import Foundation

enum ResultsStorage {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static var hasSavedResults: Bool {
        load() != nil
    }

    static func save(_ payload: SavedResultsPayload) {
        guard let data = try? encoder.encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.resultsStorageKey)
    }

    static func load() -> SavedResultsPayload? {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.resultsStorageKey) else { return nil }
        return try? decoder.decode(SavedResultsPayload.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: AppConstants.resultsStorageKey)
    }

    static func saveDraft(symptomes: Set<String>, medicaments: Set<String>) {
        let draft = QuestionnaireDraft(symptomes: Array(symptomes), medicaments: Array(medicaments))
        guard let data = try? encoder.encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.questionnaireStorageKey)
    }

    static func loadDraft() -> QuestionnaireDraft? {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.questionnaireStorageKey) else { return nil }
        return try? decoder.decode(QuestionnaireDraft.self, from: data)
    }
}

struct QuestionnaireDraft: Codable {
    let symptomes: [String]
    let medicaments: [String]
}
