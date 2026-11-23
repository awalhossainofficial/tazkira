import Foundation

/// Decides when a Reminder shows and which Remembrance it shows.
/// It is told what happened and when; it never reads the clock itself.
public final class Scheduler {
    private let list: [Remembrance]
    private var random: AnyRandom

    public init(list: [Remembrance], random: some RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.list = list
        self.random = AnyRandom(random)
    }

    public func remindMeNow(at now: Date) -> Remembrance {
        list.randomElement(using: &random)!
    }
}

/// Lets tests pass a seeded generator while the app uses the system one.
struct AnyRandom: RandomNumberGenerator {
    private let nextValue: () -> UInt64

    init(_ base: some RandomNumberGenerator) {
        var base = base
        nextValue = { base.next() }
    }

    mutating func next() -> UInt64 { nextValue() }
}
