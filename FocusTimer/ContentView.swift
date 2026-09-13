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
    @State private var selectedTab = 0
    @State private var showDayPlan = false

    private var showMiniTimer: Bool {
        let phaseFullSeconds = (timerViewModel.phase == .work ? timerViewModel.workMinutes : timerViewModel.restMinutes) * 60
        return timerViewModel.isRunning || timerViewModel.secondsLeft != phaseFullSeconds
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if showMiniTimer {
                    MiniTimerBar(viewModel: timerViewModel, onTap: { selectedTab = 0 })
                }

                TabView(selection: $selectedTab) {
                    TimerScreen(viewModel: timerViewModel)
                        .tag(0)
                        .tabItem {
                            Label("Таймер", systemImage: "play.fill")
                        }

                    HistoryScreen()
                        .tag(1)
                        .tabItem {
                            Label("История", systemImage: "clock.arrow.circlepath")
                        }

                    StatsScreen()
                        .tag(2)
                        .tabItem {
                            Label("Статистика", systemImage: "chart.bar.fill")
                        }

                    SettingsScreen(onLogout: onLogout)
                        .tag(3)
                        .tabItem {
                            Label("Настройки", systemImage: "gearshape.fill")
                        }

                    ProfileScreen()
                        .tag(4)
                        .tabItem {
                            Label("Профиль", systemImage: "person.fill")
                        }
                }
            }
            .overlay(alignment: .topTrailing) {
                Menu {
                    Button("Создать план на день") { showDayPlan = true }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.trailing, 16)
                .padding(.top, 6)
            }

            if showDayPlan {
                DayPlanScreen(onBack: { showDayPlan = false })
                    .background(Color(UIColor.systemBackground))
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .onChange(of: timerViewModel.isRunning) { isRunning in
            UIApplication.shared.isIdleTimerDisabled = isRunning && PrefsManager.shared.keepScreenOn
        }
    }
}

private struct MiniTimerBar: View {
    @ObservedObject var viewModel: TimerViewModel
    let onTap: () -> Void

    private var minutes: Int { viewModel.secondsLeft / 60 }
    private var seconds: Int { viewModel.secondsLeft % 60 }
    private var phaseColor: Color { viewModel.phase == .work ? AppColors.workColor : AppColors.restColor }

    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isRunning ? "play.fill" : "pause.fill")
                    Text(viewModel.phase == .work ? "Работа" : "Отдых")
                        .fontWeight(.bold)
                }
                Spacer()
                Text(String(format: "%02d:%02d", minutes, seconds))
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .foregroundColor(phaseColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(phaseColor.opacity(0.15))
        }
        .buttonStyle(.plain)
    }
}
