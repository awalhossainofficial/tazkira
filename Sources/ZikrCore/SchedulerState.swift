import Foundation

public struct SchedulerState: Codable, Equatable, Sendable {
    public var intervalMinutes: Int
    public var pauseEnd: Date?
    public var switchedOff: Set<String>
    public var hasLaunchedBefore: Bool
    public var pillStyle: PillStyleChoice

    public init(intervalMinutes: Int = 15, pauseEnd: Date? = nil, switchedOff: Set<String> = [],
                hasLaunchedBefore: Bool = false, pillStyle: PillStyleChoice = .island) {
        self.intervalMinutes = intervalMinutes
        self.pauseEnd = pauseEnd
        self.switchedOff = switchedOff
        self.hasLaunchedBefore = hasLaunchedBefore
        self.pillStyle = pillStyle
    }

    // Settings saved before a field existed must still load.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intervalMinutes = try container.decode(Int.self, forKey: .intervalMinutes)
        pauseEnd = try container.decodeIfPresent(Date.self, forKey: .pauseEnd)
        switchedOff = try container.decodeIfPresent(Set<String>.self, forKey: .switchedOff) ?? []
        // Anything saved at all means the app has run before.
        hasLaunchedBefore = try container.decodeIfPresent(Bool.self, forKey: .hasLaunchedBefore) ?? true
        // A style this version doesn't know must not throw away the rest of the settings.
        pillStyle = (try? container.decodeIfPresent(String.self, forKey: .pillStyle))
            .flatMap { $0 }.flatMap(PillStyleChoice.init(rawValue:)) ?? .island
    }
}

/// Which Pill Style the user picked.
public enum PillStyleChoice: String, Codable, CaseIterable, Sendable {
    case island, wings, dropCard, peek
}

public struct IntervalError: Error, Equatable {
    public let minutes: Int
}

public struct LastRemembranceError: Error, Equatable {}
