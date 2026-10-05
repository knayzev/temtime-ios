import SwiftUI

/// The day's schedule as a list. Used both on the timer screen and during setup, so it takes every
/// action as a callback and owns no state of its own.
struct DayScheduleView: View {
    let items: [PlanItem]
    let doneIds: Set<String>
    let runningId: String?
    /// Minutes since midnight, for marking entries whose time has passed; negative turns it off.
    let nowMinutes: Int
    let onSelect: (PlanItem) -> Void
    let onToggleDone: (PlanItem) -> Void
    let onEdit: (PlanItem) -> Void
    let onAdd: () -> Void
    var showProgress: Bool = true

    var body: some View {
        let doneCount = items.filter { doneIds.contains($0.id) }.count
        let totalMinutes = items.reduce(0) { $0 + $1.minutes }
        let doneMinutes = items.filter { doneIds.contains($0.id) }.reduce(0) { $0 + $1.minutes }
        let nextId = items.first { !doneIds.contains($0.id) }?.id

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .lastTextBaseline) {
                Text("Сегодня").font(.headline)
                Spacer()
                Text("\(doneCount)/\(items.count) · \(formatSpan(doneMinutes)) из \(formatSpan(totalMinutes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if showProgress && !items.isEmpty {
                ProgressBar(fraction: Double(doneCount) / Double(items.count))
                    .padding(.top, 2)
                    .padding(.bottom, 6)
            }

            if items.isEmpty {
                CardView {
                    Text("План на день пуст").font(.subheadline.bold())
                    Text("Добавьте первый пункт — он появится здесь и запустится в таймере.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(items) { item in
                    let isDone = doneIds.contains(item.id)
                    let isRunning = runningId == item.id
                    PlanItemRow(
                        item: item,
                        isDone: isDone,
                        isRunning: isRunning,
                        isNext: nextId == item.id && !isRunning,
                        isLate: nowMinutes >= 0 && !isDone && !isRunning
                            && parseClockMinutes(item.time) + item.minutes < nowMinutes,
                        onSelect: { onSelect(item) },
                        onToggleDone: { onToggleDone(item) },
                        onEdit: { onEdit(item) }
                    )
                }
            }

            Button(action: onAdd) {
                Label("Добавить занятие", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.primary)
            .padding(.top, 6)
        }
    }
}

private struct PlanItemRow: View {
    let item: PlanItem
    let isDone: Bool
    let isRunning: Bool
    let isNext: Bool
    let isLate: Bool
    let onSelect: () -> Void
    let onToggleDone: () -> Void
    let onEdit: () -> Void

    private var background: Color {
        if isRunning { return AppColors.primarySoft }
        if isDone { return AppColors.surface.opacity(0.6) }
        return AppColors.surface
    }

    private var subtitle: String {
        var text = "\(item.minutes) мин"
        if !item.comment.isEmpty { text += " · \(item.comment)" }
        if isLate { text += " · просрочено" }
        return text
    }

    var body: some View {
        HStack(spacing: 10) {
            // A circle rather than a checkbox: the title is the tap target for the timer, and this
            // one tap must not be mistaken for it.
            Button(action: onToggleDone) {
                ZStack {
                    Circle()
                        .fill(isDone ? AppColors.restColor : Color(UIColor.systemBackground))
                    Circle()
                        .stroke(isDone ? AppColors.restColor : Color.secondary.opacity(0.4), lineWidth: 2)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDone ? "Снять отметку" : "Отметить сделанным")

            Text(item.time)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(isDone ? .secondary : AppColors.primary)
                .frame(width: 46, alignment: .leading)

            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.body)
                            .strikethrough(isDone)
                            .foregroundColor(isDone ? .secondary : .primary)
                            .multilineTextAlignment(.leading)
                        if isNext {
                            Text("дальше")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(RoundedRectangle(cornerRadius: 5).fill(AppColors.primary))
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isLate ? AppColors.secondary : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Загрузить в таймер")

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Изменить")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(background))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isRunning ? AppColors.primary : Color.clear, lineWidth: 1.5)
        )
    }
}

/// Add or edit one entry. `existing` nil means a new one, and only then are the quick fills
/// offered — they would overwrite what the user already typed otherwise.
struct PlanItemEditor: View {
    let existing: PlanItem?
    let onSave: (PlanItem) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var time: String
    @State private var minutes: String
    @State private var comment: String

    init(existing: PlanItem?, defaultTime: String, onSave: @escaping (PlanItem) -> Void, onDelete: (() -> Void)? = nil) {
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: existing?.title ?? "")
        _time = State(initialValue: existing?.time ?? defaultTime)
        _minutes = State(initialValue: String(existing?.minutes ?? 30))
        _comment = State(initialValue: existing?.comment ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                if existing == nil {
                    Section("Быстрый выбор") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(planQuickFillTitles, id: \.self) { name in
                                    if let entry = planTaskLibrary.first(where: { $0.title == name }) {
                                        Button {
                                            title = entry.title
                                            time = entry.time
                                            minutes = String(entry.minutes)
                                        } label: {
                                            Text(entry.title)
                                                .font(.footnote)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Capsule().fill(AppColors.primarySoft))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section {
                    TextField("Название", text: $title)
                    ClockPicker(label: "Время", time: $time)
                    HStack {
                        Text("Длительность, мин")
                        Spacer()
                        TextField("30", text: $minutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: minutes) { newValue in
                                let digits = String(newValue.filter { $0.isNumber }.prefix(3))
                                if digits != newValue { minutes = digits }
                            }
                    }
                    TextField("Комментарий", text: $comment)
                }

                if let onDelete {
                    Section {
                        Button("Удалить", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "Новое занятие" : "Изменить занятие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else { return }
                        onSave(
                            PlanItem(
                                id: existing?.id ?? "planitem_\(Int(Date().timeIntervalSince1970 * 1000))",
                                title: clean,
                                time: time,
                                minutes: max(1, Int(minutes) ?? 30),
                                comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
