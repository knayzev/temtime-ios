import SwiftUI

/// "Сегодня": the countdown on top, the day's schedule under it. Tapping an entry loads it into
/// the timer; finishing its work phase ticks it off and queues the next one.
struct TimerScreen: View {
    @ObservedObject var viewModel: TimerViewModel
    @StateObject private var stepCounter = LiveStepCounter()
    @State private var showCommentEditor = false
    @State private var draftComment = ""

    @State private var presets = PrefsManager.shared.presets
    @State private var editingPreset: TimerPreset?
    @State private var isAddingNewPreset = false

    @State private var editingItem: PlanItem?
    @State private var addingItem = false
    @State private var wordHidden = PrefsManager.shared.wordSeenDate == dayStamp()
    @State private var minuteOfDay = nowMinutesOfDay()

    private static let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var term: DayWord { wordOfTheDay() }

    private var phaseColor: Color {
        viewModel.phase == .work ? AppColors.workColor : AppColors.restColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                notices

                let categories = PrefsManager.shared.categories
                if !categories.isEmpty {
                    Picker("Чем занимаетесь", selection: $viewModel.currentCategory) {
                        // An entry's title becomes the category while it runs, so it is offered
                        // even though it is not one of the saved categories.
                        if !categories.contains(viewModel.currentCategory) && !viewModel.currentCategory.isEmpty {
                            Text(viewModel.currentCategory).tag(viewModel.currentCategory)
                        }
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                TimerDial(
                    fraction: Double(viewModel.secondsLeft) / Double(viewModel.phaseTotalSeconds),
                    label: viewModel.phaseLabel,
                    timeText: formatClock(viewModel.secondsLeft),
                    color: phaseColor
                )
                .padding(.vertical, 4)

                HStack(spacing: 32) {
                    DialAction(systemImage: "stop.fill", label: "Стоп", primary: false) {
                        viewModel.stop()
                    }
                    DialAction(
                        systemImage: viewModel.isRunning ? "pause.fill" : "play.fill",
                        label: viewModel.isRunning ? "Пауза" : "Старт",
                        primary: true
                    ) {
                        if viewModel.isRunning {
                            viewModel.pause()
                        } else {
                            viewModel.start()
                        }
                    }
                }

                commentSection

                if !viewModel.isRunning {
                    VStack(alignment: .leading, spacing: 8) {
                        MinutesInputRow(label: "Время работы", minutes: viewModel.workMinutes) {
                            viewModel.setWorkMinutes($0)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(min(max(viewModel.workMinutes, 5), 100)) },
                                set: { viewModel.setWorkMinutes(Int($0)) }
                            ),
                            in: 5...100,
                            step: 5
                        )

                        MinutesInputRow(label: "Время отдыха", minutes: viewModel.restMinutes) {
                            viewModel.setRestMinutes($0)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(min(max(viewModel.restMinutes, 5), 100)) },
                                set: { viewModel.setRestMinutes(Int($0)) }
                            ),
                            in: 5...100,
                            step: 5
                        )
                    }
                    .padding(.top, 12)
                }

                Divider().padding(.vertical, 8)

                DayScheduleView(
                    items: viewModel.planItems,
                    doneIds: viewModel.doneIds,
                    runningId: viewModel.phase == .work ? viewModel.selectedPlanId : nil,
                    nowMinutes: minuteOfDay,
                    onSelect: { viewModel.selectPlan($0) },
                    onToggleDone: { item in
                        let willBeDone = !viewModel.doneIds.contains(item.id)
                        viewModel.toggleDone(item)
                        if willBeDone {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    },
                    onEdit: { editingItem = $0 },
                    onAdd: { addingItem = true }
                )
                if viewModel.planItems.count >= maxPlanItems {
                    Text("Достигнут предел — \(maxPlanItems) пунктов на день")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .onAppear {
            // Being on this screen counts as noticing the current phase.
            viewModel.acknowledge()
            viewModel.refreshDay()
            minuteOfDay = nowMinutesOfDay()
            if PrefsManager.shared.stepsEnabled {
                stepCounter.start()
            }
        }
        .onDisappear {
            stepCounter.stop()
        }
        .onReceive(Self.clock) { _ in
            minuteOfDay = nowMinutesOfDay()
        }
        .sheet(isPresented: $addingItem) {
            PlanItemEditor(
                existing: nil,
                defaultTime: minutesToClock(
                    viewModel.planItems.map { parseClockMinutes($0.time) + $0.minutes }.max() ?? nowMinutesOfDay()
                ),
                onSave: { viewModel.addPlanItem($0) }
            )
        }
        .sheet(item: $editingItem) { item in
            PlanItemEditor(
                existing: item,
                defaultTime: item.time,
                onSave: { viewModel.updatePlanItem($0) },
                onDelete: { viewModel.deletePlanItem(item) }
            )
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

    /// What may sit above the dial: the term of the day, a missed-window warning, the presets,
    /// today's steps and the quote earned by the last finished block.
    @ViewBuilder
    private var notices: some View {
        if !wordHidden {
            wordCard
        }

        if viewModel.escalationActive {
            HStack {
                Text("Окно пропущено — вас уведомили")
                    .font(.subheadline)
                Spacer()
                Button("Я тут") { viewModel.acknowledge() }
                    .font(.subheadline.bold())
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.coralSoft))
        }

        if !viewModel.isRunning {
            presetRow
        }

        if let steps = stepCounter.steps {
            Text("Шаги сегодня: \(steps)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }

        if let quote = viewModel.motivationQuote {
            HStack(alignment: .top) {
                Text(quote)
                    .font(.footnote)
                Spacer()
                Button {
                    viewModel.dismissQuote()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Скрыть")
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.tealSoft))
        }
    }

    private var wordCard: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("СЛОВО ДНЯ")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(AppColors.restColor)
                Text(term.word)
                    .font(.headline)
                Text(term.meaning)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                PrefsManager.shared.wordSeenDate = dayStamp()
                wordHidden = true
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Скрыть до завтра")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppColors.tealSoft))
    }

    private var presetRow: some View {
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
                        .background(AppColors.primarySoft)
                        .foregroundColor(AppColors.primary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private var commentSection: some View {
        if !showCommentEditor {
            if viewModel.currentComment.isEmpty {
                Button("Добавить комментарий") {
                    draftComment = viewModel.currentComment
                    showCommentEditor = true
                }
                .font(.footnote)
            } else {
                HStack {
                    Text(viewModel.currentComment)
                        .font(.subheadline)
                    Spacer()
                    Button {
                        draftComment = viewModel.currentComment
                        showCommentEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Изменить комментарий")
                }
            }
        } else {
            VStack(spacing: 8) {
                TextField("Комментарий к сессии", text: $draftComment)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Отмена") {
                        showCommentEditor = false
                    }
                    Button("Сохранить") {
                        viewModel.currentComment = draftComment
                        showCommentEditor = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                }
            }
        }
    }
}

/// The countdown as a ring that drains over the phase. `fraction` is the share of the phase still
/// left, so a full ring means the phase has just begun.
private struct TimerDial: View {
    let fraction: Double
    let label: String
    let timeText: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 18)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(fraction, 0), 1)))
                .stroke(color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                // Animating the sweep keeps the ring from stepping a visible notch every second.
                .animation(.easeInOut(duration: 0.7), value: fraction)
            VStack(spacing: 2) {
                Text(label)
                    .font(.headline)
                    .foregroundColor(color)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Text(timeText)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .frame(width: 248, height: 248)
    }
}

/// A round tap target with its name underneath, so the icon never has to carry the meaning alone.
private struct DialAction: View {
    let systemImage: String
    let label: String
    let primary: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                action()
            } label: {
                Image(systemName: systemImage)
                    .font(.system(size: primary ? 30 : 22, weight: .semibold))
                    .foregroundColor(primary ? .white : .primary)
                    .frame(width: primary ? 76 : 58, height: primary ? 76 : 58)
                    .background(Circle().fill(primary ? AppColors.primary : AppColors.surface))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }
}

private struct MinutesInputRow: View {
    let label: String
    let minutes: Int
    let onChange: (Int) -> Void

    @State private var text: String = ""

    var body: some View {
        HStack {
            Text("\(label), мин")
            Spacer()
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                .onChange(of: text) { newValue in
                    if let value = Int(newValue), (1...300).contains(value) {
                        onChange(value)
                    }
                }
        }
        .onAppear { text = String(minutes) }
        .onChange(of: minutes) { newValue in
            if Int(text) != newValue {
                text = String(newValue)
            }
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
            .accessibilityLabel("Изменить \(preset.label)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.surface)
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
