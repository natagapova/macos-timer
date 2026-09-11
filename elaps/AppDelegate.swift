import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let simpleTimer = TimerModel()
    private let pomodoro = PomodoroModel()
    private lazy var coordinator = AppCoordinator(simpleTimer: simpleTimer, pomodoro: pomodoro)

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(coordinator: coordinator)
        simpleTimer.requestNotificationPermission()
    }
}
