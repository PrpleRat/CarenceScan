import SwiftUI

enum AppTab: Hashable {
    case accueil
    case bilan
    case suivi
    case courses
}

@MainActor
final class AppTabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .accueil
    @Published var highlightSummaryOnBilan = false

    func openBilanSummary() {
        selectedTab = .bilan
        highlightSummaryOnBilan = true
    }

    func openCourses() {
        selectedTab = .courses
    }

    func openSuivi() {
        selectedTab = .suivi
    }
}
