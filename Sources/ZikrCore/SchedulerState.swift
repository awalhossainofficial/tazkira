import Foundation

/// The settings that survive a restart.
public struct SchedulerState: Codable, Equatable, Sendable {
    public var intervalMinutes: Int

    public init(intervalMinutes: Int = 15) {
        self.intervalMinutes = intervalMinutes
    }
}

public struct IntervalError: Error, Equatable {
    public let minutes: Int
}
