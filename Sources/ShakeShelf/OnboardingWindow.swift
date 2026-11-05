import AppKit

/// Shown once. The app has no menu bar icon or Dock icon, so without this a first launch
/// would look like nothing happened.
final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    var onFinish: (() -> Void)?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        setUpContent(in: window)
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    func present() {
        showWindow(nil)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        onFinish?()
    }

    private func setUpContent(in window: NSWindow) {
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 80).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 80).isActive = true

        let title = NSTextField(labelWithString: "Welcome to ShakeShelf")
        title.font = .systemFont(ofSize: 22, weight: .semibold)

        let steps = NSStackView(views: [
            stepRow("hand.draw", "Shake while dragging", "Start dragging files in Finder, then shake the pointer."),
            stepRow("tray.and.arrow.down", "Collect", "Drop them on the shelf, then add more from other folders."),
            stepRow("folder", "Deliver", "Drag them from the shelf to where they belong."),
        ])
        steps.orientation = .vertical
        steps.alignment = .leading
        steps.spacing = 16

        let note = NSTextField(wrappingLabelWithString:
            "There's no menu bar icon. Open ShakeShelf again to show the shelf, and right-click it for settings.")
        note.textColor = .secondaryLabelColor
        note.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        note.alignment = .center

        let continueButton = NSButton(title: "Continue", target: window, action: #selector(NSWindow.performClose(_:)))
        continueButton.bezelStyle = .rounded
        continueButton.controlSize = .large
        continueButton.keyEquivalent = "\r"

        let footer = NSStackView(views: [LaunchAtLoginCheckbox(), NSView(), continueButton])
        footer.orientation = .horizontal

        let stack = NSStackView(views: [icon, title, steps, note, footer])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 20
        stack.edgeInsets = NSEdgeInsets(top: 28, left: 32, bottom: 24, right: 32)
        stack.setCustomSpacing(8, after: icon)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        window.contentView = content
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            content.widthAnchor.constraint(equalToConstant: 440),
            steps.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -64),
            note.widthAnchor.constraint(equalTo: steps.widthAnchor),
            footer.widthAnchor.constraint(equalTo: steps.widthAnchor),
        ])
        content.layoutSubtreeIfNeeded()
        window.setContentSize(stack.fittingSize)
    }

    private func stepRow(_ symbolName: String, _ heading: String, _ detail: String) -> NSView {
        let symbol = NSImageView(image: NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) ?? NSImage())
        symbol.symbolConfiguration = .init(pointSize: 24, weight: .regular)
        symbol.contentTintColor = .controlAccentColor
        // A fixed column keeps the text aligned whatever each symbol's width.
        symbol.widthAnchor.constraint(equalToConstant: 36).isActive = true

        let headingLabel = NSTextField(labelWithString: heading)
        headingLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.textColor = .secondaryLabelColor

        let text = NSStackView(views: [headingLabel, detailLabel])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2

        let row = NSStackView(views: [symbol, text])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14
        return row
    }
}
