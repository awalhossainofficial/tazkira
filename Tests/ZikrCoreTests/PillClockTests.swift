import Foundation
import Testing
import ZikrCore

@Suite struct PillClockTests {
    @Test func eachReminderGetsTheFullEightSeconds() {
        var clock = PillClock()
        clock.show(at: start)
        #expect(clock.hidesAt == start + 8)

        clock.show(at: start + 5)
        #expect(clock.hidesAt == start + 13)
    }

    @Test func hoveringStopsTheClockAndLeavingResumesIt() {
        var clock = PillClock()
        clock.show(at: start)
        clock.hover(true, at: start + 3)
        #expect(clock.hidesAt == nil)
        clock.hover(false, at: start + 20)
        #expect(clock.hidesAt == start + 25)

        // Leaving with almost nothing left still gives one second.
        var late = PillClock()
        late.show(at: start)
        late.hover(true, at: start + 7.8)
        late.hover(false, at: start + 10)
        #expect(late.hidesAt == start + 11)
    }

    @Test func aReminderArrivingWhileHoveredWaitsForTheMouseToLeave() {
        var clock = PillClock()
        clock.show(at: start)
        clock.hover(true, at: start + 6)
        clock.show(at: start + 7)
        #expect(clock.hidesAt == nil)
        clock.hover(false, at: start + 30)
        #expect(clock.hidesAt == start + 38)
    }
}
