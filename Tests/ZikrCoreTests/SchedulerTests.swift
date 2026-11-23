import Foundation
import Testing
@testable import ZikrCore

@Test func remindMeNowShowsARemembrance() {
    let scheduler = Scheduler(list: sampleList(3), random: SeededRandom(seed: 1))
    let shown = scheduler.remindMeNow(at: start)
    #expect(sampleList(3).contains(shown))
}
