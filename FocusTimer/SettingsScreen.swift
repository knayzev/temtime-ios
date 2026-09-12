import SwiftUI

struct SettingsScreen: View {
    @State private var soundEnabled = PrefsManager.shared.soundEnabled
    @State private var vibrationEnabled = PrefsManager.shared.vibrationEnabled
    @State private var keepScreenOn = PrefsManager.shared.keepScreenOn

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

            Spacer()
        }
        .padding(24)
    }
}
