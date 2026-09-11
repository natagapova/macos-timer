import AppKit
import Foundation
import UserNotifications

@MainActor
final class PomodoroModel: ObservableObject {
    enum SessionState {
        case idle
        case running
        case paused
        case awaitingContinue
        case finished
    }

    enum Phase {
        case work
        case shortBreak
        case longBreak

        var title: String {
            switch self {
            case .work: return "work"
            case .shortBreak: return "break"
            case .longBreak: return "long break"
            }
        }
    }

    @Published private(set) var presets: [PomodoroPreset] = []
    @Published private(set) var sessionState: SessionState = .idle
    @Published private(set) var phase: Phase = .work
    @Published private(set) var currentRound: Int = 1
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var phaseTotalSeconds: Int = 0
    @Published var editingPreset: PomodoroPreset?
    @Published var isEditorPresented = false

    private var activePreset: PomodoroPreset?
    private var endDate: Date?
    private var tickTask: Task<Void, Never>?
    private let store = PomodoroStore()

    var isSessionActive: Bool {
        switch sessionState {
        case .running, .paused, .awaitingContinue:
            return true
        case .idle, .finished:
            return false
        }
    }

    var menuBarText: String {
        switch sessionState {
        case .idle, .finished:
            return ""
        case .running, .paused, .awaitingContinue:
            let prefix = phase == .work ? "w" : "b"
            return "\(prefix) \(TimerModel.formatTime(remainingSeconds))"
        }
    }

    var roundLabel: String {
        guard let activePreset else { return "" }
        return "round \(currentRound) of \(activePreset.roundsBeforeLongBreak)"
    }

    var roundsInCycle: Int {
        activePreset?.roundsBeforeLongBreak ?? 4
    }

    init() {
        presets = store.load()
    }

    func reloadPresets() {
        presets = store.load()
    }

    func start(preset: PomodoroPreset) {
        activePreset = preset
        currentRound = 1
        sessionState = .running
        beginPhase(.work, totalSeconds: preset.workMinutes * 60)
    }

    func pause() {
        guard sessionState == .running else { return }
        tickTask?.cancel()
        tickTask = nil
        sessionState = .paused
    }

    func resume() {
        guard sessionState == .paused else { return }
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        sessionState = .running
        startTicking()
    }

    func continueToNextPhase() {
        guard sessionState == .awaitingContinue else { return }
        sessionState = .running
        advanceToNextPhase()
    }

    func skipPhase() {
        guard isSessionActive, activePreset != nil else { return }

        tickTask?.cancel()
        tickTask = nil
        endDate = nil
        remainingSeconds = 0
        sessionState = .running
        advanceToNextPhase()
    }

    func stopSession() {
        tickTask?.cancel()
        tickTask = nil
        endDate = nil
        activePreset = nil
        remainingSeconds = 0
        phaseTotalSeconds = 0
        currentRound = 1
        sessionState = .idle
        phase = .work
    }

    func createPreset() {
        editingPreset = PomodoroPreset.newDraft()
        isEditorPresented = true
    }

    func editPreset(_ preset: PomodoroPreset) {
        editingPreset = preset
        isEditorPresented = true
    }

    func saveEditingPreset() {
        guard var preset = editingPreset else { return }

        preset.workMinutes = max(1, preset.workMinutes)
        preset.breakMinutes = max(1, preset.breakMinutes)
        preset.longBreakMinutes = max(1, preset.longBreakMinutes)
        preset.roundsBeforeLongBreak = max(1, preset.roundsBeforeLongBreak)

        var updated = presets
        if let index = updated.firstIndex(where: { $0.id == preset.id }) {
            updated[index] = preset
        } else {
            updated.append(preset)
        }
        presets = updated

        store.save(presets)
        editingPreset = nil
        isEditorPresented = false
    }

    func deletePreset(_ preset: PomodoroPreset) {
        var updated = presets
        updated.removeAll { $0.id == preset.id }
        presets = updated
        store.save(presets)

        if editingPreset?.id == preset.id {
            editingPreset = nil
            isEditorPresented = false
        }
    }

    func primaryAction() {
        switch sessionState {
        case .idle, .finished:
            break
        case .running:
            pause()
        case .paused:
            resume()
        case .awaitingContinue:
            continueToNextPhase()
        }
    }

    var primaryActionTitle: String {
        switch sessionState {
        case .idle, .finished:
            return "start"
        case .running:
            return "pause"
        case .paused:
            return "resume"
        case .awaitingContinue:
            return "continue"
        }
    }

    private func beginPhase(_ phase: Phase, totalSeconds: Int) {
        self.phase = phase
        phaseTotalSeconds = totalSeconds
        remainingSeconds = totalSeconds
        endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        startTicking()
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self?.tick()
            }
        }
    }

    private func tick() {
        guard let endDate else { return }
        remainingSeconds = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))

        if remainingSeconds <= 0 {
            completePhase()
        }
    }

    private func completePhase() {
        tickTask?.cancel()
        tickTask = nil
        self.endDate = nil
        remainingSeconds = 0

        playTransitionCue()
        sendPhaseNotification()

        guard let preset = activePreset else { return }

        if !preset.autoAdvance {
            sessionState = .awaitingContinue
            return
        }

        advanceToNextPhase()
    }

    private func advanceToNextPhase() {
        guard let preset = activePreset else { return }

        switch phase {
        case .work:
            if currentRound >= preset.roundsBeforeLongBreak {
                beginPhase(.longBreak, totalSeconds: preset.longBreakMinutes * 60)
            } else {
                beginPhase(.shortBreak, totalSeconds: preset.breakMinutes * 60)
            }
        case .shortBreak:
            currentRound += 1
            beginPhase(.work, totalSeconds: preset.workMinutes * 60)
        case .longBreak:
            currentRound = 1
            beginPhase(.work, totalSeconds: preset.workMinutes * 60)
        }

        sessionState = .running
    }

    private func playTransitionCue() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)

        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    private func sendPhaseNotification() {
        let content = UNMutableNotificationContent()
        content.title = "pomodoro"
        content.body = "\(phase.title) finished."

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
