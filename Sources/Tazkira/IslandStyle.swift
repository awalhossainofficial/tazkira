import SwiftUI
import TazkiraCore

/// Grows out of the notch into a card sized to the text.
struct IslandStyle: PillStyle {
    let name = "Island"
    private let width: CGFloat = 480

    func largestSize(for remembrance: Remembrance, on screen: ScreenInfo) -> CGSize {
        let open = openShape(for: remembrance, on: screen)
        return CGSize(width: open.width, height: open.height)
    }

    func pill(for remembrance: Remembrance, on screen: ScreenInfo,
              phase: PillPhase, clock: PillClock) -> AnyView {
        let isOpen = phase != .closed
        return AnyView(TopPill(shape: isOpen ? openShape(for: remembrance, on: screen) : closedShape(on: screen),
                               isOpen: isOpen, content: content(for: remembrance, on: screen)))
    }

    private func closedShape(on screen: ScreenInfo) -> PillShape { .closedAtTop(on: screen) }

    private func openShape(for remembrance: Remembrance, on screen: ScreenInfo) -> PillShape {
        PillShape(width: width, height: fittingHeight(of: content(for: remembrance, on: screen), width: width),
                  bottomRadius: 36)
    }

    private func content(for remembrance: Remembrance, on screen: ScreenInfo) -> AnyView {
        AnyView(
            VStack(spacing: 8) {
                Text(remembrance.arabic).font(ArabicFont.font(size: 30)).lineSpacing(12)
                    .environment(\.layoutDirection, .rightToLeft)
                Text(remembrance.transliteration).font(.system(size: 14, weight: .medium)).italic()
                    .foregroundStyle(.white.opacity(0.9))
                Text(remembrance.meaning).font(.system(size: 13)).lineSpacing(3)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .multilineTextAlignment(.center).foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            // Extra top room on notched screens keeps the Arabic clear of the camera.
            .padding(EdgeInsets(top: screen.hasNotch ? screen.notchHeight + 12 : 18,
                                leading: 30, bottom: 22, trailing: 30))
        )
    }
}
