import AppKit
import QuickLookThumbnailing
import UniformTypeIdentifiers

/// The shelf's contents and drop target. Panels from a background app receive their
/// first click, so the interactive views here all accept first mouse.
final class ShelfView: NSVisualEffectView {
    var onDrop: (([URL]) -> Void)?
    var onRemove: ((URL) -> Void)?
    var onToggle: ((URL) -> Void)?
    var onClear: (() -> Void)?
    var onHide: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onDragRow: ((URL, NSView, NSEvent) -> Void)?
    var onDragAll: ((NSView, NSEvent) -> Void)?

    private let grid = FileGridView()
    private let scrollView = NSScrollView()
    private let emptyState = NSStackView()
    private let separator = NSBox()
    private let footer = NSStackView()
    private let countLabel = NSTextField(labelWithString: "")
    private let dropHighlight = DropHighlightView()

    init() {
        super.init(frame: .zero)
        material = .sidebar
        blendingMode = .behindWindow
        // The panel is never the active app's window, so keep the material from going flat.
        state = .active
        maskImage = Self.roundedMask(radius: 16)
        registerForDraggedTypes([.fileURL])
        menu = makeContextMenu()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let side = radius * 2 + 1
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }

    func update(items: [URL], selection: Set<URL>) {
        grid.update(items: items, selection: selection) { [weak self] tile, url in
            tile.onToggle = { self?.onToggle?(url) }
            tile.onRemove = { self?.onRemove?(url) }
            tile.onDrag = { source, event in self?.onDragRow?(url, source, event) }
        }
        emptyState.isHidden = !items.isEmpty
        separator.isHidden = items.isEmpty
        footer.isHidden = items.isEmpty
        countLabel.stringValue = items.count == 1 ? "1 item" : "\(items.count) items"
        needsLayout = true
    }

    func preview(for url: URL) -> NSImage? {
        grid.preview(for: url)
    }

    func setMinimumTileWidth(_ width: CGFloat) {
        grid.minimumTileWidth = width
        needsLayout = true
    }

    override func layout() {
        super.layout()
        // The system restores its preferred scroller style, which takes width from the grid.
        scrollView.scrollerStyle = .overlay
        grid.fit(to: scrollView.contentView.bounds.size)
    }

    private func setUpLayout() {
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.documentView = grid
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrolled),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        let emptyIcon = NSImageView(image: NSImage(
            systemSymbolName: "tray.and.arrow.down",
            accessibilityDescription: nil
        ) ?? NSImage())
        emptyIcon.symbolConfiguration = .init(pointSize: 36, weight: .light)
        emptyIcon.contentTintColor = .tertiaryLabelColor
        // Image views register for drags and refuse them, which would block drops on the shelf.
        emptyIcon.unregisterDraggedTypes()
        let emptyLabel = NSTextField(labelWithString: "Drop files here")
        emptyLabel.textColor = .secondaryLabelColor
        emptyState.orientation = .vertical
        emptyState.spacing = 10
        emptyState.addArrangedSubview(emptyIcon)
        emptyState.addArrangedSubview(emptyLabel)
        emptyState.translatesAutoresizingMaskIntoConstraints = false

        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        countLabel.textColor = .secondaryLabelColor

        let clear = FirstMouseButton(title: "Clear", target: self, action: #selector(clearClicked))
        clear.bezelStyle = .rounded

        let dragAll = DragAllButton(title: "Drag All", target: nil, action: nil)
        dragAll.bezelStyle = .rounded
        dragAll.toolTip = "Drag everything on the shelf to a folder"
        dragAll.onDrag = { [weak self] source, event in self?.onDragAll?(source, event) }

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        [countLabel, spacer, clear, dragAll].forEach(footer.addArrangedSubview)
        footer.orientation = .horizontal
        footer.spacing = 8
        footer.translatesAutoresizingMaskIntoConstraints = false

        dropHighlight.translatesAutoresizingMaskIntoConstraints = false
        dropHighlight.isHidden = true

        [scrollView, emptyState, separator, footer, dropHighlight].forEach(addSubview)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor),

            emptyState.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyState.centerYAnchor.constraint(equalTo: centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -10),

            footer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            footer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            footer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            dropHighlight.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            dropHighlight.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            dropHighlight.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            dropHighlight.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings…", action: #selector(settingsClicked), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Hide Shelf", action: #selector(hideClicked), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit ShakeShelf", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "").target = NSApp
        return menu
    }

    @objc private func settingsClicked() {
        onOpenSettings?()
    }

    @objc private func hideClicked() {
        onHide?()
    }

    @objc private func scrolled() {
        grid.refreshTiles()
    }

    @objc private func clearClicked() {
        onClear?()
    }

    // MARK: Drop target

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let operation = preferredOperation(for: sender)
        dropHighlight.isHidden = operation.isEmpty
        return operation
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        dropHighlight.isHidden = true
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        dropHighlight.isHidden = true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        onDrop?(urls)
        return !urls.isEmpty
    }

    /// The shelf only stores references, so it asks for copy to keep the source file in place.
    private func preferredOperation(for sender: NSDraggingInfo) -> NSDragOperation {
        let mask = sender.draggingSourceOperationMask
        return [NSDragOperation.copy, .generic, .link].first(where: mask.contains) ?? []
    }
}

private final class DropHighlightView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func updateLayer() {
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
    }

    override var wantsUpdateLayer: Bool { true }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// Lays out tiles in as many columns as fit, stretching them to fill the width.
/// Tile views only exist for rows near the visible area, so the shelf's cost doesn't
/// grow with the number of files it holds.
private final class FileGridView: NSView {
    private static let padding: CGFloat = 12
    private static let gap: CGFloat = 8

    var minimumTileWidth: CGFloat = 105

    private var items: [URL] = []
    private var selection = Set<URL>()
    private var tiles: [URL: FileTileView] = [:]
    private var configure: ((FileTileView, URL) -> Void)?
    private var columns = 1
    private var tileWidth: CGFloat = 0
    private var tileHeight: CGFloat = 0
    private var viewportSize = NSSize.zero
    private let thumbnails: NSCache<NSURL, NSImage> = {
        let cache = NSCache<NSURL, NSImage>()
        cache.countLimit = 60
        return cache
    }()

    override var isFlipped: Bool { true }

    func update(
        items: [URL],
        selection: Set<URL>,
        configure: @escaping (FileTileView, URL) -> Void
    ) {
        let kept = Set(items)
        for url in self.items where !kept.contains(url) {
            thumbnails.removeObject(forKey: url as NSURL)
        }
        self.items = items
        self.selection = selection
        self.configure = configure
        refreshTiles()
    }

    func preview(for url: URL) -> NSImage? {
        tiles[url]?.preview ?? thumbnails.object(forKey: url as NSURL)
    }

    func fit(to size: NSSize) {
        viewportSize = size
        let available = size.width - Self.padding * 2
        columns = max(1, Int((available + Self.gap) / (minimumTileWidth + Self.gap)))
        tileWidth = (available - Self.gap * CGFloat(columns - 1)) / CGFloat(columns)
        tileHeight = FileTileView.height(forWidth: tileWidth)

        let rows = (items.count + columns - 1) / columns
        let contentHeight = Self.padding * 2 + CGFloat(rows) * tileHeight + CGFloat(max(rows - 1, 0)) * Self.gap
        setFrameSize(NSSize(width: size.width, height: max(contentHeight, size.height)))
        refreshTiles()
    }

    /// Creates tiles for the rows around the visible area and removes the rest.
    func refreshTiles() {
        guard tileHeight > 0, let configure else { return }
        let rowHeight = tileHeight + Self.gap
        let top = enclosingScrollView?.contentView.bounds.minY ?? 0
        let firstRow = max(Int((top - Self.padding) / rowHeight) - 1, 0)
        let lastRow = Int((top + viewportSize.height - Self.padding) / rowHeight) + 1
        let lower = min(firstRow * columns, items.count)
        let upper = min((lastRow + 1) * columns, items.count)
        let visible = items[lower..<upper]

        let visibleSet = Set(visible)
        for (url, tile) in tiles where !visibleSet.contains(url) {
            tile.cancelThumbnail()
            tile.removeFromSuperview()
            tiles[url] = nil
        }
        for (offset, url) in visible.enumerated() {
            let index = lower + offset
            let tile = tiles[url] ?? {
                let tile = FileTileView(url: url, thumbnails: thumbnails)
                configure(tile, url)
                addSubview(tile)
                tiles[url] = tile
                return tile
            }()
            tile.isSelected = selection.contains(url)
            let x = Self.padding + CGFloat(index % columns) * (tileWidth + Self.gap)
            let y = Self.padding + CGFloat(index / columns) * rowHeight
            tile.frame = backingAlignedRect(
                NSRect(x: x, y: y, width: tileWidth, height: tileHeight),
                options: .alignAllEdgesNearest
            )
        }
    }
}

private class FirstMouseButton: NSButton {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Looks like a regular button but starts a drag instead of sending an action.
private final class DragAllButton: FirstMouseButton {
    var onDrag: ((NSView, NSEvent) -> Void)?

    override func mouseDown(with event: NSEvent) {
        isHighlighted = true
        let next = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged])
        isHighlighted = false
        if let next, next.type == .leftMouseDragged {
            onDrag?(self, next)
        }
    }
}

/// A file's preview and name, selected the way Finder's icon view shows it.
/// Clicking selects it, dragging starts a drag out of the shelf.
private final class FileTileView: NSView {
    private static let inset: CGFloat = 8
    private static let labelGap: CGFloat = 2
    private static let labelFont = NSFont.systemFont(ofSize: 12)
    /// Two lines, like Finder's icon view.
    private static let labelHeight: CGFloat = ceil(labelFont.boundingRectForFont.height * 2)
    private static let removeSize: CGFloat = 20
    /// Slightly above the largest size a tile's image reaches before another column fits.
    private static let thumbnailSide: CGFloat = 140

    var onToggle: (() -> Void)?
    var onRemove: (() -> Void)?
    var onDrag: ((NSView, NSEvent) -> Void)?
    var isSelected = false {
        didSet { updateAppearance() }
    }

    var preview: NSImage? { imageView.image }

    private let imageView = NSImageView()
    private let imageBackground = NSView()
    private let labelBackground = NSView()
    private let thumbnails: NSCache<NSURL, NSImage>
    private var thumbnailRequest: QLThumbnailGenerator.Request?
    private let nameLabel: NSTextField
    private let removeButton: FirstMouseButton
    private var isHovered = false {
        didSet { updateAppearance() }
    }
    private var hasDragged = false

    static func height(forWidth width: CGFloat) -> CGFloat {
        width + labelGap + labelHeight + 2
    }

    init(url: URL, thumbnails: NSCache<NSURL, NSImage>) {
        self.thumbnails = thumbnails
        nameLabel = NSTextField(wrappingLabelWithString: url.lastPathComponent)
        removeButton = FirstMouseButton(
            image: NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Remove") ?? NSImage(),
            target: nil,
            action: nil
        )
        super.init(frame: .zero)
        toolTip = url.path

        for background in [imageBackground, labelBackground] {
            background.wantsLayer = true
            background.layer?.cornerRadius = 5
            addSubview(background)
        }

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.unregisterDraggedTypes()
        addSubview(imageView)

        nameLabel.font = Self.labelFont
        nameLabel.alignment = .center
        nameLabel.maximumNumberOfLines = 2
        nameLabel.cell?.truncatesLastVisibleLine = true
        nameLabel.isSelectable = false
        addSubview(nameLabel)

        removeButton.target = self
        removeButton.action = #selector(removeClicked)
        removeButton.isBordered = false
        removeButton.symbolConfiguration = .init(pointSize: Self.removeSize - 2, weight: .regular)
        removeButton.contentTintColor = .secondaryLabelColor
        removeButton.isHidden = true
        addSubview(removeButton)

        loadThumbnail(for: url)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override var isFlipped: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func layout() {
        super.layout()
        let inset = Self.inset
        let imageSide = bounds.width - inset * 2
        imageView.frame = NSRect(x: inset, y: inset, width: imageSide, height: imageSide)
        imageBackground.frame = imageView.frame.insetBy(dx: -6, dy: -6)

        // The label hugs its text so the selection behind it is only as wide as the name.
        let available = NSRect(x: 0, y: 0, width: bounds.width - 4, height: Self.labelHeight)
        let text = nameLabel.cell?.cellSize(forBounds: available) ?? available.size
        let width = min(ceil(text.width), available.width)
        let height = min(ceil(text.height), Self.labelHeight)
        nameLabel.frame = NSRect(
            x: (bounds.width - width) / 2,
            y: imageView.frame.maxY + inset + Self.labelGap,
            width: width,
            height: height
        )
        labelBackground.frame = nameLabel.frame.insetBy(dx: -4, dy: -1)
        removeButton.frame = NSRect(
            x: bounds.width - Self.removeSize - 4,
            y: 4,
            width: Self.removeSize,
            height: Self.removeSize
        )
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func mouseDown(with event: NSEvent) {
        hasDragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !hasDragged else { return }
        hasDragged = true
        onDrag?(self, event)
    }

    override func mouseUp(with event: NSEvent) {
        if !hasDragged { onToggle?() }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    private func updateAppearance() {
        removeButton.isHidden = !isHovered
        nameLabel.textColor = isSelected ? .alternateSelectedControlTextColor : .labelColor
        effectiveAppearance.performAsCurrentDrawingAppearance {
            // Label colors resolve oddly on a vibrant background, so the box is a plain tint.
            let isDark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let box = isDark ? NSColor.white.withAlphaComponent(0.12) : NSColor.black.withAlphaComponent(0.08)
            imageBackground.layer?.backgroundColor = isSelected ? box.cgColor : NSColor.clear.cgColor
            labelBackground.layer?.backgroundColor = isSelected
                ? NSColor.selectedContentBackgroundColor.cgColor
                : NSColor.clear.cgColor
        }
    }

    func cancelThumbnail() {
        if let thumbnailRequest {
            QLThumbnailGenerator.shared.cancel(thumbnailRequest)
        }
    }

    private func loadThumbnail(for url: URL) {
        if let cached = thumbnails.object(forKey: url as NSURL) {
            imageView.image = cached
            return
        }
        imageView.image = NSWorkspace.shared.icon(forFile: url.path)
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: NSSize(width: Self.thumbnailSide, height: Self.thumbnailSide),
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: .all
        )
        thumbnailRequest = request
        // Finder outlines document pages so a white page stands out from its background.
        let isDocument = !(UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) ?? false)
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self, thumbnails] thumbnail, _ in
            guard let thumbnail else { return }
            let image = isDocument && thumbnail.type == .thumbnail
                ? Self.outlined(thumbnail.nsImage)
                : thumbnail.nsImage
            DispatchQueue.main.async {
                thumbnails.setObject(image, forKey: url as NSURL)
                self?.imageView.image = image
            }
        }
    }

    /// Adds a hairline border and a soft shadow, with room for the shadow around the page.
    private static func outlined(_ page: NSImage) -> NSImage {
        let margin: CGFloat = 3
        let size = NSSize(width: page.size.width + margin * 2, height: page.size.height + margin * 2)
        return NSImage(size: size, flipped: false) { _ in
            let rect = NSRect(origin: NSPoint(x: margin, y: margin), size: page.size)
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = .black.withAlphaComponent(0.25)
            shadow.shadowBlurRadius = 2
            shadow.shadowOffset = NSSize(width: 0, height: -0.5)
            shadow.set()
            NSColor.white.setFill()
            rect.fill()
            NSGraphicsContext.restoreGraphicsState()
            page.draw(in: rect)
            NSColor.black.withAlphaComponent(0.15).setStroke()
            NSBezierPath(rect: rect.insetBy(dx: 0.25, dy: 0.25)).stroke()
            return true
        }
    }

    @objc private func removeClicked() {
        onRemove?()
    }
}
