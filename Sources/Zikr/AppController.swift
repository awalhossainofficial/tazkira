import AppKit
import ZikrCore

@MainActor
final class AppController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let scheduler = Scheduler(list: BuiltInList.all)
    private let pill = PillPresenter()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "Zikr")
        icon?.isTemplate = true
        item.button?.image = icon
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
        // For checking the Pill by hand: open Zikr.app --args -remindOnLaunch YES
        if UserDefaults.standard.bool(forKey: "remindOnLaunch") { remindMeNow() }
    }

    // Rebuilt each time it opens so it always shows the current state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(action("Remind me now", #selector(remindMeNow)))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Zikr", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func remindMeNow() {
        pill.show(scheduler.remindMeNow(at: Date()))
    }

    private func action(_ title: String, _ selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        return item
    }
}
