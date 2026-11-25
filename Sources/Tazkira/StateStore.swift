import Foundation
import TazkiraCore

enum StateStore {
    private static let key = "schedulerState"

    static func load() -> SchedulerState {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(SchedulerState.self, from: data) else { return SchedulerState() }
        return state
    }

    static func save(_ state: SchedulerState) {
        if let data = try? JSONEncoder().encode(state) { UserDefaults.standard.set(data, forKey: key) }
    }
}
