import Foundation

struct PomodoroStore {
    private let key = "pomodoro.presets"

    func load() -> [PomodoroPreset] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let presets = try? JSONDecoder().decode([PomodoroPreset].self, from: data)
        else {
            return [.classic]
        }
        return presets
    }

    func save(_ presets: [PomodoroPreset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
