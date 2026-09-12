import SwiftUI

struct ContentView: View {
    @StateObject private var timerViewModel = TimerViewModel()

    var body: some View {
        TabView {
            TimerScreen(viewModel: timerViewModel)
                .tabItem {
                    Label("Таймер", systemImage: "play.fill")
                }

            SettingsScreen()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }

            ProfileScreen()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
        }
        .onChange(of: timerViewModel.isRunning) { isRunning in
            UIApplication.shared.isIdleTimerDisabled = isRunning && PrefsManager.shared.keepScreenOn
        }
    }
}
