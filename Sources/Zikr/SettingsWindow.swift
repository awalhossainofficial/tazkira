import AppKit
import SwiftUI
import ZikrCore

/// The Settings window; it asks the Scheduler for every change so the rules live in one place.
@MainActor
final class SettingsWindow {
    private var window: NSWindow?
    private let model: SettingsModel

    init(scheduler: Scheduler, onChange: @escaping () -> Void) {
        model = SettingsModel(scheduler: scheduler, onChange: onChange)
    }

    func show() {
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model)))
            window.title = "Zikr Settings"
            window.styleMask = [.titled, .closable, .resizable]
            window.setContentSize(NSSize(width: 480, height: 600))
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        model.refresh()
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}

@MainActor @Observable
final class SettingsModel {
    private let scheduler: Scheduler
    private let onChange: () -> Void
    private(set) var switchedOff: Set<String> = []
    var refusal: String?

    init(scheduler: Scheduler, onChange: @escaping () -> Void) {
        self.scheduler = scheduler
        self.onChange = onChange
    }

    func refresh() {
        switchedOff = scheduler.state.switchedOff
        refusal = nil
    }

    func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { !self.switchedOff.contains(id) },
            set: { on in
                do {
                    try self.scheduler.setOn(id, on)
                    self.refusal = nil
                    self.onChange()
                } catch {
                    self.refusal = "At least one Remembrance has to stay on, or there would be nothing to show."
                }
                self.switchedOff = self.scheduler.state.switchedOff
            })
    }
}

private struct SettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            if let refusal = model.refusal {
                Text(refusal).foregroundStyle(.red)
            }
            Section("Remembrances") {
                ForEach(BuiltInList.all) { remembrance in
                    Toggle(isOn: model.binding(for: remembrance.id)) {
                        RemembranceRow(remembrance: remembrance)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct RemembranceRow: View {
    let remembrance: Remembrance

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(remembrance.arabic)
                .font(ArabicFont.font(size: 20))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(remembrance.meaning)
            Text("\(remembrance.kind.rawValue) · \(remembrance.source)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
