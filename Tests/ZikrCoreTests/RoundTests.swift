import Foundation
import Testing
@testable import ZikrCore

@Suite struct RoundTests {
    func shown(_ count: Int, from listSize: Int, seed: UInt64) -> [String] {
        let scheduler = Scheduler(list: sampleList(listSize), random: SeededRandom(seed: seed))
        scheduler.start(at: start)
        return (0..<count).map { scheduler.remindMeNow(at: start.adding(minutes: Double($0))).id }
    }

    @Test(arguments: 1...20 as ClosedRange<UInt64>)
    func nothingRepeatsWithinARound(seed: UInt64) {
        let ids = shown(15, from: 5, seed: seed)
        for round in stride(from: 0, to: 15, by: 5) {
            #expect(Set(ids[round..<round + 5]).count == 5)
        }
    }

    @Test(arguments: 1...50 as ClosedRange<UInt64>)
    func noRemembranceShowsTwiceInARowAcrossRounds(seed: UInt64) {
        let ids = shown(30, from: 3, seed: seed)
        for (a, b) in zip(ids, ids.dropFirst()) { #expect(a != b) }
    }

    @Test func theBuiltInListHasUniqueIds() {
        let ids = BuiltInList.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
