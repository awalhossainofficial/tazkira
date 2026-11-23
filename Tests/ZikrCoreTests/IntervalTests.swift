import Foundation
import Testing
@testable import ZikrCore

@Suite struct IntervalTests {
    func makeScheduler(interval: Int = 15) -> Scheduler {
        let scheduler = Scheduler(list: sampleList(3), state: SchedulerState(intervalMinutes: interval),
                                  random: SeededRandom(seed: 1))
        scheduler.start(at: start)
        return scheduler
    }

    @Test func aReminderComesAfterExactlyOneIntervalAndNotBefore() {
        let scheduler = makeScheduler()
        #expect(scheduler.tick(at: start.adding(minutes: 14.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 15)) != nil)
        #expect(scheduler.tick(at: start.adding(minutes: 29.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 30)) != nil)
    }

    @Test func remindMeNowStartsTheCountdownFresh() {
        let scheduler = makeScheduler()
        _ = scheduler.remindMeNow(at: start.adding(minutes: 10))
        #expect(scheduler.tick(at: start.adding(minutes: 24.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 25)) != nil)
    }

    @Test func changingTheIntervalStartsTheCountdownFresh() throws {
        let scheduler = makeScheduler()
        try scheduler.setInterval(5, at: start.adding(minutes: 3))
        #expect(scheduler.tick(at: start.adding(minutes: 7.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 8)) != nil)
    }

    @Test func intervalsOutsideOneTo180AreRefused() throws {
        let scheduler = makeScheduler()
        #expect(throws: IntervalError.self) { try scheduler.setInterval(0, at: start) }
        #expect(throws: IntervalError.self) { try scheduler.setInterval(181, at: start) }
        try scheduler.setInterval(180, at: start)
        try scheduler.setInterval(1, at: start)
        #expect(scheduler.state.intervalMinutes == 1)
    }
}
