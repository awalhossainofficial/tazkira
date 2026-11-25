import AppKit
import SwiftUI
import ZikrCore

struct PillShape: Equatable {
    var width: CGFloat
    var height: CGFloat
    var bottomRadius: CGFloat
    var opacity: Double = 1
}

struct ScreenInfo {
    var hasNotch: Bool
    var notchWidth: CGFloat
    var notchHeight: CGFloat
    init(_ screen: NSScreen) {
        let top = screen.safeAreaInsets.top
        hasNotch = top > 0
        notchHeight = top
        let left = screen.auxiliaryTopLeftArea?.width ?? 0
        let right = screen.auxiliaryTopRightArea?.width ?? 0
        notchWidth = hasNotch ? screen.frame.width - left - right : 0
    }
}

enum PillPhase { case closed, open, hovered }

/// How much of the 8 seconds is left, so a style can draw the clock.
struct PillProgress {
    var fractionLeft: Double
    var isPaused: Bool
    var measuredAt: Date
    var total: TimeInterval

    func fractionLeft(at now: Date) -> Double {
        isPaused ? fractionLeft : max(0, fractionLeft - now.timeIntervalSince(measuredAt) / total)
    }

    static let full = PillProgress(fractionLeft: 1, isPaused: true, measuredAt: .now, total: 8)
}

/// One visual design of the Pill. The style draws the whole Pill; the presenter owns timing and hover.
@MainActor
protocol PillStyle {
    /// Space between the top of the screen and the Pill.
    func topGap(on screen: ScreenInfo) -> CGFloat
    /// The biggest the Pill gets for this Remembrance, so the window can fit every phase.
    func largestSize(for remembrance: Remembrance, on screen: ScreenInfo) -> CGSize
    func pill(for remembrance: Remembrance, on screen: ScreenInfo,
              phase: PillPhase, progress: PillProgress) -> AnyView
}

extension PillStyle {
    func topGap(on screen: ScreenInfo) -> CGFloat { 0 }
}

/// Grows out of the notch into a card sized to the text.
struct IslandStyle: PillStyle {
    private let width: CGFloat = 480

    func largestSize(for remembrance: Remembrance, on screen: ScreenInfo) -> CGSize {
        let open = openShape(for: remembrance, on: screen)
        return CGSize(width: open.width, height: open.height)
    }

    func pill(for remembrance: Remembrance, on screen: ScreenInfo,
              phase: PillPhase, progress: PillProgress) -> AnyView {
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

/// A black shape hanging from the top edge, square on top and rounded below.
struct TopPill<Outline: Shape>: View {
    let shape: PillShape
    let outline: Outline
    let isOpen: Bool
    let content: AnyView

    var body: some View {
        outline
            .fill(.black)
            .overlay(alignment: .top) {
                content
                    .opacity(isOpen ? 1 : 0)
                    .animation(isOpen ? .easeOut(duration: 0.3).delay(0.2) : .easeOut(duration: 0.18),
                               value: isOpen)
            }
            .clipShape(outline)
            .frame(width: shape.width, height: shape.height)
            .opacity(shape.opacity)
            .shadow(color: .black.opacity(isOpen ? 0.35 : 0), radius: 20, y: 14)
            .contentShape(outline)
    }
}

extension TopPill where Outline == UnevenRoundedRectangle {
    init(shape: PillShape, isOpen: Bool, content: AnyView) {
        self.init(shape: shape,
                  outline: UnevenRoundedRectangle(bottomLeadingRadius: shape.bottomRadius,
                                                  bottomTrailingRadius: shape.bottomRadius),
                  isOpen: isOpen, content: content)
    }
}

extension PillShape {
    /// The Pill before it grows: the notch itself, or nothing on a Mac without one.
    static func closedAtTop(on screen: ScreenInfo) -> PillShape {
        screen.hasNotch
            ? PillShape(width: screen.notchWidth, height: screen.notchHeight, bottomRadius: 12)
            : PillShape(width: 120, height: 18, bottomRadius: 12, opacity: 0)
    }
}

@MainActor
func fittingHeight(of view: some View, width: CGFloat) -> CGFloat {
    ceil(NSHostingView(rootView: view.frame(width: width)).fittingSize.height)
}

extension Remembrance {
    var kindAndSource: String { "\(kind.rawValue) · \(source)" }
}

extension PillStyleChoice {
    /// The styles listed in Settings, in order.
    static let offered: [PillStyleChoice] = [.island, .wings, .dropCard, .peek]

    var name: String {
        switch self {
        case .island: "Island"
        case .wings: "Wings"
        case .dropCard: "Drop Card"
        case .peek: "Peek"
        }
    }

    @MainActor var style: PillStyle {
        switch self {
        case .island: IslandStyle()
        case .wings: WingsStyle()
        case .dropCard: DropCardStyle()
        case .peek: PeekStyle()
        }
    }
}

/// Amiri when it is bundled with the app, otherwise the system's Arabic font.
enum ArabicFont {
    static func registerBundledFonts() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
        for url in urls { CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) }
    }
    static func font(size: CGFloat) -> Font {
        NSFont(name: "Amiri-Regular", size: size) != nil
            ? .custom("Amiri-Regular", size: size) : .custom("Geeza Pro", size: size)
    }
}
