import SwiftUI
import ZikrCore

/// A separate card just below the menu bar, with a bar that runs down over the 8 seconds.
struct DropCardStyle: PillStyle {
    private let width: CGFloat = 400

    func topGap(on screen: ScreenInfo) -> CGFloat { 44 }

    func largestSize(for remembrance: Remembrance, on screen: ScreenInfo) -> CGSize {
        CGSize(width: width, height: fittingHeight(of: card(for: remembrance, progress: .full), width: width))
    }

    func pill(for remembrance: Remembrance, on screen: ScreenInfo,
              phase: PillPhase, progress: PillProgress) -> AnyView {
        let isOpen = phase != .closed
        let outline = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return AnyView(
            card(for: remembrance, progress: progress)
                .frame(width: width)
                .background(.black, in: outline)
                .clipShape(outline)
                .shadow(color: .black.opacity(0.35), radius: 20, y: 14)
                .contentShape(outline)
                .scaleEffect(isOpen ? 1 : 0.92, anchor: .top)
                .offset(y: isOpen ? 0 : -18)
                .opacity(isOpen ? 1 : 0)
        )
    }

    private func card(for remembrance: Remembrance, progress: PillProgress) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.fill").font(.system(size: 10))
                        Text("ZIKR").tracking(0.9)
                    }
                    .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Text(remembrance.kind.rawValue).font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.vertical, 2).padding(.horizontal, 8)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .font(.system(size: 11, weight: .semibold))

                Text(remembrance.arabic).font(ArabicFont.font(size: 27)).lineSpacing(10)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.top, 10)
                Text(remembrance.transliteration).font(.system(size: 14, weight: .medium)).italic()
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 4)
                Text(remembrance.meaning).font(.system(size: 13)).lineSpacing(3)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.top, 4)
                Text(remembrance.source).font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(.top, 8)
            }
            .multilineTextAlignment(.center).foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 14, trailing: 20))

            TimeLeftBar(progress: progress)
        }
    }
}

/// Drains from right to left as the 8 seconds run out, and holds still while paused.
private struct TimeLeftBar: View {
    let progress: PillProgress

    var body: some View {
        TimelineView(.animation(paused: progress.isPaused)) { context in
            GeometryReader { geometry in
                Rectangle().fill(.white.opacity(0.55))
                    .frame(width: geometry.size.width * progress.fractionLeft(at: context.date))
            }
        }
        .frame(height: 3)
        .background(.white.opacity(0.08))
    }
}
