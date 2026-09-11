import Combine
import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    enum PanelTab: Hashable {
        case simple
        case pomodoro
    }

    let simpleTimer: TimerModel
    let pomodoro: PomodoroModel

    @Published var selectedPanel: PanelTab = .simple
    @Published var appearance: AppAppearance
    @Published private(set) var hasOpenedPanel = false

    private var cancellables = Set<AnyCancellable>()
    private let appearanceStore = AppAppearanceStore()

    init(simpleTimer: TimerModel, pomodoro: PomodoroModel) {
        self.simpleTimer = simpleTimer
        self.pomodoro = pomodoro
        appearance = appearanceStore.load()
        appearance.apply()
        observeTimers()
    }

    func setAppearance(_ appearance: AppAppearance) {
        guard appearance != self.appearance else { return }
        self.appearance = appearance
        appearanceStore.save(appearance)
        appearance.apply()
    }

    func markPanelOpened() {
        guard !hasOpenedPanel else { return }
        hasOpenedPanel = true
    }

    var menuBarText: String {
        if pomodoro.isSessionActive {
            return pomodoro.menuBarText
        }
        if simpleTimer.state == .running || simpleTimer.state == .paused {
            return simpleTimer.menuBarText
        }
        if hasOpenedPanel {
            return idlePreviewText
        }
        return simpleTimer.menuBarText
    }

    private var idlePreviewText: String {
        switch selectedPanel {
        case .simple:
            return simpleTimer.menuBarText
        case .pomodoro:
            let preset = pomodoro.presets.first ?? .classic
            return "w \(TimerModel.formatTime(preset.workMinutes * 60))"
        }
    }

    func startPomodoro(preset: PomodoroPreset) {
        if simpleTimer.state == .running || simpleTimer.state == .paused {
            simpleTimer.reset()
        }
        pomodoro.start(preset: preset)
    }

    private func observeTimers() {
        simpleTimer.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.objectWillChange.send()
                if self.simpleTimer.state == .running {
                    self.pomodoro.stopSession()
                }
            }
            .store(in: &cancellables)

        pomodoro.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
