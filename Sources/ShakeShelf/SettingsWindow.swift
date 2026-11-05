import AppKit
import ShakeCore

final class SettingsWindowController: NSWindowController {
    private let settings: Settings
    private let launchAtLogin = LaunchAtLoginCheckbox()

    init(settings: Settings) {
        self.settings = settings
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        setUpContent(in: window)
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    func present() {
        launchAtLogin.refresh()
        showWindow(nil)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func setUpContent(in window: NSWindow) {
        let sensitivity = popUp(ShakeSensitivity.allCases.map(\.title), #selector(sensitivityChanged))
        sensitivity.selectItem(at: ShakeSensitivity.allCases.firstIndex(of: settings.sensitivity) ?? 0)
        let corner = popUp(ShelfCorner.allCases.map(\.title), #selector(cornerChanged))
        corner.selectItem(at: ShelfCorner.allCases.firstIndex(of: settings.corner) ?? 0)
        let size = popUp(PreviewSize.allCases.map(\.title), #selector(sizeChanged))
        size.selectItem(at: PreviewSize.allCases.firstIndex(of: settings.previewSize) ?? 0)

        let grid = NSGridView(views: [
            [NSTextField(labelWithString: "Shake sensitivity:"), sensitivity],
            [NSTextField(labelWithString: "Shelf position:"), corner],
            [NSTextField(labelWithString: "Preview size:"), size],
            [NSGridCell.emptyContentView, launchAtLogin],
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 8
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(grid)
        window.contentView = content
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            grid.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            sensitivity.widthAnchor.constraint(equalToConstant: 160),
            corner.widthAnchor.constraint(equalTo: sensitivity.widthAnchor),
            size.widthAnchor.constraint(equalTo: sensitivity.widthAnchor),
        ])
    }

    private func popUp(_ titles: [String], _ action: Selector) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.addItems(withTitles: titles)
        button.target = self
        button.action = action
        return button
    }

    @objc private func sensitivityChanged(_ sender: NSPopUpButton) {
        settings.sensitivity = ShakeSensitivity.allCases[sender.indexOfSelectedItem]
    }

    @objc private func cornerChanged(_ sender: NSPopUpButton) {
        settings.corner = ShelfCorner.allCases[sender.indexOfSelectedItem]
    }

    @objc private func sizeChanged(_ sender: NSPopUpButton) {
        settings.previewSize = PreviewSize.allCases[sender.indexOfSelectedItem]
    }
}
