import Foundation
import UserNotifications

/// Local notifications that stand in for the running app: iOS suspends it soon after it leaves
/// the screen, so every upcoming phase change is handed to the system ahead of time.
///
/// Each kind of notice has a fixed set of identifiers. Re-adding an identifier replaces the old
/// request, so rescheduling never piles up duplicates and cancelling is a single call.
enum NotificationScheduler {
    /// How many upcoming phase changes are scheduled at once — three notices each, well under the
    /// system limit of 64 pending requests.
    static let slots = 8

    private static let prefix = "epv.timer."

    private static var allIds: [String] {
        (0..<slots).flatMap { ["\(prefix)phase.\($0)", "\(prefix)late.\($0)", "\(prefix)soon.\($0)"] }
    }

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIds)
    }

    static func clearDelivered() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: allIds)
    }

    static func schedule(
        transitions: [PhaseTransition],
        sound: Bool,
        headsUpLead: Int,
        english: Bool,
        grace: TimeInterval
    ) {
        cancelAll()
        let now = Date()
        for (index, transition) in transitions.prefix(slots).enumerated() {
            let startedTitle = transition.nextPhase == .work
                ? "Работа началась: \(transition.nextLabel)"
                : "Отдых начался"
            add(
                id: "\(prefix)phase.\(index)",
                at: transition.at,
                title: startedTitle,
                body: "Откройте приложение — иначе через минуту придёт напоминание",
                sound: sound
            )

            let phaseName = transition.nextPhase == .work ? "Работа" : "Отдых"
            add(
                id: "\(prefix)late.\(index)",
                at: transition.at.addingTimeInterval(grace),
                title: "Окно «\(phaseName)» пропущено!",
                body: "Вы не отреагировали вовремя. Нажмите, чтобы открыть таймер.",
                sound: sound
            )

            if headsUpLead > 0 {
                let soon = transition.at.addingTimeInterval(-TimeInterval(headsUpLead))
                if soon > now {
                    let title: String
                    if english {
                        title = transition.endedPhase == .work ? "Rest time is approaching" : "Work time is approaching"
                    } else {
                        title = transition.endedPhase == .work ? "Приближается время отдыха" : "Приближается время работы"
                    }
                    add(
                        id: "\(prefix)soon.\(index)",
                        at: soon,
                        title: title,
                        body: english ? "In \(leadText(headsUpLead, english: true))" : "Через \(leadText(headsUpLead, english: false))",
                        sound: sound
                    )
                }
            }
        }
    }

    private static func leadText(_ seconds: Int, english: Bool) -> String {
        if seconds >= 60 && seconds % 60 == 0 {
            return english ? "\(seconds / 60) min" : "\(seconds / 60) мин"
        }
        return english ? "\(seconds) s" : "\(seconds) сек"
    }

    private static func add(id: String, at date: Date, title: String, body: String, sound: Bool) {
        let interval = date.timeIntervalSinceNow
        guard interval > 0.5 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound {
            content.sound = .default
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }
}
