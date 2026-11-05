import AppKit
import OSLog
import ShakeCore

/// Watches mouse drags in other apps and reports when files are shaken.
final class ShakeMonitor {
    var onShake: (() -> Void)?
    var onDragEnded: (() -> Void)?
    var shouldIgnore: (() -> Bool)?
    var sensitivity = ShakeSensitivity.medium {
        didSet { detector = ShakeDetector(sensitivity: sensitivity) }
    }

    private let logger = Logger(subsystem: "com.vyke.ShakeShelf", category: "shake")
    private let dragPasteboard = NSPasteboard(name: .drag)
    private var detector = ShakeDetector()
    private var baselineChangeCount = 0
    private var didShake = false
    private var monitors: [Any] = []

    func start() {
        let handlers: [(NSEvent.EventTypeMask, (NSEvent) -> Void)] = [
            (.leftMouseDown, { [weak self] _ in self?.mouseDown() }),
            (.leftMouseDragged, { [weak self] event in self?.mouseDragged(event) }),
            (.leftMouseUp, { [weak self] _ in self?.mouseUp() }),
        ]
        monitors = handlers.compactMap { mask, handler in
            NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
        }
    }

    private func mouseDown() {
        detector.reset()
        didShake = false
        baselineChangeCount = dragPasteboard.changeCount
    }

    private func mouseDragged(_ event: NSEvent) {
        guard detector.add(NSEvent.mouseLocation, at: event.timestamp) else { return }
        let hasFiles = isDraggingFiles
        logger.info("Shake detected, dragging files: \(hasFiles)")
        if hasFiles, shouldIgnore?() != true {
            didShake = true
            onShake?()
        }
    }

    private func mouseUp() {
        detector.reset()
        if didShake { onDragEnded?() }
    }

    /// The drag pasteboard only changes once a real drag starts, which separates
    /// file drags from text selections and window moves.
    private var isDraggingFiles: Bool {
        guard dragPasteboard.changeCount != baselineChangeCount else { return false }
        return dragPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
    }
}
