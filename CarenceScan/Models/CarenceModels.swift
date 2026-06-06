import Foundation

struct CarenceDatabaseFile: Codable {
    let version: String
    let description: String
    let lastUpdated: String
    let symptomes: [Symptome]
    let medicamentsDepleteurs: [MedicamentDepleteur]
    let carences: [Carence]
    let reglesCombinatoiresSpeciales: [RegleCombination]
    let soinsLocaux: [SoinLocal]
    let bilansSanguinsRecommandes: [BilanSanguin]
    let avertissements: Avertissements

    enum CodingKeys: String, CodingKey {
        case version, description, symptomes, carences, avertissements
        case lastUpdated = "last_updated"
        case medicamentsDepleteurs = "medicaments_depleteurs"
        case reglesCombinatoiresSpeciales = "regles_combinatoires_speciales"
        case soinsLocaux = "soins_locaux"
        case bilansSanguinsRecommandes = "bilans_sanguins_recommandes"
    }
}

struct Symptome: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let categorie: String
}

struct MedicamentDepleteur: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let carencesInduites: [String]
    let note: String

    enum CodingKeys: String, CodingKey {
        case id, label, note
        case carencesInduites = "carences_induites"
    }
}

struct Carence: Codable, Identifiable {
    let id: String
    let nom: String
    let description: String
    let symptomesPrimaires: [String]
    let symptomesSecondaires: [String]
    let symptomesContextuels: [String]
    let scoreParSymptome: [String: Int]
    let seuilProbable: Int
    let seuilTresProbable: Int
    let seuilQuasiCertain: Int
    let combinaisonsAmplificatrices: [CombinaisonAmplificatrice]
    let alimentsCles: [String]
    let complement: ComplementInfo
    let urgence: String
    let prescriptionObligatoire: Bool?
    let interactionsMedicaments: [String]?

    enum CodingKeys: String, CodingKey {
        case id, nom, description, complement, urgence
        case symptomesPrimaires = "symptomes_primaires"
        case symptomesSecondaires = "symptomes_secondaires"
        case symptomesContextuels = "symptomes_contextuels"
        case scoreParSymptome = "score_par_symptome"
        case seuilProbable = "seuil_probable"
        case seuilTresProbable = "seuil_tres_probable"
        case seuilQuasiCertain = "seuil_quasi_certain"
        case combinaisonsAmplificatrices = "combinaisons_amplificatrices"
        case alimentsCles = "aliments_cles"
        case prescriptionObligatoire = "prescription_obligatoire"
        case interactionsMedicaments = "interactions_medicaments"
    }
}

struct CombinaisonAmplificatrice: Codable {
    let symptomes: [String]
    let bonus: Int
}

struct ComplementInfo: Codable {
    let nom: String
    let posologie: String
    let formeRecommandee: String
    let prixMois: String
    let ouAcheter: String
    let precautions: String

    enum CodingKeys: String, CodingKey {
        case nom, posologie, precautions
        case formeRecommandee = "forme_recommandee"
        case prixMois = "prix_mois"
        case ouAcheter = "ou_acheter"
    }
}

struct RegleCombination: Codable, Identifiable {
    let id: String
    let label: String
    let description: String
    let symptomesRequis: [String]
    let carencesAmplifiees: [String]
    let bonusScore: Int
    let messageAlerte: String
    let bilanMedicalRequis: Bool?

    enum CodingKeys: String, CodingKey {
        case id, label, description
        case symptomesRequis = "symptomes_requis"
        case carencesAmplifiees = "carences_amplifiees"
        case bonusScore = "bonus_score"
        case messageAlerte = "message_alerte"
        case bilanMedicalRequis = "bilan_medical_requis"
    }
}

struct SoinLocal: Codable, Identifiable {
    let id: String
    let nom: String
    let utilisation: String
    let prix: String
    let symptomesCibles: [String]

    enum CodingKeys: String, CodingKey {
        case id, nom, utilisation, prix
        case symptomesCibles = "symptomes_cibles"
    }
}

struct BilanSanguin: Codable, Identifiable {
    let id: String
    let label: String
    let analyses: [String]
    let indication: String
    let remboursement: String
}

struct Avertissements: Codable {
    let general: String
    let medicaments: String
    let interactionsCritiques: [String]

    enum CodingKeys: String, CodingKey {
        case general, medicaments
        case interactionsCritiques = "interactions_critiques"
    }
}

struct ScoreResult: Identifiable, Codable, Hashable {
    var id: String { carenceId }
    let carenceId: String
    let score: Int
    let niveau: ProbabilityLevel
    let symptomesDetectes: [String]
    let alertes: [String]
    let bonusCombinations: Int
}

struct SavedResultsPayload: Codable {
    let date: Date
    let symptomesSelectionnes: [String]
    let medicamentsSelectionnes: [String]
    let scores: [ScoreResult]
    let reglesDetectees: [String]
}
