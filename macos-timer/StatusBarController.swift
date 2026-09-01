import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let coordinator: AppCoordinator
    private var statusItem: NSStatusItem?
    private var hostingView: MenuBarHostingView<MenuBarTimerLabel>?
    private var panel: TimerFloatingPanel?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private var resignActiveObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        super.init()
        setupStatusItem()
        observeCoordinator()
    }

    deinit {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
        }
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
        }
        if let resignActiveObserver {
            NotificationCenter.default.removeObserver(resignActiveObserver)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        button.action = #selector(togglePanel)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        updateLabel()
    }

    private func observeCoordinator() {
        coordinator.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateLabel()
            }
            .store(in: &cancellables)
    }

    private func updateLabel() {
        guard let button = statusItem?.button else { return }

        let label = MenuBarTimerLabel(
            text: coordinator.menuBarText,
            showsTomatoIcon: coordinator.menuBarShowsTomatoIcon
        )

        if let hostingView {
            hostingView.rootView = label
            hostingView.invalidateIntrinsicContentSize()
        } else {
            let hostingView = MenuBarHostingView(rootView: label)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(hostingView)
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: button.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            ])
            self.hostingView = hostingView
        }

        let size = hostingView?.fittingSize ?? .zero
        statusItem?.length = max(size.width, 44)
    }

    @objc private func togglePanel() {
        if let panel, panel.isVisible {
            closePanel()
            return
        }

        guard let button = statusItem?.button else { return }

        let rootView = RootPanelView()
            .environmentObject(coordinator)
            .environmentObject(coordinator.simpleTimer)
            .environmentObject(coordinator.pomodoro)

        let panelController = GlassPanelViewController(rootView: rootView)

        let panel = TimerFloatingPanel(contentViewController: panelController)
        self.panel = panel

        let panelWidth = PanelLayout.width
        let panelHeight = PanelLayout.height
        let origin = panelOrigin(for: button, width: panelWidth, height: panelHeight)
        panel.setFrame(NSRect(origin: origin, size: NSSize(width: panelWidth, height: panelHeight)), display: true)
        panel.makeKeyAndOrderFront(nil)
        configureTransparentWindow(for: panel)
        startOutsideClickMonitoring()
    }

    private func configureTransparentWindow(for panel: NSPanel) {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.masksToBounds = false

        DispatchQueue.main.async {
            guard let window = panel.contentView?.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.masksToBounds = false
            window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    private func panelOrigin(for button: NSStatusBarButton, width: CGFloat, height: CGFloat) -> NSPoint {
        if let window = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = window.convertToScreen(buttonFrame)
            return NSPoint(
                x: screenFrame.midX - width / 2,
                y: screenFrame.minY - height - 8
            )
        }

        let mouseLocation = NSEvent.mouseLocation
        return NSPoint(
            x: mouseLocation.x - width / 2,
            y: mouseLocation.y - height - 8
        )
    }

    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }

            if self.shouldKeepPanelOpen(for: event) {
                return event
            }

            Task { @MainActor in
                self.closePanel()
            }

            return event
        }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                guard let self else { return }
                if self.shouldKeepPanelOpen(for: event) {
                    return
                }
                self.closePanel()
            }
        }

        resignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.shouldPreventPanelClose() {
                    return
                }
                self.closePanel()
            }
        }
    }

    private func shouldPreventPanelClose() -> Bool {
        coordinator.pomodoro.isEditorPresented || hasOpenAuxiliaryWindow()
    }

    private func shouldKeepPanelOpen(for event: NSEvent) -> Bool {
        if isClickOnStatusItem() {
            return true
        }

        if let window = event.window, isAuxiliaryWindow(window) {
            return true
        }

        return isMouseInsideRelevantWindows(at: NSEvent.mouseLocation)
    }

    private func hasOpenAuxiliaryWindow() -> Bool {
        NSApp.windows.contains { window in
            window.isVisible && isAuxiliaryWindow(window)
        }
    }

    private func isAuxiliaryWindow(_ window: NSWindow) -> Bool {
        guard let panel else { return false }
        if window === panel {
            return true
        }

        if window.parent === panel || window.sheetParent === panel {
            return true
        }

        var parent = window.parent
        while let current = parent {
            if current === panel {
                return true
            }
            parent = current.parent
        }

        return false
    }

    private func isMouseInsideRelevantWindows(at screenLocation: NSPoint) -> Bool {
        if isClickOnStatusItem() {
            return true
        }

        for window in NSApp.windows where window.isVisible {
            guard isAuxiliaryWindow(window) else { continue }
            if window.frame.contains(screenLocation) {
                return true
            }
        }

        return false
    }

    private func stopOutsideClickMonitoring() {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }

        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }

        if let resignActiveObserver {
            NotificationCenter.default.removeObserver(resignActiveObserver)
            self.resignActiveObserver = nil
        }
    }

    private func closePanel() {
        guard let panel, panel.isVisible else { return }
        stopOutsideClickMonitoring()
        panel.orderOut(nil)
    }

    private func isClickOnStatusItem() -> Bool {
        guard let button = statusItem?.button, let window = button.window else { return false }

        let clickLocation = NSEvent.mouseLocation
        let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        return buttonFrame.contains(clickLocation)
    }
}
