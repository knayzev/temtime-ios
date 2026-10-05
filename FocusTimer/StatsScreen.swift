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

/// A productivity window, compared against the minute of the day a session started at.
private struct FocusWindow {
    let label: String
    let start: String
    let end: String

    func contains(_ minuteOfDay: Int) -> Bool {
        minuteOfDay >= parseClockMinutes(start) && minuteOfDay < parseClockMinutes(end)
    }
}

private struct WindowStats: Identifiable {
    let window: FocusWindow
    let today: Int
    let week: Int
    let month: Int
    var id: String { window.label }
}

struct StatsScreen: View {
    @State private var history: [SessionRecord] = PrefsManager.shared.history
    @State private var todaySteps: Int?

    private var workEntries: [SessionRecord] { history.filter { $0.phase == "WORK" } }

    private var todayStart: TimeInterval { Self.startOfDay(Date()) }
    private var weekStart: TimeInterval { todayStart - 6 * Self.dayInterval }
    private var monthStart: TimeInterval {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return (calendar.date(from: components) ?? Date()).timeIntervalSince1970
    }

    private func seconds(_ entries: [SessionRecord], since start: TimeInterval) -> Int {
        entries.filter { $0.startTime >= start }.reduce(0) { $0 + $1.durationSeconds }
    }

    private var completedCount: Int { workEntries.filter { !$0.interrupted }.count }
    private var streak: Int { Self.computeStreak(workEntries) }

    /// Two productivity windows, classified by when a session started.
    private var windows: [FocusWindow] {
        let prefs = PrefsManager.shared
        return [
            FocusWindow(label: "Первая половина", start: prefs.focusWindowOneStart, end: prefs.focusWindowOneEnd),
            FocusWindow(label: "Вторая половина", start: prefs.focusWindowTwoStart, end: prefs.focusWindowTwoEnd)
        ]
    }

    private var windowStats: [WindowStats] {
        windows.map { window in
            let inWindow = workEntries.filter { window.contains(Self.minuteOfDay($0.startTime)) }
            return WindowStats(
                window: window,
                today: seconds(inWindow, since: todayStart),
                week: seconds(inWindow, since: weekStart),
                month: seconds(inWindow, since: monthStart)
            )
        }
    }

    private var outsideMonth: Int {
        let all = windows
        return workEntries
            .filter { $0.startTime >= monthStart }
            .filter { entry in !all.contains { $0.contains(Self.minuteOfDay(entry.startTime)) } }
            .reduce(0) { $0 + $1.durationSeconds }
    }

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
            [3, 7, 30, 100].map { Achievement(label: "Стрик \($0) \(daysWord($0))", current: streak, target: $0) }
    }

    var body: some View {
        let work = workEntries
        let breakdown = categoryBreakdown

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // The three totals people actually come here for, big enough to read at a glance.
                HStack(spacing: 12) {
                    HeadlineStat(label: "Сегодня", value: Self.formatDuration(seconds(work, since: todayStart)))
                    HeadlineStat(label: "Неделя", value: Self.formatDuration(seconds(work, since: weekStart)))
                    HeadlineStat(label: "Месяц", value: Self.formatDuration(seconds(work, since: monthStart)))
                }

                StatsCard(title: "Сессии") {
                    StatRow(label: "Завершено", value: "\(completedCount) из \(work.count)")
                    StatRow(label: "Текущий стрик", value: "\(streak) \(daysWord(streak))")
                    if PrefsManager.shared.stepsEnabled {
                        StatRow(label: "Шаги сегодня", value: todaySteps.map { "\($0)" } ?? "…")
                    }
                }

                StatsCard(title: "Окна продуктивности", subtitle: "Сегодня · неделя · месяц") {
                    ForEach(windowStats) { stats in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(stats.window.label) · \(stats.window.start)–\(stats.window.end)")
                                .font(.subheadline.weight(.medium))
                            Text(
                                Self.formatDuration(stats.today) + "  ·  "
                                    + Self.formatDuration(stats.week) + "  ·  "
                                    + Self.formatDuration(stats.month)
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    if outsideMonth > 0 {
                        StatRow(label: "Вне окон, за месяц", value: Self.formatDuration(outsideMonth))
                    }
                }

                if !breakdown.isEmpty {
                    StatsCard(title: "По категориям") {
                        let largest = max(1, breakdown[0].seconds)
                        ForEach(breakdown, id: \.category) { item in
                            // A category's share of the busiest one, so the split is visible
                            // without reading the numbers.
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.category).font(.subheadline)
                                    Spacer()
                                    Text(Self.formatDuration(item.seconds))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                ProgressBar(fraction: Double(item.seconds) / Double(largest), tint: AppColors.primary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                StatsCard(title: "Достижения") {
                    ForEach(achievements) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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

    private static func minuteOfDay(_ timestamp: TimeInterval) -> Int {
        nowMinutesOfDay(Date(timeIntervalSince1970: timestamp))
    }

    private static func computeStreak(_ workEntries: [SessionRecord]) -> Int {
        let completedDays = Set(
            workEntries.filter { !$0.interrupted }.map { startOfDay(Date(timeIntervalSince1970: $0.startTime)) }
        )
        var streak = 0
        var cursor = Date()
        while completedDays.contains(startOfDay(cursor)) {
            streak += 1
            // Stepping by calendar day keeps the count right across a clock change.
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor.addingTimeInterval(-dayInterval)
        }
        return streak
    }

    private static func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return hours > 0 ? "\(hours) ч \(minutes) мин" : "\(minutes) мин"
    }
}

/// One of the three big totals across the top.
private struct HeadlineStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(AppColors.primarySoft))
    }
}

/// Groups related rows so the screen reads as sections rather than one long list.
private struct StatsCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(AppColors.surface))
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
                .foregroundColor(achievement.unlocked ? AppColors.restColor : .secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.label)
                ProgressView(value: achievement.progress)
            }
        }
        .padding(.vertical, 4)
    }
}
