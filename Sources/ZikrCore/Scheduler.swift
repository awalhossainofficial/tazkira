import Foundation

/// Decides when a Reminder is due and which Remembrance it shows.
/// Every event takes the current time, so tests can drive it with a fake clock.
public final class Scheduler {
    public static let allowedIntervals = 1...180

    public private(set) var state: SchedulerState
    private let list: [Remembrance]
    private var random: AnyRandom
    private var nextDue: Date?
    private var round: [Remembrance] = []
    private var lastShown: Remembrance?
    private var isAsleep = false
    private var isLocked = false

    public init(list: [Remembrance], state: SchedulerState = SchedulerState(),
                random: some RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.list = list
        self.state = state
        self.random = AnyRandom(random)
    }

    public func start(at now: Date) {
        restartCountdown(at: now)
    }

    /// Call often; returns a Remembrance when a Reminder is due.
    public func tick(at now: Date) -> Remembrance? {
        guard !isAway, let nextDue, now >= nextDue else { return nil }
        return show(at: now)
    }

    public func didSleep(at now: Date) { isAsleep = true }
    public func didLock(at now: Date) { isLocked = true }

    public func didWake(at now: Date) {
        isAsleep = false
        restartCountdown(at: now)
    }

    public func didUnlock(at now: Date) {
        isLocked = false
        restartCountdown(at: now)
    }

    private var isAway: Bool { isAsleep || isLocked }

    public func remindMeNow(at now: Date) -> Remembrance {
        show(at: now)
    }

    public func setInterval(_ minutes: Int, at now: Date) throws {
        guard Self.allowedIntervals.contains(minutes) else { throw IntervalError(minutes: minutes) }
        state.intervalMinutes = minutes
        restartCountdown(at: now)
    }

    private func show(at now: Date) -> Remembrance {
        restartCountdown(at: now)
        if round.isEmpty { round = newRound() }
        let next = round.removeFirst()
        lastShown = next
        return next
    }

    // A new shuffle never opens with the one just shown.
    private func newRound() -> [Remembrance] {
        var shuffled = list.shuffled(using: &random)
        if shuffled.count > 1, shuffled.first == lastShown {
            shuffled.swapAt(0, Int.random(in: 1..<shuffled.count, using: &random))
        }
        return shuffled
    }

    private func restartCountdown(at now: Date) {
        nextDue = now.addingTimeInterval(TimeInterval(state.intervalMinutes * 60))
    }
}

/// Lets the Scheduler hold any random source, seeded in tests.
struct AnyRandom: RandomNumberGenerator {
    private let nextValue: () -> UInt64
    init(_ base: some RandomNumberGenerator) {
        var base = base
        nextValue = { base.next() }
    }
    mutating func next() -> UInt64 { nextValue() }
}
