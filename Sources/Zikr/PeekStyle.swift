import SwiftUI
import ZikrCore

/// Only the Arabic on one line; hovering opens the rest.
struct PeekStyle: PillStyle {
    private let hoveredWidth: CGFloat = 470
    private let lineHeight: CGFloat = 48

    func largestSize(for remembrance: Remembrance, on screen: ScreenInfo) -> CGSize {
        let open = openShape(on: screen), hovered = hoveredShape(for: remembrance, on: screen)
        return CGSize(width: max(open.width, hovered.width), height: max(open.height, hovered.height))
    }

    func pill(for remembrance: Remembrance, on screen: ScreenInfo,
              phase: PillPhase, progress: PillProgress) -> AnyView {
        let shape: PillShape = switch phase {
        case .closed: .closedAtTop(on: screen)
        case .open: openShape(on: screen)
        case .hovered: hoveredShape(for: remembrance, on: screen)
        }
        return AnyView(TopPill(shape: shape, isOpen: phase != .closed,
                               content: content(for: remembrance, on: screen, showsAll: phase == .hovered)))
    }

    private func topRoom(on screen: ScreenInfo) -> CGFloat { screen.hasNotch ? screen.notchHeight + 6 : 12 }

    private func openShape(on screen: ScreenInfo) -> PillShape {
        PillShape(width: screen.hasNotch ? 380 : 340, height: topRoom(on: screen) + lineHeight, bottomRadius: 28)
    }

    private func hoveredShape(for remembrance: Remembrance, on screen: ScreenInfo) -> PillShape {
        let full = content(for: remembrance, on: screen, showsAll: true)
        return PillShape(width: hoveredWidth, height: fittingHeight(of: full, width: hoveredWidth), bottomRadius: 34)
    }

    private func content(for remembrance: Remembrance, on screen: ScreenInfo, showsAll: Bool) -> AnyView {
        AnyView(
            VStack(spacing: 6) {
                // Arabic runs right to left, so a cut line shows its "…" on the left.
                Text(remembrance.arabic).font(ArabicFont.font(size: showsAll ? 26 : 22))
                    .lineSpacing(showsAll ? 8 : 0).lineLimit(showsAll ? nil : 1).truncationMode(.tail)
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(height: showsAll ? nil : lineHeight)
                if showsAll {
                    Text(remembrance.transliteration).font(.system(size: 14, weight: .medium)).italic()
                        .foregroundStyle(.white.opacity(0.9))
                    Text(remembrance.meaning).font(.system(size: 13)).lineSpacing(3)
                        .foregroundStyle(.white.opacity(0.72))
                    Text(remembrance.kindAndSource).font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
            .multilineTextAlignment(.center).foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: topRoom(on: screen), leading: 24, bottom: showsAll ? 18 : 0, trailing: 24))
        )
    }
}
