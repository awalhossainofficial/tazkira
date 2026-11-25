import SwiftUI
import ZikrCore

/// A thin strip either side of the notch: the English letters on the left, the Arabic on the right.
struct WingsStyle: PillStyle {
    private let noNotchGap: CGFloat = 24

    func largestSize(for remembrance: Remembrance, on screen: ScreenInfo) -> CGSize {
        let hovered = hoveredShape(for: remembrance, on: screen)
        return CGSize(width: hovered.width, height: hovered.height)
    }

    func pill(for remembrance: Remembrance, on screen: ScreenInfo,
              phase: PillPhase, progress: PillProgress) -> AnyView {
        let shape: PillShape = switch phase {
        case .closed: .closedAtTop(on: screen)
        case .open: PillShape(width: width(on: screen), height: rowHeight(on: screen), bottomRadius: 14)
        case .hovered: hoveredShape(for: remembrance, on: screen)
        }
        // Behind the notch the strip stays whole, since the notch is black anyway.
        let gap = phase == .open && !screen.hasNotch ? noNotchGap : 0
        return AnyView(TopPill(shape: shape, outline: WingsOutline(gap: gap, radius: shape.bottomRadius),
                               isOpen: phase != .closed, content: content(for: remembrance, on: screen)))
    }

    private func width(on screen: ScreenInfo) -> CGFloat { screen.hasNotch ? screen.notchWidth + 470 : 520 }
    private func rowHeight(on screen: ScreenInfo) -> CGFloat { max(32, screen.notchHeight) }

    private func hoveredShape(for remembrance: Remembrance, on screen: ScreenInfo) -> PillShape {
        let w = width(on: screen)
        return PillShape(width: w, height: fittingHeight(of: content(for: remembrance, on: screen), width: w),
                         bottomRadius: 30)
    }

    // The open strip shows only the top row; hovering uncovers the card below it.
    private func content(for remembrance: Remembrance, on screen: ScreenInfo) -> AnyView {
        let middle = screen.hasNotch ? screen.notchWidth + 24 : noNotchGap
        return AnyView(
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill").font(.system(size: 11))
                        Text(remembrance.transliteration).font(.system(size: 12)).lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Color.clear.frame(width: middle)
                    // Amiri sits high in its line box, so its top marks would touch the screen edge.
                    Text(remembrance.arabic).font(ArabicFont.font(size: 17)).lineLimit(1)
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(y: 3)
                }
                .padding(.horizontal, 14)
                .frame(height: rowHeight(on: screen))

                VStack(spacing: 6) {
                    Text(remembrance.arabic).font(ArabicFont.font(size: 26)).lineSpacing(8)
                        .environment(\.layoutDirection, .rightToLeft)
                    Text(remembrance.transliteration).font(.system(size: 14, weight: .medium)).italic()
                        .foregroundStyle(.white.opacity(0.9))
                    Text(remembrance.meaning).font(.system(size: 13)).lineSpacing(3)
                        .foregroundStyle(.white.opacity(0.72))
                    Text(remembrance.kindAndSource).font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.42))
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(EdgeInsets(top: 10, leading: 26, bottom: 20, trailing: 26))
            }
            .foregroundStyle(.white)
        )
    }
}

/// One strip, or two halves split by a gap. The inner corners shrink with the gap, so closing it is seamless.
struct WingsOutline: Shape {
    var gap: CGFloat
    var radius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(gap, radius) }
        set { gap = newValue.first; radius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        guard gap > 0.5 else {
            return UnevenRoundedRectangle(bottomLeadingRadius: radius, bottomTrailingRadius: radius).path(in: rect)
        }
        let half = (rect.width - gap) / 2
        let inner = min(radius, gap / 2)
        var path = UnevenRoundedRectangle(bottomLeadingRadius: radius, bottomTrailingRadius: inner)
            .path(in: CGRect(x: rect.minX, y: rect.minY, width: half, height: rect.height))
        path.addPath(UnevenRoundedRectangle(bottomLeadingRadius: inner, bottomTrailingRadius: radius)
            .path(in: CGRect(x: rect.maxX - half, y: rect.minY, width: half, height: rect.height)))
        return path
    }
}
