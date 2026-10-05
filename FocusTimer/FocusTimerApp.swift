import SwiftUI
import UserNotifications

@main
struct FocusTimerApp: App {
    init() {
        // Set before launch finishes, so a tap on a notification that started the app is not lost.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationScheduler.registerActions()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
