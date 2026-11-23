import Foundation
@testable import ZikrCore

/// Repeatable shuffles so Round tests give the same answer every run.
struct SeededRandom: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

func sampleList(_ count: Int) -> [Remembrance] {
    (1...count).map { Remembrance(id: "r\($0)", kind: .zikr, arabic: "ع\($0)", transliteration: "t\($0)", meaning: "m\($0)", source: "s\($0)") }
}

let start = Date(timeIntervalSince1970: 1_800_000_000)

extension Date {
    func adding(minutes: Double) -> Date { addingTimeInterval(minutes * 60) }
}
