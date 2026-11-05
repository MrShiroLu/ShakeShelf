import AppKit

/// Owns the shelf's files and panel, and acts as the source for drags out of it.
final class ShelfController: NSObject, NSDraggingSource {
    private static let maxDragPreviews = 6

    var onOpenSettings: (() -> Void)?
    private(set) var isDraggingOut = false

    private var items: [URL] = []
    private var selection = Set<URL>()
    private var draggedItems: [URL] = []
    private let settings: Settings
    private lazy var shelfView = makeShelfView()
    private lazy var panel = makePanel()

    init(settings: Settings) {
        self.settings = settings
    }

    var isVisible: Bool { panel.isVisible }

    func show() {
        if !panel.isVisible {
            removeMissingItems()
            reload()
            panel.setFrameOrigin(cornerOrigin())
        }
        panel.orderFrontRegardless()
    }

    func applySettings() {
        shelfView.setMinimumTileWidth(settings.previewSize.tileWidth)
        let size = shelfSize
        panel.minSize = NSSize(width: size.width, height: 320)
        panel.setContentSize(size)
        panel.setFrameOrigin(cornerOrigin())
    }

    func hide() {
        panel.orderOut(nil)
    }

    /// Closes a shelf that was opened by a shake but never received anything.
    func hideIfUnused() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            if items.isEmpty, !isDraggingOut { panel.orderOut(nil) }
        }
    }

    func clear() {
        items = []
        selection = []
        reload()
        panel.orderOut(nil)
    }

    private func add(_ urls: [URL]) {
        var known = Set(items)
        for url in urls.map(\.standardizedFileURL) where known.insert(url).inserted {
            items.append(url)
        }
        reload()
    }

    private func remove(_ urls: [URL]) {
        let removed = Set(urls)
        items.removeAll(where: removed.contains)
        selection.subtract(urls)
        reload()
    }

    private func toggleSelection(of url: URL) {
        if selection.remove(url) == nil { selection.insert(url) }
        reload()
    }

    private func removeMissingItems() {
        let missing = items.filter { !FileManager.default.fileExists(atPath: $0.path) }
        if !missing.isEmpty { remove(missing) }
    }

    private func reload() {
        shelfView.update(items: items, selection: selection)
    }

    /// Three rows and columns of tiles at the current preview size.
    private var shelfSize: NSSize {
        let tile = settings.previewSize.tileWidth
        return NSSize(width: 40 + tile * 3, height: 82 + (tile + 36) * 3)
    }

    /// The chosen corner of the screen under the cursor, clear of the Dock and menu bar.
    private func cornerOrigin() -> NSPoint {
        let cursor = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(cursor) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return panel.frame.origin }
        let size = panel.frame.size
        let margin: CGFloat = 16
        switch settings.corner {
        case .bottomRight: return NSPoint(x: visible.maxX - size.width - margin, y: visible.minY + margin)
        case .bottomLeft: return NSPoint(x: visible.minX + margin, y: visible.minY + margin)
        case .topRight: return NSPoint(x: visible.maxX - size.width - margin, y: visible.maxY - size.height - margin)
        case .topLeft: return NSPoint(x: visible.minX + margin, y: visible.maxY - size.height - margin)
        }
    }

    // MARK: Dragging out

    private func beginDrag(_ urls: [URL], from view: NSView, event: NSEvent) {
        let location = view.convert(event.locationInWindow, from: nil)
        let draggingItems = urls.enumerated().map { index, url -> NSDraggingItem in
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            guard index < Self.maxDragPreviews else {
                item.setDraggingFrame(NSRect(origin: location, size: NSSize(width: 1, height: 1)), contents: nil)
                return item
            }
            let image = shelfView.preview(for: url) ?? NSWorkspace.shared.icon(forFile: url.path)
            let scale = 64 / max(image.size.width, image.size.height, 1)
            let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
            let offset = CGFloat(min(index, 5)) * 6
            let frame = NSRect(
                x: location.x - size.width / 2 + offset,
                y: location.y - size.height / 2 - offset,
                width: size.width,
                height: size.height
            )
            item.setDraggingFrame(frame, contents: image)
            return item
        }
        draggedItems = urls
        isDraggingOut = true
        view.beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        context == .outsideApplication ? [.copy, .move, .generic] : []
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        isDraggingOut = false
        if !operation.isEmpty { remove(draggedItems) }
        draggedItems = []
        removeMissingItems()
        if items.isEmpty { panel.orderOut(nil) }
    }

    // MARK: Setup

    private func makeShelfView() -> ShelfView {
        let view = ShelfView()
        view.onDrop = { [weak self] urls in self?.add(urls) }
        view.onRemove = { [weak self] url in
            guard let self else { return }
            remove([url])
            if items.isEmpty { panel.orderOut(nil) }
        }
        view.onToggle = { [weak self] url in self?.toggleSelection(of: url) }
        view.onClear = { [weak self] in self?.clear() }
        view.onHide = { [weak self] in self?.hide() }
        view.onOpenSettings = { [weak self] in self?.onOpenSettings?() }
        view.setMinimumTileWidth(settings.previewSize.tileWidth)
        view.onDragRow = { [weak self] url, source, event in
            guard let self else { return }
            let urls = selection.contains(url) ? items.filter(selection.contains) : [url]
            beginDrag(urls, from: source, event: event)
        }
        view.onDragAll = { [weak self] source, event in
            guard let self, !items.isEmpty else { return }
            beginDrag(items, from: source, event: event)
        }
        return view
    }

    private func makePanel() -> NSPanel {
        let panel = ShelfPanel(
            contentRect: NSRect(origin: .zero, size: shelfSize),
            styleMask: [.borderless, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.minSize = NSSize(width: shelfSize.width, height: 320)
        panel.contentView = shelfView
        return panel
    }
}

/// A borderless panel can't become key by default, which Escape needs.
private final class ShelfPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}
