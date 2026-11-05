// Renders the real shelf view to PNGs in docs/images. See demo/screenshots/render.sh.
import AppKit

let app = NSApplication.shared
app.applicationIconImage = NSImage(contentsOfFile: "Resources/AppIcon.icns")
app.setActivationPolicy(.prohibited)
let mock = URL(fileURLWithPath: "demo/mock-files")
let urls = [
    "Pictures/aurora.png", "Documents/product-brief.pdf", "Pictures/sunset.png",
    "Projects/logo.svg", "Documents/meeting-notes.md", "Pictures/dunes.png",
    "Projects/Brand Kit", "Documents/budget.csv", "Projects/Brand Kit/palette.png",
].map { mock.appendingPathComponent($0).standardizedFileURL }
let output = URL(fileURLWithPath: "docs/images")
try! FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func hiddenOverlay(in view: NSView) -> NSView? {
    view.subviews.first { String(describing: type(of: $0)) == "DropHighlightView" }
}

func render(items: [URL], selection: Set<URL>, dark: Bool, highlighted: Bool = false) -> NSBitmapImageRep {
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 355, height: 505), styleMask: [.borderless], backing: .buffered, defer: false)
    window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    let view = ShelfView()
    window.contentView = view
    view.update(items: items, selection: selection)
    view.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(3))
    hiddenOverlay(in: view)?.isHidden = !highlighted
    view.needsLayout = true
    view.layoutSubtreeIfNeeded()
    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds, to: rep)
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
}

func hero(_ rep: NSBitmapImageRep) -> NSBitmapImageRep {
    let size = NSSize(width: 1280, height: 800)
    let canvas = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: 2560, pixelsHigh: 1600, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    canvas.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)
    let rect = NSRect(origin: .zero, size: size)
    NSGradient(colors: [.systemIndigo, .systemPurple, .systemPink])?.draw(in: rect, angle: 35)
    let shelf = NSRect(x: (size.width - 355) / 2, y: (size.height - 477) / 2, width: 355, height: 505)
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 40
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    shadow.set()
    rep.draw(in: shelf, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    NSGraphicsContext.restoreGraphicsState()
    return canvas
}

/// Window chrome isn't part of the content view, so the background is drawn here.
func renderWindow(_ window: NSWindow?, dark: Bool = true) -> NSBitmapImageRep {
    let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)!
    window?.appearance = appearance
    let view = window!.contentView!
    view.layoutSubtreeIfNeeded()
    let content = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds, to: content)
    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    appearance.performAsCurrentDrawingAppearance {
        NSColor.windowBackgroundColor.setFill()
        view.bounds.fill()
    }
    content.draw(in: view.bounds, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let selected: Set<URL> = [urls[2]]
let dark = render(items: urls, selection: selected, dark: true)
save(dark, "shelf-dark.png")
save(render(items: urls, selection: selected, dark: false), "shelf-light.png")
save(render(items: [], selection: [], dark: true, highlighted: true), "shelf-drop.png")
save(hero(dark), "hero.png")
save(renderWindow(OnboardingWindowController().window), "welcome.png")
save(renderWindow(SettingsWindowController(settings: Settings()).window), "settings.png")
print("Rendered to \(output.path)")
