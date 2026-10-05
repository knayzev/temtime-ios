import SwiftUI

// MARK: - Clock helpers

/// "HH:MM" as minutes since midnight.
func parseClockMinutes(_ text: String) -> Int {
    let parts = text.split(separator: ":")
    let hour = parts.count > 0 ? Int(parts[0].trimmingCharacters(in: .whitespaces)) ?? 0 : 0
    let minute = parts.count > 1 ? Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0 : 0
    return hour * 60 + minute
}

func minutesToClock(_ total: Int) -> String {
    let clamped = min(max(total, 0), 23 * 60 + 59)
    return String(format: "%02d:%02d", clamped / 60, clamped % 60)
}

func formatSpan(_ totalMinutes: Int) -> String {
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 {
        return minutes > 0 ? "\(hours) ч \(minutes) мин" : "\(hours) ч"
    }
    return "\(minutes) мин"
}

func formatClock(_ totalSeconds: Int) -> String {
    let safe = max(0, totalSeconds)
    return String(format: "%02d:%02d", safe / 60, safe % 60)
}

/// A day as "yyyy-MM-dd", the key per-day completions are stored under.
func dayStamp(_ date: Date = Date()) -> String {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
}

func dateFromStamp(_ stamp: String) -> Date? {
    let parts = stamp.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
}

func nowMinutesOfDay(_ date: Date = Date()) -> Int {
    let c = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (c.hour ?? 0) * 60 + (c.minute ?? 0)
}

/// Today's date carrying the given "HH:MM", for binding a clock string to a DatePicker.
func clockDate(_ text: String) -> Date {
    let total = parseClockMinutes(text)
    return Calendar.current.date(
        bySettingHour: total / 60 % 24, minute: total % 60, second: 0, of: Date()
    ) ?? Date()
}

func clockString(_ date: Date) -> String {
    let c = Calendar.current.dateComponents([.hour, .minute], from: date)
    return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
}

func daysWord(_ n: Int) -> String {
    let mod100 = n % 100
    let mod10 = n % 10
    if (11...14).contains(mod100) { return "дней" }
    switch mod10 {
    case 1: return "день"
    case 2, 3, 4: return "дня"
    default: return "дней"
    }
}

// MARK: - Small views

/// A labelled hour-and-minute picker that reads and writes a "HH:MM" string.
struct ClockPicker: View {
    let label: String
    @Binding var time: String

    var body: some View {
        DatePicker(
            label,
            selection: Binding(get: { clockDate(time) }, set: { time = clockString($0) }),
            displayedComponents: .hourAndMinute
        )
        .environment(\.locale, Locale(identifier: "ru_RU"))
    }
}

/// A rounded tinted block that groups related content.
struct CardView<Content: View>: View {
    var fill: Color = AppColors.surface
    var padding: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(fill))
    }
}

/// A thin rounded progress bar; `fraction` is clamped to 0...1.
struct ProgressBar: View {
    let fraction: Double
    var tint: Color = AppColors.restColor
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.18))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * CGFloat(min(max(fraction, 0), 1)))
            }
        }
        .frame(height: height)
    }
}

/// A modern connected-circle progress stepper for the post-registration setup flow.
struct StepperHeader: View {
    let currentStep: Int
    let labels: [String]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(labels.enumerated()), id: \.offset) { index, _ in
                    let step = index + 1
                    if index > 0 {
                        Rectangle()
                            .fill(step <= currentStep ? AppColors.primary : Color.secondary.opacity(0.25))
                            .frame(height: 2)
                    }
                    ZStack {
                        Circle()
                            .fill(step <= currentStep ? AppColors.primary : Color.secondary.opacity(0.18))
                            .frame(width: 30, height: 30)
                        if step < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(step == currentStep ? .white : .secondary)
                        }
                    }
                }
            }
            HStack {
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.caption2)
                        .fontWeight(index + 1 == currentStep ? .bold : .regular)
                        .foregroundColor(index + 1 == currentStep ? AppColors.primary : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// A soft gradient-tinted circle with a large emoji glyph — a lightweight illustration stand-in.
struct HeroGlyph: View {
    let emoji: String
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.primary.opacity(0.18), AppColors.restColor.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(emoji).font(.system(size: size * 0.42))
        }
        .frame(width: size, height: size)
    }
}
