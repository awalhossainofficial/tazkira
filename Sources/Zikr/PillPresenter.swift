import AppKit
import SwiftUI
import ZikrCore

@MainActor
final class PillPresenter {
    private var style: PillStyle
    private let model: PillModel
    private let panel: NSPanel
    private var clock = PillClock()
    private var hideTask: Task<Void, Never>?
    private var screen: NSScreen?

    /// Room around the Pill for its shadow.
    private let margin: CGFloat = 40

    init(choice: PillStyleChoice = .island) {
        let style = choice.style
        self.style = style
        model = PillModel(style: style)
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let host = NSHostingView(rootView: PillView(model: model))
        // The panel keeps the size we give it; the Pill animates inside.
        host.sizingOptions = []
        panel.contentView = host
        model.onHover = { [weak self] inside in self?.hoverChanged(inside) }
        model.onClick = { [weak self] in self?.hide() }
    }

    /// Closes any open Pill at once so the next one starts clean in the new style.
    func setStyle(_ choice: PillStyleChoice) {
        let newStyle = choice.style
        hideTask?.cancel()
        panel.orderOut(nil)
        clock.hide(at: .now)
        model.phase = .closed
        style = newStyle
        model.style = newStyle
    }

    func show(_ remembrance: Remembrance) {
        let isShowing = clock.isShowing
        // A Pill already up stays on its screen; a new one follows the mouse.
        let mouseScreen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
        guard let screen = (isShowing ? screen : nil) ?? mouseScreen ?? NSScreen.main else { return }
        let info = ScreenInfo(screen)
        let size = style.largestSize(for: remembrance, on: info)
        let gap = style.topGap(on: info)
        // A gap above the Pill leaves room for the top of its shadow.
        let topRoom = min(gap, margin)
        var frame = NSRect(x: screen.frame.midX - size.width / 2 - margin,
                           y: screen.frame.maxY - gap - size.height - margin,
                           width: size.width + margin * 2, height: size.height + margin + topRoom)

        if isShowing {
            // Never shrink mid-animation, or the old Pill gets cut off.
            frame = frame.union(panel.frame)
            panel.setFrame(frame, display: true)
            model.topRoom = topRoom
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                model.remembrance = remembrance
            }
        } else {
            panel.setFrame(frame, display: false)
            model.topRoom = topRoom
            model.screen = info
            model.remembrance = remembrance
            model.phase = .closed
            panel.orderFrontRegardless()
            // Let the closed Pill render once so the growth animates.
            DispatchQueue.main.async { [model] in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) { model.phase = .open }
            }
        }
        self.screen = screen
        clock.show(at: .now)
        clockChanged()
    }

    func hide() {
        guard clock.isShowing else { return }
        clock.hide(at: .now)
        clockChanged()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) { model.phase = .closed }
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard let self, !self.clock.isShowing else { return }
            self.panel.orderOut(nil)
        }
    }

    private func hoverChanged(_ inside: Bool) {
        guard clock.isShowing else { return }
        clock.hover(inside, at: .now)
        clockChanged()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            model.phase = inside ? .hovered : .open
        }
    }

    /// Hands the Pill Clock to the style and sets one alarm for when it runs out.
    private func clockChanged() {
        model.clock = clock
        hideTask?.cancel()
        guard let hidesAt = clock.hidesAt else { return }
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, hidesAt.timeIntervalSinceNow)))
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }
}

@MainActor @Observable
final class PillModel {
    var style: PillStyle
    var remembrance: Remembrance?
    var screen: ScreenInfo?
    var phase = PillPhase.closed
    var clock = PillClock()
    var topRoom: CGFloat = 0
    var onHover: (Bool) -> Void = { _ in }
    var onClick: () -> Void = {}

    init(style: PillStyle) { self.style = style }
}

private struct PillView: View {
    let model: PillModel

    var body: some View {
        Group {
            if let remembrance = model.remembrance, let screen = model.screen {
                model.style.pill(for: remembrance, on: screen, phase: model.phase, clock: model.clock)
                    .onHover { model.onHover($0) }
                    .onTapGesture { model.onClick() }
            }
        }
        .padding(.top, model.topRoom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
