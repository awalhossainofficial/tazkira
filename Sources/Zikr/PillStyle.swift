import AppKit
import SwiftUI
import ZikrCore

/// The black shape at one moment: its size, corner rounding and visibility.
struct PillShape: Equatable {
    var width: CGFloat
    var height: CGFloat
    var bottomRadius: CGFloat
    var opacity: Double = 1
}

/// What a Pill Style needs to know about the screen it appears on.
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

/// One visual design of the Pill. v1 ships Island only.
@MainActor
protocol PillStyle {
    func closedShape(on screen: ScreenInfo) -> PillShape
    func openShape(for remembrance: Remembrance, on screen: ScreenInfo) -> PillShape
    func hoverShape(for remembrance: Remembrance, on screen: ScreenInfo) -> PillShape
    func content(for remembrance: Remembrance, on screen: ScreenInfo) -> AnyView
}

extension PillStyle {
    func hoverShape(for remembrance: Remembrance, on screen: ScreenInfo) -> PillShape {
        openShape(for: remembrance, on: screen)
    }
}

/// Grows out of the notch into a card sized to the text.
struct IslandStyle: PillStyle {
    private let width: CGFloat = 480

    func closedShape(on screen: ScreenInfo) -> PillShape {
        screen.hasNotch
            ? PillShape(width: screen.notchWidth, height: screen.notchHeight, bottomRadius: 12)
            : PillShape(width: 120, height: 18, bottomRadius: 12, opacity: 0)
    }

    func openShape(for remembrance: Remembrance, on screen: ScreenInfo) -> PillShape {
        let measured = NSHostingView(rootView: content(for: remembrance, on: screen).frame(width: width))
        return PillShape(width: width, height: ceil(measured.fittingSize.height), bottomRadius: 36)
    }

    func content(for remembrance: Remembrance, on screen: ScreenInfo) -> AnyView {
        AnyView(
            VStack(spacing: 8) {
                Text(remembrance.arabic)
                    .font(ArabicFont.font(size: 30))
                    .lineSpacing(12)
                    .environment(\.layoutDirection, .rightToLeft)
                Text(remembrance.meaning)
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            // Extra top room on notched screens keeps the Arabic clear of the camera.
            .padding(EdgeInsets(top: screen.hasNotch ? screen.notchHeight + 12 : 18,
                                leading: 30, bottom: 22, trailing: 30))
        )
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
            ? .custom("Amiri-Regular", size: size)
            : .custom("Geeza Pro", size: size)
    }
}
