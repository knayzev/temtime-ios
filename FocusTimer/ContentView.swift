import SwiftUI

private enum RootScreen {
    case auth
    case onboarding
    case lifestyle
    case main
}

struct ContentView: View {
    @State private var screen: RootScreen = {
        let prefs = PrefsManager.shared
        if !prefs.isRegistered || !prefs.isLoggedIn {
            return .auth
        } else if !prefs.isOnboarded {
            return .onboarding
        } else {
            return .main
        }
    }()

    var body: some View {
        Group {
            switch screen {
            case .auth:
                AuthScreen(
                    startInLoginMode: PrefsManager.shared.isRegistered,
                    onAuthenticated: {
                        screen = PrefsManager.shared.isOnboarded ? .main : .onboarding
                    }
                )
            case .onboarding:
                OnboardingScreen(onComplete: { screen = .lifestyle })
            case .lifestyle:
                LifestyleQuestionsScreen(onComplete: { screen = .main })
            case .main:
                MainTabView(onLogout: {
                    PrefsManager.shared.isLoggedIn = false
                    screen = .auth
                })
            }
        }
        .tint(AppColors.primary)
    }
}

private struct MainTabView: View {
    let onLogout: () -> Void
    @StateObject private var timerViewModel = TimerViewModel()

    var body: some View {
        TabView {
            TimerScreen(viewModel: timerViewModel)
                .tabItem {
                    Label("Таймер", systemImage: "play.fill")
                }

            HistoryScreen()
                .tabItem {
                    Label("История", systemImage: "clock.arrow.circlepath")
                }

            StatsScreen()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }

            SettingsScreen(onLogout: onLogout)
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
