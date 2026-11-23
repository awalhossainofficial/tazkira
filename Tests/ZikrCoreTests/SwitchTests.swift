import Foundation
import Testing
@testable import ZikrCore

@Suite struct SwitchTests {
    func makeScheduler(_ count: Int, seed: UInt64) -> Scheduler {
        let scheduler = Scheduler(list: sampleList(count), random: SeededRandom(seed: seed))
        scheduler.start(at: start)
        return scheduler
    }

    func show(_ scheduler: Scheduler, times: Int) -> [String] {
        (0..<times).map { scheduler.remindMeNow(at: start.adding(minutes: Double($0))).id }
    }

    @Test(arguments: 1...20 as ClosedRange<UInt64>)
    func switchingOnJoinsTheCurrentRound(seed: UInt64) throws {
        let scheduler = makeScheduler(3, seed: seed)
        try scheduler.setOn("r3", false)
        let first = show(scheduler, times: 1)
        try scheduler.setOn("r3", true)
        let restOfRound = show(scheduler, times: 2)
        #expect(Set(first + restOfRound) == ["r1", "r2", "r3"])
    }

    @Test(arguments: 1...20 as ClosedRange<UInt64>)
    func switchingOffRemovesItAtOnce(seed: UInt64) throws {
        let scheduler = makeScheduler(3, seed: seed)
        _ = show(scheduler, times: 1)
        try scheduler.setOn("r2", false)
        #expect(!show(scheduler, times: 20).contains("r2"))
        #expect(!scheduler.isOn("r2"))
    }

    @Test func switchingOffTheLastOneIsRefused() throws {
        let scheduler = makeScheduler(2, seed: 1)
        try scheduler.setOn("r1", false)
        #expect(throws: LastRemembranceError.self) { try scheduler.setOn("r2", false) }
        #expect(scheduler.isOn("r2"))
    }

    @Test func aRestoredSnapshotKeepsSwitchedOffOnesOff() throws {
        let before = makeScheduler(3, seed: 1)
        try before.setOn("r1", false)
        let after = Scheduler(list: sampleList(3), state: before.state, random: SeededRandom(seed: 2))
        #expect(!show(after, times: 20).contains("r1"))
    }
}
