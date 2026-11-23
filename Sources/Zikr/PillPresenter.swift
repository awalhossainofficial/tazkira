import AppKit
import SwiftUI
import ZikrCore

/// Shows a Reminder in the Pill on the screen the mouse is on, then hides it.
@MainActor
final class PillPresenter {
    private let style: PillStyle
    private let model = PillModel()
    private let panel: NSPanel
    private let showFor: Duration = .seconds(8)
    private var remaining: Duration = .zero
    private var timerStarted = ContinuousClock.now
    private var hideTask: Task<Void, Never>?
    private var isShowing = false

    /// Room around the Pill for its shadow.
    private let margin: CGFloat = 40

    init(style: PillStyle = IslandStyle()) {
        self.style = style
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let host = NSHostingView(rootView: PillView(model: model))
        // The panel keeps the size we give it; the black shape animates inside.
        host.sizingOptions = []
        panel.contentView = host
        model.onHover = { [weak self] inside in self?.hoverChanged(inside) }
        model.onClick = { [weak self] in self?.hide() }
    }

    func show(_ remembrance: Remembrance) {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        guard let screen else { return }
        let info = ScreenInfo(screen)
        let open = style.openShape(for: remembrance, on: info)

        if !isShowing {
            panel.setFrame(NSRect(x: screen.frame.midX - open.width / 2 - margin,
                                  y: screen.frame.maxY - open.height - margin,
                                  width: open.width + margin * 2, height: open.height + margin),
                           display: false)
            model.shape = style.closedShape(on: info)
            model.isOpen = false
            panel.orderFrontRegardless()
        }
        isShowing = true
        model.content = style.content(for: remembrance, on: info)
        // Let the closed shape render once so the growth animates.
        DispatchQueue.main.async { [model] in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                model.shape = open
                model.isOpen = true
            }
        }
        model.closedShape = style.closedShape(on: info)
        restartTimer(for: showFor)
    }

    func hide() {
        guard isShowing else { return }
        isShowing = false
        hideTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            model.shape = model.closedShape
            model.isOpen = false
        }
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard let self, !self.isShowing else { return }
            self.panel.orderOut(nil)
        }
    }

    // Hovering freezes the countdown; leaving resumes the time that was left.
    private func hoverChanged(_ inside: Bool) {
        guard isShowing else { return }
        if inside {
            hideTask?.cancel()
            remaining -= ContinuousClock.now - timerStarted
        } else {
            restartTimer(for: max(remaining, .seconds(1)))
        }
    }

    private func restartTimer(for duration: Duration) {
        hideTask?.cancel()
        remaining = duration
        timerStarted = .now
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }
}

@MainActor @Observable
final class PillModel {
    var shape = PillShape(width: 0, height: 0, bottomRadius: 0, opacity: 0)
    var closedShape = PillShape(width: 0, height: 0, bottomRadius: 0, opacity: 0)
    var isOpen = false
    var content = AnyView(EmptyView())
    var onHover: (Bool) -> Void = { _ in }
    var onClick: () -> Void = {}
}

private struct PillView: View {
    let model: PillModel

    var body: some View {
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: model.shape.bottomRadius,
                                           bottomTrailingRadius: model.shape.bottomRadius)
        shape
            .fill(.black)
            .overlay(alignment: .top) {
                model.content
                    .opacity(model.isOpen ? 1 : 0)
                    .animation(model.isOpen ? .easeOut(duration: 0.3).delay(0.2) : .easeOut(duration: 0.18),
                               value: model.isOpen)
            }
            .clipShape(shape)
            .frame(width: model.shape.width, height: model.shape.height)
            .opacity(model.shape.opacity)
            .shadow(color: .black.opacity(model.isOpen ? 0.35 : 0), radius: 20, y: 14)
            .contentShape(shape)
            .onHover { model.onHover($0) }
            .onTapGesture { model.onClick() }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
