import SwiftUI

private let weekdayShort = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

private func mondayOfWeek(_ date: Date) -> Date {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date) // 1 = Sunday … 7 = Saturday
    let diff = weekday == 1 ? -6 : 2 - weekday
    return calendar.date(byAdding: .day, value: diff, to: calendar.startOfDay(for: date)) ?? date
}

private func datesBefore(_ anchor: String, count: Int) -> [String] {
    guard var date = dateFromStamp(anchor) else { return [] }
    var result: [String] = []
    for _ in 0..<count {
        date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        result.append(dayStamp(date))
    }
    return result
}

private func greeting(for userName: String) -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    let base: String
    switch hour {
    case ..<5: base = "Доброй ночи"
    case ..<12: base = "Доброе утро"
    case ..<18: base = "Добрый день"
    default: base = "Добрый вечер"
    }
    return userName.isEmpty ? base : "\(base), \(userName)"
}

private func displayDate(_ key: String) -> String {
    guard let date = dateFromStamp(key) else { return key }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ru_RU")
    formatter.dateFormat = "EEEE, d MMMM"
    let text = formatter.string(from: date)
    return text.prefix(1).uppercased() + text.dropFirst()
}

/// Daily rituals grouped by part of the day, with streaks, a week strip to look back, and a chain
/// timer: one timed task runs at a time, and when it ends the next timed task of the same period
/// starts after a short countdown the user can cancel by ticking it.
struct RoutineScreen: View {
    private let prefs = PrefsManager.shared
    private let todayKey: String
    private let previousDates: [String]

    @State private var tasks: [RoutineTask]
    @State private var selectedDate: String
    @State private var completedIds: Set<String>
    @State private var showAddSheet = false
    @State private var taskPendingDelete: RoutineTask?
    @State private var draftSummary: String
    @State private var editingSummary = false

    @State private var runningTaskId: String?
    @State private var endDate: Date?
    @State private var pausedSecondsLeft: Int?
    @State private var secondsLeft = 0
    @State private var pendingNextId: String?
    @State private var pendingStartAt: Date?
    @State private var pendingSeconds = 0

    private static let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    init() {
        let today = dayStamp()
        let prefs = PrefsManager.shared
        todayKey = today
        previousDates = datesBefore(today, count: 60)
        _tasks = State(initialValue: prefs.routineTasks)
        _selectedDate = State(initialValue: today)
        _completedIds = State(initialValue: prefs.completedRoutineIds(date: today))
        _draftSummary = State(initialValue: prefs.daySummary(date: today))
    }

    var body: some View {
        let isToday = selectedDate == todayKey
        let allDone = !tasks.isEmpty && tasks.allSatisfy { completedIds.contains($0.id) }
        let doneCount = tasks.filter { completedIds.contains($0.id) }.count

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting(for: prefs.userName))
                        .font(.title2.bold())
                    Text(displayDate(selectedDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                WeekStrip(todayKey: todayKey, selectedDate: selectedDate) { switchDate($0) }

                if !tasks.isEmpty {
                    CardView(fill: AppColors.primarySoft) {
                        Text("Выполнено \(doneCount) из \(tasks.count)")
                            .font(.headline)
                        ProgressBar(fraction: Double(doneCount) / Double(tasks.count), tint: AppColors.primary, height: 8)
                    }
                }

                ForEach(ritualPeriods, id: \.self) { period in
                    let periodTasks = tasks.filter { $0.period == period }
                    if !periodTasks.isEmpty {
                        periodSection(period: period, periodTasks: periodTasks, isToday: isToday)
                    }
                }

                Button {
                    showAddSheet = true
                } label: {
                    Text("+ Добавить задание")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.primarySoft))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                if allDone {
                    summaryCard
                        .padding(.top, 12)
                }
            }
            .padding(20)
        }
        .onReceive(Self.ticker) { _ in onTick() }
        .sheet(isPresented: $showAddSheet) {
            AddRoutineTaskView(existingIds: Set(tasks.map(\.id))) { task in
                tasks.append(task)
                prefs.routineTasks = tasks
            }
        }
        .alert(
            "Удалить задание?",
            isPresented: Binding(get: { taskPendingDelete != nil }, set: { if !$0 { taskPendingDelete = nil } }),
            presenting: taskPendingDelete
        ) { task in
            Button("Удалить", role: .destructive) {
                tasks.removeAll { $0.id == task.id }
                prefs.routineTasks = tasks
                taskPendingDelete = nil
            }
            Button("Отмена", role: .cancel) { taskPendingDelete = nil }
        } message: { task in
            Text("«\(task.title)» будет убрано из рутины. История выполнения сохранится.")
        }
    }

    @ViewBuilder
    private func periodSection(period: String, periodTasks: [RoutineTask], isToday: Bool) -> some View {
        let periodMinutes = periodTasks.reduce(0) { $0 + $1.durationMinutes }
        let periodDone = periodTasks.filter { completedIds.contains($0.id) }.count
        let nextInPeriod = periodTasks.first { $0.durationMinutes > 0 && !completedIds.contains($0.id) }

        HStack {
            Text("\(ritualPeriodEmoji(period))  \(ritualPeriodTitle(period))")
                .font(.headline)
            Spacer()
            if isToday, let next = nextInPeriod, runningTaskId == nil {
                Button("▶ Запустить") { startTask(next) }
                    .font(.footnote.bold())
                    .padding(.trailing, 6)
            }
            Text("\(periodDone)/\(periodTasks.count)" + (periodMinutes > 0 ? " · \(periodMinutes) мин" : ""))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 10)

        ForEach(periodTasks) { task in
            RoutineRow(
                task: task,
                colorIndex: tasks.firstIndex(where: { $0.id == task.id }) ?? 0,
                isDone: completedIds.contains(task.id),
                streak: prefs.routineStreak(taskId: task.id, today: todayKey, previousDates: previousDates),
                interactive: isToday,
                isRunning: runningTaskId == task.id,
                isPaused: pausedSecondsLeft != nil,
                secondsLeft: runningTaskId == task.id ? secondsLeft : 0,
                startsInSeconds: pendingNextId == task.id ? pendingSeconds : 0,
                onToggle: { toggle(task) },
                onStart: { startTask(task) },
                onPauseToggle: { togglePause() },
                onDelete: { taskPendingDelete = task }
            )
        }
    }

    private var summaryCard: some View {
        let saved = prefs.daySummary(date: selectedDate)
        return CardView(fill: AppColors.tealSoft) {
            Text("🎉 Рутина выполнена — итог дня")
                .font(.headline)
            if !editingSummary && !saved.isEmpty {
                HStack(alignment: .top) {
                    Text(saved)
                    Spacer()
                    Button {
                        draftSummary = saved
                        editingSummary = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Изменить итог")
                }
            } else {
                TextField("Как прошёл день?", text: $draftSummary, axis: .vertical)
                    .lineLimit(2...6)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    if !saved.isEmpty {
                        Button("Отмена") { editingSummary = false }
                    }
                    Button("Сохранить итог") {
                        prefs.setDaySummary(date: selectedDate, text: draftSummary)
                        editingSummary = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                }
            }
        }
    }

    // MARK: Actions

    private func toggle(_ task: RoutineTask) {
        let newDone = !completedIds.contains(task.id)
        // Ticking the running task by hand ends its timer instead of leaving a countdown attached
        // to something already done.
        if newDone && runningTaskId == task.id { stopChain() }
        if pendingNextId == task.id {
            pendingNextId = nil
            pendingStartAt = nil
        }
        // Ticking something off is the reward on this screen, so it gets a confirming tap back.
        if newDone {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        prefs.setRoutineTaskDone(date: selectedDate, taskId: task.id, done: newDone)
        completedIds = prefs.completedRoutineIds(date: selectedDate)
    }

    private func switchDate(_ newDate: String) {
        selectedDate = newDate
        completedIds = prefs.completedRoutineIds(date: newDate)
        draftSummary = prefs.daySummary(date: newDate)
        editingSummary = false
        stopChain()
    }

    private func stopChain() {
        runningTaskId = nil
        endDate = nil
        pausedSecondsLeft = nil
        pendingNextId = nil
        pendingStartAt = nil
    }

    private func startTask(_ task: RoutineTask) {
        guard task.durationMinutes > 0 else { return }
        pendingNextId = nil
        pendingStartAt = nil
        runningTaskId = task.id
        secondsLeft = task.durationMinutes * 60
        endDate = Date().addingTimeInterval(TimeInterval(secondsLeft))
        pausedSecondsLeft = nil
    }

    private func togglePause() {
        if let paused = pausedSecondsLeft {
            endDate = Date().addingTimeInterval(TimeInterval(paused))
            pausedSecondsLeft = nil
        } else if let end = endDate {
            pausedSecondsLeft = max(1, Int(ceil(end.timeIntervalSinceNow)))
            endDate = nil
        }
    }

    private func finishRunningTask() {
        guard let finishedId = runningTaskId else { return }
        prefs.setRoutineTaskDone(date: selectedDate, taskId: finishedId, done: true)
        completedIds = prefs.completedRoutineIds(date: selectedDate)
        runningTaskId = nil
        endDate = nil
        pausedSecondsLeft = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        guard let finished = tasks.first(where: { $0.id == finishedId }) else { return }
        let timed = tasks.filter { $0.period == finished.period && $0.durationMinutes > 0 }
        guard let index = timed.firstIndex(where: { $0.id == finishedId }) else { return }
        if let next = timed[(index + 1)...].first(where: { !completedIds.contains($0.id) }) {
            pendingNextId = next.id
            pendingSeconds = 5
            pendingStartAt = Date().addingTimeInterval(5)
        }
    }

    /// Measured against the clock rather than counted, so the countdown is right after the screen
    /// was locked or the app was in the background.
    private func onTick() {
        if runningTaskId != nil, let end = endDate {
            let remaining = Int(ceil(end.timeIntervalSinceNow))
            if remaining <= 0 {
                finishRunningTask()
            } else if remaining != secondsLeft {
                secondsLeft = remaining
            }
        }
        if let queued = pendingNextId, let at = pendingStartAt {
            let remaining = Int(ceil(at.timeIntervalSinceNow))
            if remaining <= 0 {
                if let task = tasks.first(where: { $0.id == queued }) {
                    startTask(task)
                } else {
                    pendingNextId = nil
                    pendingStartAt = nil
                }
            } else if remaining != pendingSeconds {
                pendingSeconds = remaining
            }
        }
    }
}

private struct WeekStrip: View {
    let todayKey: String
    let selectedDate: String
    let onSelect: (String) -> Void

    var body: some View {
        let monday = mondayOfWeek(Date())
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset, to: monday) ?? monday
                let key = dayStamp(date)
                let isSelected = key == selectedDate
                let isToday = key == todayKey
                Button {
                    onSelect(key)
                } label: {
                    VStack(spacing: 4) {
                        Text(weekdayShort[offset])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.subheadline)
                            .fontWeight(isSelected || isToday ? .bold : .regular)
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(
                                    isSelected ? AppColors.primary : (isToday ? AppColors.primarySoft : Color.clear)
                                )
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct RoutineRow: View {
    let task: RoutineTask
    let colorIndex: Int
    let isDone: Bool
    let streak: Int
    let interactive: Bool
    let isRunning: Bool
    let isPaused: Bool
    let secondsLeft: Int
    let startsInSeconds: Int
    let onToggle: () -> Void
    let onStart: () -> Void
    let onPauseToggle: () -> Void
    let onDelete: () -> Void

    private var iconFill: Color {
        switch colorIndex % 3 {
        case 0: return AppColors.primarySoft
        case 1: return AppColors.coralSoft
        default: return AppColors.tealSoft
        }
    }

    private var detail: String? {
        var parts: [String] = []
        if streak > 0 {
            parts.append("🔥 \(streak) дн. подряд")
        }
        if task.durationMinutes > 0 {
            if isRunning {
                parts.append(formatClock(secondsLeft) + (isPaused ? " · пауза" : ""))
            } else if startsInSeconds > 0 {
                parts.append("старт через \(startsInSeconds)")
            } else {
                parts.append("\(task.durationMinutes) мин")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(task.icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(Circle().fill(iconFill))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .fontWeight(.medium)
                    .strikethrough(isDone)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .fontWeight(isRunning ? .bold : .regular)
                        .foregroundColor(isRunning || startsInSeconds > 0 ? AppColors.primary : .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if interactive { onToggle() }
            }

            // Timer control only makes sense for tasks that carry a duration; a 0-minute task like
            // "Отбой" is just a checkbox.
            if task.durationMinutes > 0 && !isDone && interactive {
                Button {
                    if isRunning { onPauseToggle() } else { onStart() }
                } label: {
                    Image(systemName: isRunning && !isPaused ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isRunning ? .white : .primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(isRunning ? AppColors.primary : AppColors.surface))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRunning ? "Пауза" : "Запустить таймер")
            }

            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isDone ? AppColors.primary : Color.clear)
                    Circle()
                        .stroke(isDone ? AppColors.primary : Color.secondary.opacity(0.5), lineWidth: 2)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(!interactive)
            .accessibilityLabel(isDone ? "Готово" : "Отметить")
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppColors.surface))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Удалить из рутины", systemImage: "trash")
            }
        }
    }
}

private struct AddRoutineTaskView: View {
    let existingIds: Set<String>
    let onAdd: (RoutineTask) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mode = 0
    @State private var customTitle = ""
    @State private var customDuration = ""
    @State private var customPeriod = ritualMorning

    var body: some View {
        let available = routineTaskLibrary.filter { !existingIds.contains($0.id) }
        NavigationStack {
            Form {
                Picker("", selection: $mode) {
                    Text("Готовые").tag(0)
                    Text("Своё").tag(1)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if mode == 0 {
                    if available.isEmpty {
                        Text("Все готовые задания уже добавлены")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(ritualPeriods, id: \.self) { period in
                            let inPeriod = available.filter { $0.period == period }
                            if !inPeriod.isEmpty {
                                Section("\(ritualPeriodEmoji(period)) \(ritualPeriodTitle(period))") {
                                    ForEach(inPeriod) { task in
                                        Button {
                                            onAdd(task)
                                            dismiss()
                                        } label: {
                                            HStack {
                                                Text(task.icon)
                                                Text(task.title).foregroundColor(.primary)
                                                Spacer()
                                                if task.durationMinutes > 0 {
                                                    Text("\(task.durationMinutes) мин")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        TextField("Название задания", text: $customTitle)
                        TextField("Минут (необязательно)", text: $customDuration)
                            .keyboardType(.numberPad)
                        Picker("Когда", selection: $customPeriod) {
                            ForEach(ritualPeriods, id: \.self) { period in
                                Text(ritualPeriodTitle(period)).tag(period)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Новое задание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                if mode == 1 {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Добавить") {
                            let title = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !title.isEmpty else { return }
                            onAdd(
                                RoutineTask(
                                    id: "routine_custom_\(Int(Date().timeIntervalSince1970 * 1000))",
                                    title: title,
                                    icon: "✅",
                                    durationMinutes: Int(customDuration) ?? 0,
                                    period: customPeriod
                                )
                            )
                            dismiss()
                        }
                        .disabled(customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}
