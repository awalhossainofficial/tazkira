import AppKit
import ZikrCore

@MainActor
final class AppController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let scheduler = Scheduler(list: BuiltInList.all, state: StateStore.load())
    private let pill = PillPresenter()
    private var statusItem: NSStatusItem?
    private var ticker: Timer?
    private var systemEvents: SystemEvents?
    private let presetIntervals = [5, 10, 15, 30]
    private lazy var settings = SettingsWindow(scheduler: scheduler) { [unowned self] in StateStore.save(scheduler.state) }

    func applicationDidFinishLaunching(_ notification: Notification) {
        ArabicFont.registerBundledFonts()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "Zikr")
        icon?.isTemplate = true
        item.button?.image = icon
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item

        scheduler.start(at: Date())
        if let welcome = scheduler.firstLaunchReminder(at: Date()) {
            pill.show(welcome)
            try? LoginItem.set(true)
        }
        StateStore.save(scheduler.state)
        systemEvents = SystemEvents { [weak self] event in self?.handle(event) }
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // For checking the Pill by hand: open Zikr.app --args -remindOnLaunch YES
        if UserDefaults.standard.bool(forKey: "remindOnLaunch") { remindMeNow() }
    }

    // Rebuilt each time it opens so it always shows the current state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(action("Remind me now", #selector(remindMeNow)))
        menu.addItem(.separator())
        menu.addItem(intervalMenu())
        menu.addItem(.separator())
        if let end = scheduler.pausedUntil {
            let status = NSMenuItem(title: "Paused until \(pauseEndText(end))", action: nil, keyEquivalent: "")
            status.isEnabled = false
            menu.addItem(status)
            menu.addItem(action("Resume", #selector(resume)))
        } else {
            menu.addItem(action("Pause for 1 hour", #selector(pauseForAnHour)))
            menu.addItem(action("Pause until tomorrow", #selector(pauseUntilTomorrow)))
        }
        menu.addItem(.separator())
        let settingsItem = action("Settings…", #selector(openSettings))
        settingsItem.keyEquivalent = ","
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem(title: "Quit Zikr", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func intervalMenu() -> NSMenuItem {
        let current = scheduler.state.intervalMinutes
        let submenu = NSMenu()
        for minutes in presetIntervals {
            let item = action("\(minutes) minutes", #selector(choosePreset(_:)))
            item.tag = minutes
            item.state = minutes == current ? .on : .off
            submenu.addItem(item)
        }
        let isCustom = !presetIntervals.contains(current)
        let custom = action(isCustom ? "Custom (\(current) min)…" : "Custom…", #selector(chooseCustom))
        custom.state = isCustom ? .on : .off
        submenu.addItem(custom)

        let parent = NSMenuItem(title: "Every \(current) min", action: nil, keyEquivalent: "")
        parent.submenu = submenu
        return parent
    }

    private func handle(_ event: SystemEvents.Event) {
        let now = Date()
        switch event {
        case .sleep: scheduler.didSleep(at: now); pill.hide()
        case .lock: scheduler.didLock(at: now); pill.hide()
        case .wake: scheduler.didWake(at: now)
        case .unlock: scheduler.didUnlock(at: now)
        }
    }

    private func tick() {
        let wasPaused = scheduler.pausedUntil != nil
        if let due = scheduler.tick(at: Date()) { pill.show(due) }
        if wasPaused, scheduler.pausedUntil == nil { StateStore.save(scheduler.state) }
    }

    private func pauseEndText(_ end: Date) -> String {
        let time = end.formatted(date: .omitted, time: .shortened)
        return Calendar.current.isDateInToday(end) ? time : "tomorrow \(time)"
    }

    @objc private func pauseForAnHour() {
        scheduler.pauseForAnHour(at: Date())
        pill.hide()
        StateStore.save(scheduler.state)
    }

    @objc private func pauseUntilTomorrow() {
        scheduler.pauseUntilTomorrow(at: Date())
        pill.hide()
        StateStore.save(scheduler.state)
    }

    @objc private func openSettings() {
        settings.show()
    }

    @objc private func resume() {
        scheduler.resume(at: Date())
        StateStore.save(scheduler.state)
    }

    @objc private func remindMeNow() {
        pill.show(scheduler.remindMeNow(at: Date()))
    }

    @objc private func choosePreset(_ sender: NSMenuItem) {
        setInterval(sender.tag)
    }

    @objc private func chooseCustom() {
        let alert = NSAlert()
        alert.messageText = "Remind me every…"
        alert.informativeText = "Enter a number of minutes from 1 to 180."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 80, height: 24))
        field.stringValue = String(scheduler.state.intervalMinutes)
        alert.accessoryView = field
        alert.addButton(withTitle: "Set")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let typed = field.stringValue.trimmingCharacters(in: .whitespaces)
        guard let minutes = Int(typed), Scheduler.allowedIntervals.contains(minutes) else {
            let refusal = NSAlert()
            refusal.messageText = "“\(typed)” isn’t a valid Interval"
            refusal.informativeText = "Please enter a whole number of minutes from 1 to 180."
            refusal.runModal()
            return
        }
        setInterval(minutes)
    }

    private func setInterval(_ minutes: Int) {
        guard (try? scheduler.setInterval(minutes, at: Date())) != nil else { return }
        StateStore.save(scheduler.state)
    }

    private func action(_ title: String, _ selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        return item
    }
}
