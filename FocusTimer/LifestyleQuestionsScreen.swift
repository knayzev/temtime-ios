import SwiftUI

struct LifestyleQuestionsScreen: View {
    let onComplete: () -> Void

    @State private var answers: [String: [String]]
    @State private var customTexts: [String: String] = [:]

    @State private var showResult = false
    @State private var regenerateCount = 0
    @State private var scheduleItems: [ScheduleItem] = []
    @State private var showCustomInput = false
    @State private var customSchedule = ""

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
                    }
                }
            }

            Section {
                Button("Сгенерировать график") {
                    PrefsManager.shared.lifestyleAnswers = answers
                    regenerateCount = 0
                    scheduleItems = generateSchedule(
                        answers: answers,
                        wakeTime: PrefsManager.shared.wakeTime,
                        bedTime: PrefsManager.shared.bedTime,
                        breakfastTime: PrefsManager.shared.breakfastTime,
                        lunchTime: PrefsManager.shared.lunchTime,
                        dinnerTime: PrefsManager.shared.dinnerTime,
                        variant: 0
                    )
                    showCustomInput = false
                    showResult = true
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
            }
            .listRowBackground(Color.clear)
        }
    }

    private var resultView: some View {
        Form {
            Section("Предложенный график дня") {
                if showCustomInput {
                    TextEditor(text: $customSchedule)
                        .frame(minHeight: 160)
                } else {
                    ForEach(scheduleItems) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(item.time) — \(item.title)").fontWeight(.medium)
                            ForEach(item.tips, id: \.self) { tip in
                                Text("• \(tip)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section {
                HStack {
                    Button("Ещё варианты (\(3 - regenerateCount))") {
                        regenerateCount += 1
                        scheduleItems = generateSchedule(
                            answers: answers,
                            wakeTime: PrefsManager.shared.wakeTime,
                            bedTime: PrefsManager.shared.bedTime,
                            breakfastTime: PrefsManager.shared.breakfastTime,
                            lunchTime: PrefsManager.shared.lunchTime,
                            dinnerTime: PrefsManager.shared.dinnerTime,
                            variant: regenerateCount
                        )
                        showCustomInput = false
                    }
                    .disabled(regenerateCount >= 3)

                    Spacer()

                    Button(showCustomInput ? "К предложенному" : "Свой вариант") {
                        showCustomInput.toggle()
                    }
                }
            }

            Section {
                Button("Сохранить и продолжить") {
                    let trimmedCustom = customSchedule.trimmingCharacters(in: .whitespacesAndNewlines)
                    if showCustomInput && !trimmedCustom.isEmpty {
                        PrefsManager.shared.daySchedule = customSchedule
                    } else {
                        PrefsManager.shared.daySchedule = scheduleToText(scheduleItems)
                    }
                    PrefsManager.shared.isOnboarded = true
                    onComplete()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)

                Button("Изменить ответы") {
                    showResult = false
                }
                .frame(maxWidth: .infinity)
            }
        }
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
