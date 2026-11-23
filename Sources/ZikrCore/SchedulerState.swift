import Foundation

/// The settings that survive a restart.
public struct SchedulerState: Codable, Equatable, Sendable {
    public var intervalMinutes: Int
    public var pauseEnd: Date?

    public init(intervalMinutes: Int = 15, pauseEnd: Date? = nil) {
        self.intervalMinutes = intervalMinutes
        self.pauseEnd = pauseEnd
    }
}

public struct IntervalError: Error, Equatable {
    public let minutes: Int
}
