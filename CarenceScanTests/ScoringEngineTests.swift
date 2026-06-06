import XCTest
@testable import CarenceScan

final class ScoringEngineTests: XCTestCase {

    private let validationSymptoms: Set<String> = [
        "gencives_douloureuses",
        "coins_levres_craques",
        "crevasses_doigts",
        "peau_seche_oreilles",
        "fatigue_intense",
        "travail_nuit"
    ]

    func testValidationScenario() {
        let scores = ScoringEngine.calculerScores(
            symptomesSelectionnes: validationSymptoms,
            medicamentsSelectionnes: []
        )
        let regles = ScoringEngine.detecterCombinaisonsSpeciales(
            symptomesSelectionnes: validationSymptoms,
            regles: CarenceDatabase.shared.reglesCombinatoiresSpeciales
        )

        let vitC = scores.first { $0.carenceId == "vitamine_c" }
        XCTAssertNotNil(vitC)
        XCTAssertGreaterThanOrEqual(vitC?.score ?? 0, 65)
        XCTAssertTrue(vitC?.niveau == .tresProbable || vitC?.niveau == .quasiCertaine)

        let zinc = scores.first { $0.carenceId == "zinc" }
        XCTAssertNotNil(zinc)
        XCTAssertEqual(zinc?.niveau, .quasiCertaine)
        XCTAssertGreaterThan(zinc?.score ?? 0, 70)

        let vitD = scores.first { $0.carenceId == "vitamine_d" }
        XCTAssertNotNil(vitD)
        XCTAssertTrue(vitD?.niveau == .tresProbable || vitD?.niveau == .quasiCertaine)

        let b2b3 = scores.first { $0.carenceId == "vitamine_b2_b3" }
        XCTAssertNotNil(b2b3)
        XCTAssertTrue(b2b3?.niveau == .tresProbable || b2b3?.niveau == .quasiCertaine)

        XCTAssertTrue(regles.contains { $0.id == "combo_peau_muqueuses" })
    }

    func testMedicamentBonus() {
        var scores = ScoringEngine.calculerScores(
            symptomesSelectionnes: ["fatigue_intense"],
            medicamentsSelectionnes: []
        )
        let baseMag = scores.first { $0.carenceId == "magnesium" }?.score

        scores = ScoringEngine.calculerScores(
            symptomesSelectionnes: ["fatigue_intense", "irritabilite"],
            medicamentsSelectionnes: ["sertraline"]
        )
        let withMed = scores.first { $0.carenceId == "magnesium" }
        XCTAssertNotNil(withMed)
        if let baseMag, let withMed {
            XCTAssertGreaterThanOrEqual(withMed.score, baseMag + 20)
        }
    }
}
