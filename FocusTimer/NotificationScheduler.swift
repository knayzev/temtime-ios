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

    /// The "Я тут" button on a phase-change notice: answers it without opening the app.
    static let acknowledgeAction = "epv.timer.ack"
    /// Which of the scheduled phase changes a notice belongs to.
    static let slotKey = "slot"

    private static let prefix = "epv.timer."
    private static let phaseCategory = "epv.timer.phase"

    private static var allIds: [String] {
        (0..<slots).flatMap { ["\(prefix)phase.\($0)", "\(prefix)late.\($0)", "\(prefix)soon.\($0)"] }
    }

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Declares the "Я тут" button. Called once at launch, before any notice can arrive.
    static func registerActions() {
        let acknowledge = UNNotificationAction(identifier: acknowledgeAction, title: "Я тут", options: [])
        let category = UNNotificationCategory(
            identifier: phaseCategory,
            actions: [acknowledge],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIds)
    }

    static func clearDelivered() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: allIds)
    }

    /// Drops the "window missed" reminder for one phase change that has been answered.
    static func cancelLateNotice(slot: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(prefix)late.\(slot)"]
        )
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
                body: "Откройте приложение или нажмите «Я тут» — иначе через минуту придёт напоминание",
                sound: sound,
                slot: index
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

    /// `slot` marks a phase-change notice: it gets the "Я тут" button and remembers which reminder
    /// that button should cancel.
    private static func add(id: String, at date: Date, title: String, body: String, sound: Bool, slot: Int? = nil) {
        let interval = date.timeIntervalSinceNow
        guard interval > 0.5 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound {
            content.sound = .default
        }
        if let slot {
            content.categoryIdentifier = phaseCategory
            content.userInfo = [slotKey: slot]
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }
}

/// Receives what the user does with a notification. Kept free of any actor: the system calls it
/// on a thread of its own choosing, and everything it touches is safe from any thread.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Both methods are pinned to their Objective-C selectors, so the system finds them whatever
    // annotations an SDK adds to the Swift view of the protocol.
    @objc(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // "Я тут" answers the phase change without opening the app, so its reminder is dropped.
        // Tapping the notice itself opens the app, which clears everything on becoming active.
        if response.actionIdentifier == NotificationScheduler.acknowledgeAction,
           let slot = response.notification.request.content.userInfo[NotificationScheduler.slotKey] as? Int {
            NotificationScheduler.cancelLateNotice(slot: slot)
        }
        completionHandler()
    }

    @objc(userNotificationCenter:willPresentNotification:withCompletionHandler:)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // With the app on screen the timer rings and speaks for itself.
        completionHandler([])
    }
}
