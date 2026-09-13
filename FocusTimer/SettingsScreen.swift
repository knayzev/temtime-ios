import SwiftUI
import CoreMotion

struct SettingsScreen: View {
    @State private var soundEnabled = PrefsManager.shared.soundEnabled
    @State private var vibrationEnabled = PrefsManager.shared.vibrationEnabled
    @State private var keepScreenOn = PrefsManager.shared.keepScreenOn

    @State private var stepsEnabled = PrefsManager.shared.stepsEnabled
    @State private var stepCount: Int?
    @State private var pedometer = CMPedometer()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Настройки")
                .font(.title.bold())
                .padding(.bottom, 8)

            Toggle("Звук по окончании этапа", isOn: $soundEnabled)
                .onChange(of: soundEnabled) { PrefsManager.shared.soundEnabled = $0 }

            Toggle("Вибрация по окончании этапа", isOn: $vibrationEnabled)
                .onChange(of: vibrationEnabled) { PrefsManager.shared.vibrationEnabled = $0 }

            Toggle("Не выключать экран во время таймера", isOn: $keepScreenOn)
                .onChange(of: keepScreenOn) { PrefsManager.shared.keepScreenOn = $0 }

            Divider()

            Toggle("Счётчик шагов", isOn: $stepsEnabled)
                .onChange(of: stepsEnabled) { enabled in
                    PrefsManager.shared.stepsEnabled = enabled
                    if enabled {
                        startStepUpdates()
                    } else {
                        pedometer.stopUpdates()
                        stepCount = nil
                    }
                }

            if stepsEnabled {
                Text(stepCount.map { "Шагов сегодня: \($0)" } ?? "Считаем шаги…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(24)
        .onAppear {
            if stepsEnabled {
                startStepUpdates()
            }
        }
        .onDisappear {
            pedometer.stopUpdates()
        }
    }

    private func startStepUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: startOfDay) { data, _ in
            guard let data else { return }
            DispatchQueue.main.async {
                stepCount = data.numberOfSteps.intValue
            }
        }
    }
}
