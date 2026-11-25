import Foundation

/// How long a Reminder stays up. Every event takes the current time,
/// so tests can drive it without waiting.
public struct PillClock: Sendable {
    public static let showFor: TimeInterval = 8
    // Leaving with almost no time left still gives a moment to read.
    static let leastAfterHover: TimeInterval = 1

    public private(set) var isShowing = false
    public private(set) var isHovered = false
    private var left: TimeInterval = showFor
    private var runningSince: Date?

    public init() {}

    /// A new Reminder always gets the full time; while hovered it waits for the mouse to leave.
    public mutating func show(at now: Date) {
        isShowing = true
        left = Self.showFor
        runningSince = isHovered ? nil : now
    }

    public mutating func hover(_ inside: Bool, at now: Date) {
        guard isShowing, inside != isHovered else { return }
        isHovered = inside
        if inside {
            stop(at: now)
        } else {
            left = max(left, Self.leastAfterHover)
            runningSince = now
        }
    }

    public mutating func hide(at now: Date) {
        stop(at: now)
        isShowing = false
        isHovered = false
    }

    public var isRunning: Bool { runningSince != nil }

    /// When the Pill should go, or nil while it is hidden or hovered.
    public var hidesAt: Date? { runningSince?.addingTimeInterval(left) }

    public func fractionLeft(at now: Date) -> Double { timeLeft(at: now) / Self.showFor }

    private func timeLeft(at now: Date) -> TimeInterval {
        guard let runningSince else { return left }
        return max(0, left - now.timeIntervalSince(runningSince))
    }

    private mutating func stop(at now: Date) {
        left = timeLeft(at: now)
        runningSince = nil
    }
}
