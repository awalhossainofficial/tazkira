import Foundation
import Testing
@testable import ZikrCore

@Suite struct PauseTests {
    // New York has a daylight-saving jump on 14 March 2027.
    static let newYork: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    static func local(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = newYork
        formatter.timeZone = newYork.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text)!
    }

    func makeScheduler(state: SchedulerState = SchedulerState(), at now: Date = start) -> Scheduler {
        let scheduler = Scheduler(list: sampleList(3), state: state, calendar: Self.newYork,
                                  random: SeededRandom(seed: 1))
        scheduler.start(at: now)
        return scheduler
    }

    @Test func anHourPauseEndsAfterExactlyOneHourThenCountsAFullInterval() {
        let scheduler = makeScheduler()
        scheduler.pauseForAnHour(at: start)
        #expect(scheduler.pausedUntil == start.adding(minutes: 60))
        #expect(scheduler.tick(at: start.adding(minutes: 59.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 60)) == nil)
        #expect(scheduler.pausedUntil == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 74.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 75)) != nil)
    }

    @Test(arguments: [
        ("2027-01-10 22:00", "2027-01-11 06:00"),
        ("2027-01-10 04:30", "2027-01-10 06:00"),
        ("2027-03-13 22:00", "2027-03-14 06:00"),
    ])
    func untilTomorrowEndsAtSixInTheMorning(picked: String, ends: String) {
        let scheduler = makeScheduler(at: Self.local(picked))
        scheduler.pauseUntilTomorrow(at: Self.local(picked))
        #expect(scheduler.pausedUntil == Self.local(ends))
    }

    @Test func remindMeNowWorksDuringAPauseWithoutEndingIt() {
        let scheduler = makeScheduler()
        scheduler.pauseForAnHour(at: start)
        _ = scheduler.remindMeNow(at: start.adding(minutes: 10))
        #expect(scheduler.pausedUntil == start.adding(minutes: 60))
        #expect(scheduler.tick(at: start.adding(minutes: 30)) == nil)
    }

    @Test func resumeStartsTheCountdownFresh() {
        let scheduler = makeScheduler()
        scheduler.pauseForAnHour(at: start)
        scheduler.resume(at: start.adding(minutes: 20))
        #expect(scheduler.pausedUntil == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 34.99)) == nil)
        #expect(scheduler.tick(at: start.adding(minutes: 35)) != nil)
    }

    @Test func aRestoredSnapshotKeepsThePause() {
        let paused = makeScheduler()
        paused.pauseForAnHour(at: start)

        let reopened = makeScheduler(state: paused.state, at: start.adding(minutes: 30))
        #expect(reopened.pausedUntil == start.adding(minutes: 60))
        #expect(reopened.tick(at: start.adding(minutes: 50)) == nil)
    }

    @Test func aPauseThatEndedWhileClosedIsCleared() {
        let paused = makeScheduler()
        paused.pauseForAnHour(at: start)

        let reopened = makeScheduler(state: paused.state, at: start.adding(minutes: 90))
        #expect(reopened.pausedUntil == nil)
        #expect(reopened.state.pauseEnd == nil)
    }
}
