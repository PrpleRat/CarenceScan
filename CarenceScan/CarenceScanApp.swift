import SwiftUI

@main
struct CarenceScanApp: App {
    @StateObject private var questionnaire = QuestionnaireViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(questionnaire)
        }
    }
}
