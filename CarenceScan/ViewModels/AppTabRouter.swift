import SwiftUI

enum AppTab: Hashable {
    case accueil
    case bilan
    case suivi
    case courses
}

enum CoursesHubSection: Hashable {
    case liste
    case recettes
}

@MainActor
final class AppTabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .accueil
    @Published var highlightSummaryOnBilan = false
    @Published var coursesSection: CoursesHubSection = .liste

    func openBilanSummary() {
        selectedTab = .bilan
        highlightSummaryOnBilan = true
    }

    func openCourses(section: CoursesHubSection = .liste) {
        coursesSection = section
        selectedTab = .courses
    }

    func openRecettes() {
        openCourses(section: .recettes)
    }

    func openSuivi() {
        selectedTab = .suivi
    }
}
