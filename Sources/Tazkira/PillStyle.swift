import AppKit
import SwiftUI
import TazkiraCore

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

/// One visual design of the Pill. The style draws the whole Pill; the Pill Clock owns timing.
@MainActor
protocol PillStyle {
    /// What Settings calls this style.
    var name: String { get }
    /// Space between the top of the screen and the Pill.
    func topGap(on screen: ScreenInfo) -> CGFloat
    /// The biggest the Pill gets for this Remembrance, so the window can fit every phase.
    func largestSize(for remembrance: Remembrance, on screen: ScreenInfo) -> CGSize
    func pill(for remembrance: Remembrance, on screen: ScreenInfo,
              phase: PillPhase, clock: PillClock) -> AnyView
}

extension PillStyle {
    func topGap(on screen: ScreenInfo) -> CGFloat { 0 }
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
