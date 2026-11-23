import AppKit
import SwiftUI
import ZikrCore

/// Shows a Reminder in the Pill at the top centre of the screen.
@MainActor
final class PillPresenter {
    private let panel: NSPanel
    private var hideTask: Task<Void, Never>?

    init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 160),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    func show(_ remembrance: Remembrance) {
        guard let screen = NSScreen.main else { return }
        let view = NSHostingView(rootView: PillContent(remembrance: remembrance))
        panel.contentView = view
        let size = view.fittingSize
        panel.setFrame(NSRect(x: screen.frame.midX - size.width / 2, y: screen.frame.maxY - size.height,
                              width: size.width, height: size.height), display: true)
        panel.orderFrontRegardless()
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            self?.panel.orderOut(nil)
        }
    }
}

private struct PillContent: View {
    let remembrance: Remembrance

    var body: some View {
        VStack(spacing: 4) {
            Text(remembrance.arabic).font(.custom("Geeza Pro", size: 30))
            Text(remembrance.meaning).font(.system(size: 13)).foregroundStyle(.white.opacity(0.72))
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(EdgeInsets(top: 18, leading: 30, bottom: 22, trailing: 30))
        .frame(width: 480)
        .background(UnevenRoundedRectangle(bottomLeadingRadius: 36, bottomTrailingRadius: 36).fill(.black))
    }
}
