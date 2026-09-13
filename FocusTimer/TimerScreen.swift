import SwiftUI

struct TimerScreen: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var showComment = false

    @State private var presets = PrefsManager.shared.presets
    @State private var editingPreset: TimerPreset?
    @State private var isAddingNewPreset = false

    private var minutes: Int { viewModel.secondsLeft / 60 }
    private var seconds: Int { viewModel.secondsLeft % 60 }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if !viewModel.isRunning {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets) { preset in
                            PresetChip(
                                preset: preset,
                                onApply: {
                                    viewModel.setWorkMinutes(preset.workMinutes)
                                    viewModel.setRestMinutes(preset.restMinutes)
                                    if !preset.comment.isEmpty {
                                        viewModel.currentComment = preset.comment
                                    }
                                },
                                onEdit: { editingPreset = preset }
                            )
                        }
                        Button {
                            isAddingNewPreset = true
                        } label: {
                            Text("+ Добавить")
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(AppColors.primary.opacity(0.15))
                                .foregroundColor(AppColors.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            Text(viewModel.phase == .work ? "Работа" : "Отдых")
                .font(.title.bold())
                .foregroundColor(viewModel.phase == .work ? AppColors.workColor : AppColors.restColor)

            Text(String(format: "%02d:%02d", minutes, seconds))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()

            let categories = PrefsManager.shared.categories
            if !categories.isEmpty {
                Picker("Чем занимаетесь", selection: $viewModel.currentCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack(spacing: 16) {
                Button(viewModel.isRunning ? "Пауза" : "Старт") {
                    if viewModel.isRunning {
                        viewModel.pause()
                    } else {
                        viewModel.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)

                Button("Стоп") {
                    viewModel.stop()
                }
                .buttonStyle(.bordered)
            }

            Button(showComment ? "Скрыть комментарий" : "Добавить комментарий") {
                showComment.toggle()
            }
            .font(.footnote)

            if showComment {
                TextField("Комментарий к сессии", text: $viewModel.currentComment)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 24)
            }

            if !viewModel.isRunning {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Время работы: \(viewModel.workMinutes) мин")
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.workMinutes) },
                            set: { viewModel.setWorkMinutes(Int($0)) }
                        ),
                        in: 5...100,
                        step: 5
                    )

                    Text("Время отдыха: \(viewModel.restMinutes) мин")
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.restMinutes) },
                            set: { viewModel.setRestMinutes(Int($0)) }
                        ),
                        in: 5...100,
                        step: 5
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Spacer()
        }
        .sheet(item: $editingPreset) { preset in
            PresetEditView(
                preset: preset,
                onSave: { updated in
                    presets = presets.map { $0.id == updated.id ? updated : $0 }
                    PrefsManager.shared.presets = presets
                },
                onDelete: {
                    presets.removeAll { $0.id == preset.id }
                    PrefsManager.shared.presets = presets
                }
            )
        }
        .sheet(isPresented: $isAddingNewPreset) {
            PresetEditView(
                preset: nil,
                onSave: { newPreset in
                    presets.append(newPreset)
                    PrefsManager.shared.presets = presets
                },
                onDelete: nil
            )
        }
    }
}

private struct PresetChip: View {
    let preset: TimerPreset
    let onApply: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(preset.label)
                .onTapGesture(perform: onApply)
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}

private struct PresetEditView: View {
    let preset: TimerPreset?
    let onSave: (TimerPreset) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var label: String
    @State private var workMinutes: Int
    @State private var restMinutes: Int
    @State private var comment: String

    init(preset: TimerPreset?, onSave: @escaping (TimerPreset) -> Void, onDelete: (() -> Void)?) {
        self.preset = preset
        self.onSave = onSave
        self.onDelete = onDelete
        _label = State(initialValue: preset?.label ?? "")
        _workMinutes = State(initialValue: preset?.workMinutes ?? 25)
        _restMinutes = State(initialValue: preset?.restMinutes ?? 5)
        _comment = State(initialValue: preset?.comment ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $label)
                Stepper("Работа: \(workMinutes) мин", value: $workMinutes, in: 1...180)
                Stepper("Отдых: \(restMinutes) мин", value: $restMinutes, in: 1...180)
                TextField("Комментарий по умолчанию", text: $comment)

                if let onDelete {
                    Button("Удалить", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            }
            .navigationTitle(preset == nil ? "Новый таб" : "Изменить таб")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        guard !label.isEmpty else { return }
                        onSave(
                            TimerPreset(
                                id: preset?.id ?? "preset_\(Int(Date().timeIntervalSince1970 * 1000))",
                                label: label,
                                workMinutes: workMinutes,
                                restMinutes: restMinutes,
                                comment: comment
                            )
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
