import SwiftUI
import UniformTypeIdentifiers

private struct JSONTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct SettingsScreen: View {
    var onLogout: () -> Void = {}
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Основные настройки").tag(0)
                Text("Активность").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                GeneralSettingsView(onLogout: onLogout)
            } else {
                ActivitySettingsView()
            }
        }
    }
}

private struct GeneralSettingsView: View {
    let onLogout: () -> Void

    @State private var soundEnabled = PrefsManager.shared.soundEnabled
    @State private var vibrationEnabled = PrefsManager.shared.vibrationEnabled
    @State private var keepScreenOn = PrefsManager.shared.keepScreenOn

    @State private var voiceAnnounceEnabled = PrefsManager.shared.voiceAnnounceEnabled
    @State private var voiceAnnounceValue = String(PrefsManager.shared.voiceAnnounceLeadValue)
    @State private var voiceAnnounceUnit = PrefsManager.shared.voiceAnnounceUnit

    @State private var showExporter = false
    @State private var showImporter = false
    @State private var showImportConfirm = false
    @State private var pendingImportText: String?
    @State private var importMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Звук по окончании этапа", isOn: $soundEnabled)
                    .onChange(of: soundEnabled) { PrefsManager.shared.soundEnabled = $0 }

                Toggle("Вибрация по окончании этапа", isOn: $vibrationEnabled)
                    .onChange(of: vibrationEnabled) { PrefsManager.shared.vibrationEnabled = $0 }

                Toggle("Не выключать экран во время таймера", isOn: $keepScreenOn)
                    .onChange(of: keepScreenOn) { PrefsManager.shared.keepScreenOn = $0 }

                Divider()
                Text("Голосовое предупреждение").font(.headline)
                Text("Голосом предупредит о приближении смены этапа заранее")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Озвучивать приближение конца этапа", isOn: $voiceAnnounceEnabled)
                    .onChange(of: voiceAnnounceEnabled) { PrefsManager.shared.voiceAnnounceEnabled = $0 }

                if voiceAnnounceEnabled {
                    HStack {
                        TextField("За сколько", text: $voiceAnnounceValue)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .onChange(of: voiceAnnounceValue) { newValue in
                                if let value = Int(newValue), (1...600).contains(value) {
                                    PrefsManager.shared.voiceAnnounceLeadValue = value
                                }
                            }
                        Picker("", selection: $voiceAnnounceUnit) {
                            Text("Секунды").tag("Секунды")
                            Text("Минуты").tag("Минуты")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: voiceAnnounceUnit) { PrefsManager.shared.voiceAnnounceUnit = $0 }
                    }
                }

                Divider()
                Text("Экспорт и бэкап").font(.headline)
                Text("Все данные хранятся только на этом устройстве — сохраните файл, чтобы не потерять историю")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button("Экспортировать") {
                        showExporter = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)

                    Button("Импортировать") {
                        showImporter = true
                    }
                    .buttonStyle(.bordered)
                }

                if let importMessage {
                    Text(importMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                Button("Выйти из аккаунта", role: .destructive) {
                    onLogout()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
            }
            .padding(24)
        }
        .fileExporter(
            isPresented: $showExporter,
            document: JSONTextDocument(text: PrefsManager.shared.exportAllData()),
            contentType: .json,
            defaultFilename: "focus-timer-backup"
        ) { result in
            switch result {
            case .success:
                importMessage = "Данные экспортированы"
            case .failure:
                importMessage = "Не удалось сохранить файл"
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) {
                    pendingImportText = text
                    showImportConfirm = true
                } else {
                    importMessage = "Не удалось прочитать файл"
                }
            case .failure:
                importMessage = "Не удалось открыть файл"
            }
        }
        .alert("Импортировать данные?", isPresented: $showImportConfirm) {
            Button("Отмена", role: .cancel) {
                pendingImportText = nil
            }
            Button("Импортировать", role: .destructive) {
                if let text = pendingImportText, PrefsManager.shared.importAllData(text) {
                    importMessage = "Данные импортированы"
                } else {
                    importMessage = "Не удалось прочитать файл"
                }
                pendingImportText = nil
            }
        } message: {
            Text("Текущий профиль, настройки и история будут заменены содержимым файла.")
        }
    }
}

private struct ActivitySettingsView: View {
    @StateObject private var stepCounter = LiveStepCounter()
    @State private var stepsEnabled = PrefsManager.shared.stepsEnabled

    @State private var categories = PrefsManager.shared.categories
    @State private var newCategory = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Счётчик шагов", isOn: $stepsEnabled)
                    .onChange(of: stepsEnabled) { enabled in
                        PrefsManager.shared.stepsEnabled = enabled
                        if enabled {
                            stepCounter.start()
                        } else {
                            stepCounter.stop()
                        }
                    }

                if stepsEnabled {
                    Text(stepCounter.steps.map { "Шагов сегодня: \($0)" } ?? "Считаем шаги…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()
                Text("Категории активности").font(.headline)
                Text("Выбираются на экране таймера и видны в истории")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(categories, id: \.self) { category in
                    HStack {
                        Text(category)
                        Spacer()
                        Button {
                            categories.removeAll { $0 == category }
                            PrefsManager.shared.categories = categories
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                HStack {
                    TextField("Новая категория", text: $newCategory)
                        .textFieldStyle(.roundedBorder)
                    Button("Добавить") {
                        let trimmed = newCategory.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !categories.contains(trimmed) {
                            categories.append(trimmed)
                            PrefsManager.shared.categories = categories
                        }
                        newCategory = ""
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            if stepsEnabled {
                stepCounter.start()
            }
        }
        .onDisappear {
            stepCounter.stop()
        }
    }
}
