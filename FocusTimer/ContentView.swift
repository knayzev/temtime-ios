import SwiftUI

private enum RootScreen {
    case profileSetup
    case scheduleSetup
    case main
}

struct ContentView: View {
    // There is no account to sign in to: the app opens on the setup once and on the day itself
    // ever after. Name and e-mail are optional and live in the profile.
    @State private var screen: RootScreen = PrefsManager.shared.isOnboarded ? .main : .profileSetup

    var body: some View {
        Group {
            switch screen {
            case .profileSetup:
                ProfileSetupScreen(onNext: { screen = .scheduleSetup })
            case .scheduleSetup:
                ScheduleSetupScreen(
                    onBack: { screen = .profileSetup },
                    onDone: { screen = .main }
                )
            case .main:
                MainTabView()
            }
        }
        .tint(AppColors.primary)
    }
}

/// Screens opened on top of the tabs rather than as one of them.
private enum OverlayScreen: String, Identifiable {
    case routine
    case lifestyle
    case details

    var id: String { rawValue }
}

private struct MainTabView: View {
    @StateObject private var timerViewModel = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var overlay: OverlayScreen?

    var body: some View {
        VStack(spacing: 0) {
            // The Today tab already shows the dial; elsewhere this keeps the countdown in sight.
            if timerViewModel.isActive && selectedTab != 0 {
                MiniTimerBar(viewModel: timerViewModel, onTap: { selectedTab = 0 })
            }

            TabView(selection: $selectedTab) {
                page("Сегодня") { TimerScreen(viewModel: timerViewModel) }
                    .tag(0)
                    .tabItem { Label("Сегодня", systemImage: "timer") }

                page("История") { HistoryScreen() }
                    .tag(1)
                    .tabItem { Label("История", systemImage: "clock.arrow.circlepath") }

                page("Статистика") { StatsScreen() }
                    .tag(2)
                    .tabItem { Label("Статистика", systemImage: "chart.bar.fill") }

                page("Настройки") { SettingsScreen() }
                    .tag(3)
                    .tabItem { Label("Настройки", systemImage: "gearshape.fill") }

                page("Профиль") {
                    ProfileScreen(
                        onOpenLifestyle: { overlay = .lifestyle },
                        onOpenDetails: { overlay = .details }
                    )
                }
                .tag(4)
                .tabItem { Label("Профиль", systemImage: "person.fill") }
            }
        }
        .sheet(item: $overlay) { which in
            NavigationStack {
                Group {
                    switch which {
                    case .routine:
                        RoutineScreen()
                    case .lifestyle:
                        LifestyleQuestionsScreen(onComplete: { overlay = nil })
                    // The long questionnaire is no longer part of setup, but it is the only place
                    // some schedule inputs are collected, so it stays reachable from the profile.
                    case .details:
                        OnboardingScreen(onComplete: { overlay = nil })
                    }
                }
                .navigationTitle(overlayTitle(which))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Закрыть") { overlay = nil }
                    }
                }
            }
        }
        .onAppear {
            NotificationScheduler.requestAuthorization()
            timerViewModel.refreshDay()
            applyKeepScreenOn(timerViewModel.isRunning)
        }
        .onChange(of: timerViewModel.isRunning) { isRunning in
            applyKeepScreenOn(isRunning)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                timerViewModel.appBecameActive()
            }
        }
    }

    /// One tab's content under a title bar. Naming the section in the bar lets each screen drop
    /// its own headline, and the rituals stay one tap away from anywhere.
    private func page<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            overlay = .routine
                        } label: {
                            Image(systemName: "checklist")
                        }
                        .accessibilityLabel("Ритуалы")
                    }
                }
        }
    }

    private func overlayTitle(_ which: OverlayScreen) -> String {
        switch which {
        case .routine: return "Ритуалы"
        case .lifestyle: return "Образ жизни"
        case .details: return "Подробная анкета"
        }
    }

    private func applyKeepScreenOn(_ isRunning: Bool) {
        UIApplication.shared.isIdleTimerDisabled = isRunning && PrefsManager.shared.keepScreenOn
    }
}

private struct MiniTimerBar: View {
    @ObservedObject var viewModel: TimerViewModel
    let onTap: () -> Void

    private var phaseColor: Color { viewModel.phase == .work ? AppColors.workColor : AppColors.restColor }

    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isRunning ? "play.fill" : "pause.fill")
                    Text(viewModel.phaseLabel)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                Spacer()
                Text(formatClock(viewModel.secondsLeft))
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .foregroundColor(phaseColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(phaseColor.opacity(0.1))
        }
        .buttonStyle(.plain)
    }
}
