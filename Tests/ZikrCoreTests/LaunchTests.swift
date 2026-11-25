import Foundation
import Testing
@testable import ZikrCore

@Suite struct LaunchTests {
    func launch(with state: SchedulerState) -> (Scheduler, Remembrance?) {
        let scheduler = Scheduler(list: sampleList(3), state: state, random: SeededRandom(seed: 1))
        scheduler.start(at: start)
        return (scheduler, scheduler.firstLaunchReminder(at: start))
    }

    @Test func firstLaunchShowsAReminderAtOnceAndLaterLaunchesDoNot() {
        let (first, shown) = launch(with: SchedulerState())
        #expect(shown != nil)
        #expect(first.state.intervalMinutes == 15)
        #expect(first.tick(at: start.adding(minutes: 14.99)) == nil)

        let (_, shownAgain) = launch(with: first.state)
        #expect(shownAgain == nil)
    }

    @Test func settingsSavedBeforeThisVersionCountAsLaunchedBefore() throws {
        let old = try JSONDecoder().decode(SchedulerState.self, from: Data(#"{"intervalMinutes":30}"#.utf8))
        #expect(old.intervalMinutes == 30)
        #expect(old.switchedOff.isEmpty)
        #expect(launch(with: old).1 == nil)
    }

    @Test func aMissingOrUnknownPillStyleLoadsAsIslandAndKeepsTheRest() throws {
        let decode = { (json: String) in try JSONDecoder().decode(SchedulerState.self, from: Data(json.utf8)) }
        #expect(try decode(#"{"intervalMinutes":30}"#).pillStyle == .island)

        let unknown = try decode(#"{"intervalMinutes":10,"switchedOff":["astaghfirullah"],"pillStyle":"lava"}"#)
        #expect(unknown.pillStyle == .island)
        #expect(unknown.intervalMinutes == 10)
        #expect(unknown.switchedOff == ["astaghfirullah"])

        let saved = try JSONEncoder().encode(SchedulerState(pillStyle: .peek))
        #expect(try JSONDecoder().decode(SchedulerState.self, from: saved).pillStyle == .peek)
    }
}
