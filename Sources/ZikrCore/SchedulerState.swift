import Foundation

/// The settings that survive a restart.
public struct SchedulerState: Codable, Equatable, Sendable {
    public var intervalMinutes: Int
    public var pauseEnd: Date?
    public var switchedOff: Set<String>

    public init(intervalMinutes: Int = 15, pauseEnd: Date? = nil, switchedOff: Set<String> = []) {
        self.intervalMinutes = intervalMinutes
        self.pauseEnd = pauseEnd
        self.switchedOff = switchedOff
    }

    // Settings saved before a field existed must still load.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intervalMinutes = try container.decode(Int.self, forKey: .intervalMinutes)
        pauseEnd = try container.decodeIfPresent(Date.self, forKey: .pauseEnd)
        switchedOff = try container.decodeIfPresent(Set<String>.self, forKey: .switchedOff) ?? []
    }
}

public struct IntervalError: Error, Equatable {
    public let minutes: Int
}

/// At least one Remembrance must stay switched on.
public struct LastRemembranceError: Error, Equatable {}
