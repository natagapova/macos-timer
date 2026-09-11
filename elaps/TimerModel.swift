import AppKit
import Foundation
import UserNotifications

@MainActor
final class TimerModel: ObservableObject {
    enum State {
        case idle
        case running
        case paused
        case finished
    }

    static let minDuration = 60
    static let maxDuration = 7_200

    @Published private(set) var state: State = .idle
    @Published private(set) var remainingSeconds: Int = 0
    @Published var selectedSeconds: Int = 30 * 60
    @Published var completionSound: CompletionSound

    private var totalSeconds: Int = 0
    private var endDate: Date?
    private var tickTask: Task<Void, Never>?
    private let completionSoundStore = CompletionSoundStore()

    init() {
        completionSound = completionSoundStore.load()
    }

    var isEditable: Bool {
        state == .idle || state == .finished
    }

    var readoutSeconds: Int {
        switch state {
        case .idle, .finished:
            return selectedSeconds
        case .running, .paused:
            return remainingSeconds
        }
    }

    var menuBarText: String {
        switch state {
        case .idle:
            return Self.formatTime(selectedSeconds)
        case .running, .paused:
            return Self.formatTime(remainingSeconds)
        case .finished:
            return Self.formatTime(0)
        }
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - Double(remainingSeconds) / Double(totalSeconds)
    }

    var scrubberFraction: Double {
        Double(selectedSeconds - Self.minDuration) / Double(Self.maxDuration - Self.minDuration)
    }

    func start() {
        switch state {
        case .idle, .finished:
            totalSeconds = selectedSeconds
            remainingSeconds = selectedSeconds
            endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            state = .running
            startTicking()
        case .paused:
            endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            state = .running
            startTicking()
        case .running:
            break
        }
    }

    func pause() {
        guard state == .running else { return }
        tickTask?.cancel()
        tickTask = nil
        state = .paused
    }

    func reset() {
        tickTask?.cancel()
        tickTask = nil
        endDate = nil
        totalSeconds = 0
        remainingSeconds = selectedSeconds
        state = .idle
    }

    func setDuration(_ seconds: Int) {
        guard isEditable else { return }
        selectedSeconds = Self.snapToMinute(seconds)
    }

    func setPreset(minutes: Int) {
        setDuration(minutes * 60)
    }

    func setCompletionSound(_ sound: CompletionSound) {
        completionSound = sound
        completionSoundStore.save(sound)
        if sound != .none {
            sound.play()
        }
    }

    func setScrubberFraction(_ fraction: Double) {
        let clamped = max(0, min(1, fraction))
        let minMinutes = Self.minDuration / 60
        let maxMinutes = Self.maxDuration / 60
        let minutes = minMinutes + Int((clamped * Double(maxMinutes - minMinutes)).rounded())
        setDuration(minutes * 60)
    }

    static func snapToMinute(_ seconds: Int) -> Int {
        let minutes = max(minDuration / 60, min(maxDuration / 60, Int((Double(seconds) / 60).rounded())))
        return minutes * 60
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
            finish()
        }
    }

    private func finish() {
        tickTask?.cancel()
        tickTask = nil
        self.endDate = nil
        remainingSeconds = 0
        state = .finished
        playCompletionCue()
        notifyFinished()
    }

    private func playCompletionCue() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        completionSound.play()
    }

    private func notifyFinished() {
        let content = UNMutableNotificationContent()
        content.title = "timer finished"
        content.body = "your \(Self.formatTime(totalSeconds)) timer is done."

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
