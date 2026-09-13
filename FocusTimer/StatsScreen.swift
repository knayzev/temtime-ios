import SwiftUI
import CoreMotion

private struct Achievement: Identifiable {
    let label: String
    let current: Int
    let target: Int
    var id: String { label }
    var unlocked: Bool { current >= target }
    var progress: Double { min(1.0, Double(current) / Double(target)) }
}

struct StatsScreen: View {
    @State private var history: [SessionRecord] = PrefsManager.shared.history
    @State private var todaySteps: Int?

    private var workEntries: [SessionRecord] { history.filter { $0.phase == "WORK" } }

    private var todayStart: TimeInterval { Self.startOfDay(Date()) }
    private var weekStart: TimeInterval { todayStart - 6 * Self.dayInterval }

    private var todaySeconds: Int {
        workEntries.filter { $0.startTime >= todayStart }.reduce(0) { $0 + $1.durationSeconds }
    }
    private var weekSeconds: Int {
        workEntries.filter { $0.startTime >= weekStart }.reduce(0) { $0 + $1.durationSeconds }
    }
    private var completedCount: Int { workEntries.filter { !$0.interrupted }.count }
    private var totalCount: Int { workEntries.count }
    private var streak: Int { Self.computeStreak(workEntries) }

    private var categoryBreakdown: [(category: String, seconds: Int)] {
        var totals: [String: Int] = [:]
        for entry in workEntries {
            let key = entry.category.isEmpty ? "Без категории" : entry.category
            totals[key, default: 0] += entry.durationSeconds
        }
        return totals.map { (category: $0.key, seconds: $0.value) }.sorted { $0.seconds > $1.seconds }
    }

    private var achievements: [Achievement] {
        [1, 10, 50, 100, 500].map { Achievement(label: "\($0) завершённых сессий", current: completedCount, target: $0) } +
            [3, 7, 30, 100].map { Achievement(label: "Стрик \($0) \(Self.daysWord($0))", current: streak, target: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Статистика")
                    .font(.title.bold())

                StatRow(label: "Сегодня", value: Self.formatDuration(todaySeconds))
                StatRow(label: "За неделю", value: Self.formatDuration(weekSeconds))
                StatRow(label: "Завершено сессий", value: "\(completedCount) из \(totalCount)")
                StatRow(label: "Текущий стрик", value: "\(streak) \(Self.daysWord(streak))")
                if PrefsManager.shared.stepsEnabled {
                    StatRow(label: "Шаги сегодня", value: todaySteps.map { "\($0)" } ?? "…")
                }

                if !categoryBreakdown.isEmpty {
                    Divider()
                    Text("По категориям").font(.headline)
                    ForEach(categoryBreakdown, id: \.category) { item in
                        StatRow(label: item.category, value: Self.formatDuration(item.seconds))
                    }
                }

                Divider()
                Text("Достижения").font(.headline)
                ForEach(achievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
            .padding(24)
        }
        .onAppear {
            history = PrefsManager.shared.history
            if PrefsManager.shared.stepsEnabled, CMPedometer.isStepCountingAvailable() {
                let startOfDay = Calendar.current.startOfDay(for: Date())
                CMPedometer().queryPedometerData(from: startOfDay, to: Date()) { data, _ in
                    guard let data else { return }
                    DispatchQueue.main.async {
                        todaySteps = data.numberOfSteps.intValue
                    }
                }
            }
        }
    }

    private static let dayInterval: TimeInterval = 24 * 60 * 60

    private static func startOfDay(_ date: Date) -> TimeInterval {
        Calendar.current.startOfDay(for: date).timeIntervalSince1970
    }

    private static func computeStreak(_ workEntries: [SessionRecord]) -> Int {
        let completedDays = Set(
            workEntries.filter { !$0.interrupted }.map { startOfDay(Date(timeIntervalSince1970: $0.startTime)) }
        )
        var streak = 0
        var cursor = startOfDay(Date())
        while completedDays.contains(cursor) {
            streak += 1
            cursor -= dayInterval
        }
        return streak
    }

    private static func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return hours > 0 ? "\(hours) ч \(minutes) мин" : "\(minutes) мин"
    }

    private static func daysWord(_ n: Int) -> String {
        let mod100 = n % 100
        let mod10 = n % 10
        if (11...14).contains(mod100) { return "дней" }
        switch mod10 {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

private struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: achievement.unlocked ? "checkmark.circle.fill" : "lock.fill")
                .foregroundColor(achievement.unlocked ? .green : .secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.label)
                ProgressView(value: achievement.progress)
            }
        }
        .padding(.vertical, 4)
    }
}
