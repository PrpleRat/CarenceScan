import Foundation

struct SymptomJournalEntry: Codable, Identifiable, Hashable {
    var id: String { "\(dayKey)|\(symptomeId)" }
    let date: Date
    let symptomeId: String
    let present: Bool

    var dayKey: String {
        Calendar.current.startOfDay(for: date).ISO8601Format()
    }
}

struct SymptomTrackingSettings: Codable, Equatable {
    var notificationsEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var trackedSymptomeIds: [String]

    static let `default` = SymptomTrackingSettings(
        notificationsEnabled: false,
        reminderHour: 20,
        reminderMinute: 0,
        trackedSymptomeIds: []
    )
}

struct SymptomeCarenceLink: Identifiable, Hashable {
    var id: String { carenceId }
    let carenceId: String
    let carenceNom: String
    let tier: SymptomeCarenceTier
    let score: Int
}

enum SymptomeCarenceTier: String, Hashable, CaseIterable {
    case primaire
    case secondaire
    case contextuel
    case associe

    var label: String {
        switch self {
        case .primaire: return "Symptôme caractéristique"
        case .secondaire: return "Symptôme fréquent"
        case .contextuel: return "Lié au mode de vie"
        case .associe: return "Association possible"
        }
    }

    var emoji: String {
        switch self {
        case .primaire: return "🎯"
        case .secondaire: return "📌"
        case .contextuel: return "🔄"
        case .associe: return "🔗"
        }
    }
}

struct SymptomeFicheDetail {
    let symptomeId: String
    let label: String
    let categorie: String
    let description: String
    let quandSinquieter: String
    let carencesLiees: [SymptomeCarenceLink]
}
