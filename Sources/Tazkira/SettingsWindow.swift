import AppKit
import SwiftUI
import TazkiraCore

/// The Settings window; it asks the Scheduler for every change so the rules live in one place.
@MainActor
final class SettingsWindow {
    private var window: NSWindow?
    private let model: SettingsModel

    init(scheduler: Scheduler, onChange: @escaping () -> Void,
         onPickStyle: @escaping (PillStyleChoice) -> Void) {
        model = SettingsModel(scheduler: scheduler, onChange: onChange, onPickStyle: onPickStyle)
    }

    func show() {
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model)))
            window.title = "Tazkira Settings"
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
    private let onPickStyle: (PillStyleChoice) -> Void
    private(set) var switchedOff: Set<String> = []
    private(set) var pillStyle = PillStyleChoice.island
    private(set) var opensAtLogin = false
    private(set) var loginNote: String?
    var refusal: String?

    init(scheduler: Scheduler, onChange: @escaping () -> Void,
         onPickStyle: @escaping (PillStyleChoice) -> Void) {
        self.scheduler = scheduler
        self.onChange = onChange
        self.onPickStyle = onPickStyle
    }

    func refresh() {
        switchedOff = scheduler.state.switchedOff
        pillStyle = scheduler.state.pillStyle
        refusal = nil
        readLoginItem()
    }

    var opensAtLoginBinding: Binding<Bool> {
        Binding(
            get: { self.opensAtLogin },
            set: { on in
                do { try LoginItem.set(on) } catch { self.loginNote = "macOS didn’t accept that change. Try again in a moment." }
                self.readLoginItem(keepingNote: true)
            })
    }

    private func readLoginItem(keepingNote: Bool = false) {
        opensAtLogin = LoginItem.isOn || LoginItem.needsApproval
        if LoginItem.needsApproval {
            loginNote = "Allow Tazkira in System Settings › General › Login Items."
        } else if !keepingNote {
            loginNote = nil
        }
    }

    // Saved before the switch, so a quit right after still keeps the choice.
    var pillStyleBinding: Binding<PillStyleChoice> {
        Binding(
            get: { self.pillStyle },
            set: { choice in
                guard choice != self.pillStyle else { return }
                self.scheduler.setPillStyle(choice)
                self.pillStyle = choice
                self.onChange()
                self.onPickStyle(choice)
            })
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
            Section("General") {
                Toggle("Open Tazkira at login", isOn: model.opensAtLoginBinding)
                if let note = model.loginNote {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Pill style") {
                Picker("Pill style", selection: model.pillStyleBinding) {
                    ForEach(PillStyleChoice.allCases, id: \.self) { Text($0.style.name).tag($0) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
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
            Text(remembrance.transliteration).italic()
            Text(remembrance.meaning)
            Text("\(remembrance.kind.rawValue) · \(remembrance.source)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
