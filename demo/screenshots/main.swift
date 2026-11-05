// Renders the settings window to docs/images/settings.png. See demo/screenshots/render.sh.
import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let output = URL(fileURLWithPath: "docs/images")
try! FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

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

let rep = renderWindow(SettingsWindowController(settings: Settings()).window)
try! rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("settings.png"))
print("Rendered to \(output.path)")
