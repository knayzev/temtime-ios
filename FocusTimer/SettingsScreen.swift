import SwiftUI
import CoreMotion
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
    @State private var soundEnabled = PrefsManager.shared.soundEnabled
    @State private var vibrationEnabled = PrefsManager.shared.vibrationEnabled
    @State private var keepScreenOn = PrefsManager.shared.keepScreenOn

    @State private var stepsEnabled = PrefsManager.shared.stepsEnabled
    @State private var stepCount: Int?
    @State private var pedometer = CMPedometer()

    @State private var categories = PrefsManager.shared.categories
    @State private var newCategory = ""

    @State private var showExporter = false
    @State private var showImporter = false
    @State private var showImportConfirm = false
    @State private var pendingImportText: String?
    @State private var importMessage: String?

    var body: some View {
        ScrollView {
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
            }
            .padding(24)
        }
        .onAppear {
            if stepsEnabled {
                startStepUpdates()
            }
        }
        .onDisappear {
            pedometer.stopUpdates()
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
                    categories = PrefsManager.shared.categories
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
