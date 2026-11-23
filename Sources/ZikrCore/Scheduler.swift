import Foundation

/// Decides when a Reminder is due and which Remembrance it shows.
/// Every event takes the current time, so tests can drive it with a fake clock.
public final class Scheduler {
    public static let allowedIntervals = 1...180

    public private(set) var state: SchedulerState
    private let list: [Remembrance]
    private let calendar: Calendar
    private var random: AnyRandom
    private var nextDue: Date?
    private var round: [Remembrance] = []
    private var lastShown: Remembrance?
    private var isAsleep = false
    private var isLocked = false

    public init(list: [Remembrance], state: SchedulerState = SchedulerState(),
                calendar: Calendar = .current,
                random: some RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.list = list
        self.state = state
        self.calendar = calendar
        self.random = AnyRandom(random)
    }

    public func start(at now: Date) {
        if let end = state.pauseEnd, now >= end { state.pauseEnd = nil }
        restartCountdown(at: now)
    }

    /// Only the very first launch greets the user with a Reminder.
    public func firstLaunchReminder(at now: Date) -> Remembrance? {
        guard !state.hasLaunchedBefore else { return nil }
        state.hasLaunchedBefore = true
        return show(at: now)
    }

    /// Call often; returns a Remembrance when a Reminder is due.
    public func tick(at now: Date) -> Remembrance? {
        if let end = state.pauseEnd {
            if now >= end { resume(at: now) }
            return nil
        }
        guard !isAway, let nextDue, now >= nextDue else { return nil }
        return show(at: now)
    }

    public var pausedUntil: Date? { state.pauseEnd }

    public func pauseForAnHour(at now: Date) {
        state.pauseEnd = now.addingTimeInterval(60 * 60)
    }

    public func pauseUntilTomorrow(at now: Date) {
        state.pauseEnd = calendar.nextDate(after: now, matching: DateComponents(hour: 6, minute: 0),
                                           matchingPolicy: .nextTime)
    }

    public func resume(at now: Date) {
        state.pauseEnd = nil
        restartCountdown(at: now)
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

    public func isOn(_ id: String) -> Bool { !state.switchedOff.contains(id) }

    public func setOn(_ id: String, _ on: Bool) throws {
        guard on != isOn(id) else { return }
        if on {
            state.switchedOff.remove(id)
            // Only a Round already under way needs it added; a new one picks it up anyway.
            if !round.isEmpty, let remembrance = list.first(where: { $0.id == id }) {
                round.insert(remembrance, at: Int.random(in: 0...round.count, using: &random))
            }
        } else {
            guard switchedOn.count > 1 else { throw LastRemembranceError() }
            state.switchedOff.insert(id)
            round.removeAll { $0.id == id }
        }
    }

    private var switchedOn: [Remembrance] { list.filter { isOn($0.id) } }

    private func show(at now: Date) -> Remembrance {
        restartCountdown(at: now)
        if round.isEmpty { round = newRound() }
        let next = round.removeFirst()
        lastShown = next
        return next
    }

    // A new shuffle never opens with the one just shown.
    private func newRound() -> [Remembrance] {
        var shuffled = switchedOn.shuffled(using: &random)
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
