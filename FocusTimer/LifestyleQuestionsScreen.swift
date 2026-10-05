import SwiftUI

/// How many schedule variants can be generated and compared.
private let maxScheduleVariants = 4

/// Questions about sleep and mornings, turned into a day schedule. Up to four variants can be
/// generated, compared side by side, and the chosen one adjusted before it is saved.
struct LifestyleQuestionsScreen: View {
    let onComplete: () -> Void

    @State private var answers: [String: [String]]
    @State private var customTexts: [String: String] = [:]

    @State private var showResult = false
    @State private var variants: [[ScheduleItem]] = []
    @State private var selectedIndex = 0
    @State private var editedItems: [ScheduleItem] = []
    @State private var showCompare = false

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        let stored = PrefsManager.shared.lifestyleAnswers
        var initial: [String: [String]] = [:]
        for question in lifestyleQuestions {
            initial[question.id] = stored[question.id] ?? []
        }
        _answers = State(initialValue: initial)
    }

    var body: some View {
        if !showResult {
            questionsView
        } else {
            resultView
        }
    }

    private var questionsView: some View {
        Form {
            Section {
                Text("Немного о вашем режиме").font(.title2.bold())
                Text("Это поможет предложить подходящий график дня")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color.clear)

            ForEach(lifestyleQuestions) { question in
                Section(question.question) {
                    ForEach(question.options, id: \.self) { option in
                        let selected = answers[question.id]?.contains(option) ?? false
                        Button {
                            toggle(option, for: question.id)
                        } label: {
                            HStack {
                                Text(option).foregroundColor(.primary)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark").foregroundColor(AppColors.primary)
                                }
                            }
                        }
                    }

                    ForEach((answers[question.id] ?? []).filter { !question.options.contains($0) }, id: \.self) { custom in
                        HStack {
                            Text("• \(custom)")
                            Spacer()
                            Button {
                                answers[question.id]?.removeAll { $0 == custom }
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        TextField("Свой вариант", text: Binding(
                            get: { customTexts[question.id] ?? "" },
                            set: { customTexts[question.id] = $0 }
                        ))
                        Button("Добавить") {
                            let trimmed = (customTexts[question.id] ?? "").trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                var current = answers[question.id] ?? []
                                if !current.contains(trimmed) {
                                    current.append(trimmed)
                                    answers[question.id] = current
                                }
                            }
                            customTexts[question.id] = ""
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section {
                Button {
                    PrefsManager.shared.lifestyleAnswers = answers
                    let first = makeVariant(0)
                    variants = [first]
                    selectedIndex = 0
                    editedItems = first
                    showCompare = false
                    showResult = true
                } label: {
                    Text("Сгенерировать график")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .listRowBackground(Color.clear)
        }
    }

    private var resultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("График дня №\(selectedIndex + 1)")
                    .font(.title3.bold())

                HStack(spacing: 8) {
                    Button {
                        selectVariant(selectedIndex - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(selectedIndex == 0)
                    .accessibilityLabel("Предыдущий график")

                    ForEach(variants.indices, id: \.self) { index in
                        Button {
                            selectVariant(index)
                        } label: {
                            Text("\(index + 1)")
                                .font(.subheadline.bold())
                                .foregroundColor(index == selectedIndex ? AppColors.onPrimary : .primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle().fill(index == selectedIndex ? AppColors.primary : AppColors.surface)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        selectVariant(selectedIndex + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(selectedIndex >= variants.count - 1)
                    .accessibilityLabel("Следующий график")
                }

                if showCompare && variants.count > 1 {
                    ScheduleCompareTable(variants: variants)
                } else {
                    Text("Подстройте время под себя — остальное менять не обязательно")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach($editedItems) { $item in
                        HStack(alignment: .top, spacing: 12) {
                            ClockPicker(label: "", time: $item.time)
                                .labelsHidden()
                                .frame(width: 90, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).fontWeight(.medium)
                                ForEach(item.tips, id: \.self) { tip in
                                    Text("• \(tip)")
                                        .font(.caption)
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Ещё графики (\(maxScheduleVariants - variants.count))") {
                        let next = makeVariant(variants.count)
                        variants.append(next)
                        selectVariant(variants.count - 1)
                        showCompare = false
                    }
                    .buttonStyle(.bordered)
                    .disabled(variants.count >= maxScheduleVariants)

                    Button(showCompare ? "К графику" : "Сравнить графики") {
                        showCompare.toggle()
                    }
                    .buttonStyle(.bordered)
                    .disabled(variants.count < 2)
                }
                .font(.subheadline)

                Button {
                    PrefsManager.shared.daySchedule = scheduleToText(editedItems)
                    onComplete()
                } label: {
                    Text("Сохранить график")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Изменить ответы") {
                    showResult = false
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
    }

    private func makeVariant(_ variant: Int) -> [ScheduleItem] {
        let prefs = PrefsManager.shared
        return generateSchedule(
            answers: answers,
            wakeTime: prefs.wakeTime,
            bedTime: prefs.bedTime,
            breakfastTime: prefs.breakfastTime,
            lunchTime: prefs.lunchTime,
            dinnerTime: prefs.dinnerTime,
            variant: variant
        )
    }

    private func selectVariant(_ index: Int) {
        guard variants.indices.contains(index) else { return }
        selectedIndex = index
        editedItems = variants[index]
    }

    private func toggle(_ option: String, for questionId: String) {
        var current = answers[questionId] ?? []
        if let idx = current.firstIndex(of: option) {
            current.remove(at: idx)
        } else {
            current.append(option)
        }
        answers[questionId] = current
    }
}

/// The variants side by side: one row per block of the day, one column of times per variant.
private struct ScheduleCompareTable: View {
    let variants: [[ScheduleItem]]

    var body: some View {
        let rowCount = variants.first?.count ?? 0
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    Text("").frame(width: 150, alignment: .leading)
                    ForEach(variants.indices, id: \.self) { index in
                        Text("№\(index + 1)")
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.primary)
                            .frame(width: 64, alignment: .leading)
                    }
                }
                Divider()
                ForEach(0..<rowCount, id: \.self) { row in
                    HStack(alignment: .top, spacing: 0) {
                        Text(variants[0][row].title)
                            .font(.subheadline)
                            .frame(width: 150, alignment: .leading)
                        ForEach(variants.indices, id: \.self) { index in
                            Text(row < variants[index].count ? variants[index][row].time : "—")
                                .font(.subheadline)
                                .monospacedDigit()
                                .frame(width: 64, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}
