import SwiftUI
import UserNotifications

@main
struct CarenceScanApp: App {
    @StateObject private var questionnaire = QuestionnaireViewModel()
    @StateObject private var tracker = SymptomTrackerViewModel.shared

    init() {
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(questionnaire)
                .environmentObject(tracker)
                .task {
                    await NotificationService.shared.refreshAuthorizationStatus()
                }
        }
    }
}
