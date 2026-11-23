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
        #expect(launch(with: old).1 == nil)
    }
}
