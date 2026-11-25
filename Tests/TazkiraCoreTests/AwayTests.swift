import Foundation
import Testing
@testable import TazkiraCore

@Suite struct AwayTests {
    func makeScheduler() -> Scheduler {
        let scheduler = Scheduler(list: sampleList(3), random: SeededRandom(seed: 1))
        scheduler.start(at: start)
        return scheduler
    }

    @Test func noReminderWhileAsleepOrLocked() {
        let asleep = makeScheduler()
        asleep.didSleep(at: start.adding(minutes: 5))
        #expect(asleep.tick(at: start.adding(minutes: 60)) == nil)

        let locked = makeScheduler()
        locked.didLock(at: start.adding(minutes: 5))
        #expect(locked.tick(at: start.adding(minutes: 60)) == nil)
    }

    @Test func wakingStartsTheCountdownFresh() {
        let scheduler = makeScheduler()
        scheduler.didSleep(at: start.adding(minutes: 5))
        scheduler.didWake(at: start.adding(minutes: 100))
        #expect(scheduler.tick(at: start.adding(minutes: 114.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 115)) != nil)
    }

    @Test func unlockingStartsTheCountdownFresh() {
        let scheduler = makeScheduler()
        scheduler.didLock(at: start.adding(minutes: 5))
        scheduler.didUnlock(at: start.adding(minutes: 40))
        #expect(scheduler.tick(at: start.adding(minutes: 54.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 55)) != nil)
    }

    // Waking to the lock screen must not count; the clock starts at unlock.
    @Test func wakingWhileStillLockedWaitsForUnlock() {
        let scheduler = makeScheduler()
        scheduler.didLock(at: start.adding(minutes: 5))
        scheduler.didSleep(at: start.adding(minutes: 6))
        scheduler.didWake(at: start.adding(minutes: 100))
        #expect(scheduler.tick(at: start.adding(minutes: 200)) == nil)
        scheduler.didUnlock(at: start.adding(minutes: 210))
        #expect(scheduler.tick(at: start.adding(minutes: 224.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 225)) != nil)
    }
}
