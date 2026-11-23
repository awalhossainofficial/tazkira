import AppKit

/// Lives as long as the app, so it never removes its observers.
@MainActor
final class SystemEvents {
    enum Event { case sleep, wake, lock, unlock }

    private var observers: [NSObjectProtocol] = []

    init(onEvent: @escaping @MainActor (Event) -> Void) {
        let workspace = NSWorkspace.shared.notificationCenter
        let distributed = DistributedNotificationCenter.default()
        let sources: [(NotificationCenter, Notification.Name, Event)] = [
            (workspace, NSWorkspace.willSleepNotification, .sleep),
            (workspace, NSWorkspace.didWakeNotification, .wake),
            (distributed, Notification.Name("com.apple.screenIsLocked"), .lock),
            (distributed, Notification.Name("com.apple.screenIsUnlocked"), .unlock),
        ]
        for (center, name, event) in sources {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { onEvent(event) }
            }
            observers.append(token)
        }
    }
}
