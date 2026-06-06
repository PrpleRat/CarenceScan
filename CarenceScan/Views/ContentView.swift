import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .tint(CarenceColors.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(QuestionnaireViewModel())
}
