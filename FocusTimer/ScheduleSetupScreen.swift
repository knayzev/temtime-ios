import SwiftUI

/// Step two: the day, laid out from the profession preset so the user starts with something usable
/// rather than an empty list. Everything here is editable before the day begins.
struct ScheduleSetupScreen: View {
    let onBack: () -> Void
    let onDone: () -> Void

    @State private var presetName: String
    @State private var hints: [ProfessionPlanItem]
    @State private var items: [PlanItem]
    @State private var showHints = false
    @State private var editing: PlanItem?
    @State private var adding = false

    init(onBack: @escaping () -> Void, onDone: @escaping () -> Void) {
        self.onBack = onBack
        self.onDone = onDone

        let prefs = PrefsManager.shared
        let source = planItemsFor(profession: prefs.profession, details: prefs.professionDetails)
        // Presets carry durations but no clock times, so lay them out back to back, starting an
        // hour after waking — the first hour belongs to getting going, not to planned work.
        var cursor = parseClockMinutes(prefs.wakeTime.isEmpty ? "07:00" : prefs.wakeTime) + 60
        let stamp = Int(Date().timeIntervalSince1970 * 1000)
        var generated: [PlanItem] = []
        for (index, item) in source.enumerated() {
            generated.append(
                PlanItem(
                    id: "planitem_\(stamp)_\(index)",
                    title: item.title,
                    time: minutesToClock(cursor),
                    minutes: item.durationMinutes,
                    comment: ""
                )
            )
            cursor += item.durationMinutes
        }

        _presetName = State(initialValue: presetForProfession(prefs.profession).name)
        _hints = State(initialValue: source.filter { $0.hint != nil })
        _items = State(initialValue: generated)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                StepperHeader(currentStep: 2, labels: ["О себе", "Расписание", "Готово"])
                    .padding(.bottom, 6)

                Text("Ваш день")
                    .font(.title2.bold())
                Text("Собрано под «\(presetName)». Время и длительность можно поменять — нажмите на пункт.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !hints.isEmpty {
                    Button(showHints ? "Скрыть «почему так»" : "Почему так") {
                        showHints.toggle()
                    }
                    .font(.subheadline.weight(.semibold))

                    if showHints {
                        CardView(fill: AppColors.accentSoft) {
                            ForEach(Array(hints.enumerated()), id: \.offset) { _, item in
                                if let hint = item.hint {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(hint.text)
                                            .font(.caption)
                                        if !hint.source.isEmpty {
                                            if let url = URL(string: hint.url), !hint.url.isEmpty {
                                                Link(hint.source, destination: url)
                                                    .font(.caption2)
                                            } else {
                                                Text(hint.source)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 6)
                                }
                            }
                        }
                    }
                }

                DayScheduleView(
                    items: items,
                    doneIds: [],
                    runningId: nil,
                    nowMinutes: -1,
                    onSelect: { editing = $0 },
                    onToggleDone: { _ in },
                    onEdit: { editing = $0 },
                    onAdd: { adding = true },
                    showProgress: false
                )
                .padding(.top, 6)

                Button {
                    let prefs = PrefsManager.shared
                    prefs.planItems = Array(items.sorted { $0.time < $1.time }.prefix(maxPlanItems))
                    prefs.isOnboarded = true
                    onDone()
                } label: {
                    Text("Начать день")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(items.isEmpty)
                .padding(.top, 8)

                if items.isEmpty {
                    Text("Оставьте хотя бы один пункт")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Назад", action: onBack)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .sheet(isPresented: $adding) {
            PlanItemEditor(
                existing: nil,
                defaultTime: minutesToClock(
                    items.map { parseClockMinutes($0.time) + $0.minutes }.max() ?? 12 * 60
                ),
                onSave: { item in
                    items = (items + [item]).sorted { $0.time < $1.time }
                }
            )
        }
        .sheet(item: $editing) { item in
            PlanItemEditor(
                existing: item,
                defaultTime: item.time,
                onSave: { updated in
                    items = items.map { $0.id == updated.id ? updated : $0 }.sorted { $0.time < $1.time }
                },
                onDelete: {
                    items.removeAll { $0.id == item.id }
                }
            )
        }
    }
}
