import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings()
    private lazy var shelf = ShelfController(settings: settings)
    private let monitor = ShakeMonitor()
    private var settingsWindow: SettingsWindowController?
    private var onboardingWindow: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.onChange = { [weak self] in self?.applySettings() }
        shelf.onOpenSettings = { [weak self] in self?.showSettings() }

        monitor.sensitivity = settings.sensitivity
        monitor.shouldIgnore = { [weak self] in self?.shelf.isDraggingOut ?? false }
        monitor.onShake = { [weak self] in self?.shelf.show() }
        monitor.onDragEnded = { [weak self] in self?.shelf.hideIfUnused() }
        monitor.start()

        if !settings.hasCompletedOnboarding {
            showOnboarding()
        }
    }

    /// Opening the app again is how to reach the shelf without a shake, since it has no menu bar icon.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        shelf.show()
        return false
    }

    private func applySettings() {
        monitor.sensitivity = settings.sensitivity
        shelf.applySettings()
    }

    private func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(settings: settings)
        }
        settingsWindow?.present()
    }

    private func showOnboarding() {
        let window = OnboardingWindowController()
        window.onFinish = { [weak self] in
            self?.settings.hasCompletedOnboarding = true
            self?.onboardingWindow = nil
        }
        onboardingWindow = window
        window.present()
    }
}
