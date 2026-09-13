import SwiftUI

struct DayPlanScreen: View {
    let onBack: () -> Void

    @State private var tasks: String
    @State private var priority: String
    @State private var dontForget: String
    @State private var updatedAt: TimeInterval
    @State private var justSaved = false

    init(onBack: @escaping () -> Void) {
        self.onBack = onBack
        let saved = PrefsManager.shared.dayPlan
        _tasks = State(initialValue: saved.tasks)
        _priority = State(initialValue: saved.priority)
        _dontForget = State(initialValue: saved.dontForget)
        _updatedAt = State(initialValue: saved.updatedAt)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                    }
                    Text("План на день")
                        .font(.title2.bold())
                }

                if updatedAt > 0 {
                    Text("Сохранено: \(formattedTimestamp(updatedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 28)
                }

                planField(title: "Что нужно сделать", placeholder: "Список задач на сегодня", text: $tasks)
                planField(title: "Что в первую очередь", placeholder: "Самое важное, с чего начать", text: $priority)
                planField(title: "Что не забыть", placeholder: "Мелочи, звонки, напоминания", text: $dontForget)

                HStack {
                    Spacer()
                    if justSaved {
                        Text("Сохранено")
                            .foregroundColor(AppColors.primary)
                    }
                    Button("Сохранить план") {
                        let now = Date().timeIntervalSince1970
                        PrefsManager.shared.dayPlan = DayPlan(
                            tasks: tasks,
                            priority: priority,
                            dontForget: dontForget,
                            updatedAt: now
                        )
                        updatedAt = now
                        justSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            justSaved = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private func planField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                TextEditor(text: text)
                    .frame(minHeight: 100)
                    .padding(4)
                    .scrollContentBackground(.hidden)
            }
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func formattedTimestamp(_ value: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: value))
    }
}
