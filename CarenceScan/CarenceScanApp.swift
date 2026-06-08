import SwiftUI
import UserNotifications

@main
struct CarenceScanApp: App {
    @StateObject private var questionnaire = QuestionnaireViewModel()
    @StateObject private var tracker = SymptomTrackerViewModel.shared
    @StateObject private var tabRouter = AppTabRouter()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(questionnaire)
                .environmentObject(tracker)
                .environmentObject(tabRouter)
                .task {
                    await NotificationService.shared.refreshAuthorizationStatus()
                    await SmartNotificationService.evaluateAndSchedule(tracker: tracker)
                }
        }
    }
}
