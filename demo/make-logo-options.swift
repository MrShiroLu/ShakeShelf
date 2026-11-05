// Draws the app icon candidates into docs/logo-options. Run from the project root:
//   swift demo/make-logo-options.swift
import AppKit

let output = URL(fileURLWithPath: "docs/logo-options")
let body = NSRect(x: 100, y: 100, width: 824, height: 824)

func hex(_ value: UInt32) -> NSColor {
    NSColor(
        srgbRed: CGFloat((value >> 16) & 255) / 255,
        green: CGFloat((value >> 8) & 255) / 255,
        blue: CGFloat(value & 255) / 255,
        alpha: 1
    )
}

func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func rotated(around center: NSPoint, by degrees: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: center.x, yBy: center.y)
    transform.rotate(byDegrees: degrees)
    transform.translateX(by: -center.x, yBy: -center.y)
    transform.concat()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func softShadow(_ opacity: CGFloat = 0.22, blur: CGFloat = 26, y: CGFloat = -10) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(opacity)
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = NSSize(width: 0, height: y)
    shadow.set()
}

/// A page with a folded top-right corner and optional text lines.
func document(_ rect: NSRect, fill: NSColor, fold: NSColor, lines: NSColor? = nil) {
    let cut = rect.width * 0.3
    let path = NSBezierPath()
    path.move(to: NSPoint(x: rect.minX + 22, y: rect.minY))
    path.line(to: NSPoint(x: rect.maxX - 22, y: rect.minY))
    path.curve(to: NSPoint(x: rect.maxX, y: rect.minY + 22), controlPoint1: NSPoint(x: rect.maxX - 8, y: rect.minY), controlPoint2: NSPoint(x: rect.maxX, y: rect.minY + 8))
    path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - cut))
    path.line(to: NSPoint(x: rect.maxX - cut, y: rect.maxY))
    path.line(to: NSPoint(x: rect.minX + 22, y: rect.maxY))
    path.curve(to: NSPoint(x: rect.minX, y: rect.maxY - 22), controlPoint1: NSPoint(x: rect.minX + 8, y: rect.maxY), controlPoint2: NSPoint(x: rect.minX, y: rect.maxY - 8))
    path.line(to: NSPoint(x: rect.minX, y: rect.minY + 22))
    path.curve(to: NSPoint(x: rect.minX + 22, y: rect.minY), controlPoint1: NSPoint(x: rect.minX, y: rect.minY + 8), controlPoint2: NSPoint(x: rect.minX + 8, y: rect.minY))
    path.close()
    fill.setFill()
    path.fill()

    let flap = NSBezierPath()
    flap.move(to: NSPoint(x: rect.maxX - cut, y: rect.maxY))
    flap.line(to: NSPoint(x: rect.maxX - cut, y: rect.maxY - cut))
    flap.line(to: NSPoint(x: rect.maxX, y: rect.maxY - cut))
    flap.close()
    fold.setFill()
    flap.fill()

    guard let lines else { return }
    lines.setFill()
    let inset = rect.width * 0.17
    let height = rect.height * 0.045
    for (index, width) in [0.66, 0.66, 0.42].enumerated() {
        let y = rect.minY + rect.height * (0.46 - CGFloat(index) * 0.14)
        rounded(NSRect(x: rect.minX + inset, y: y, width: rect.width * width, height: height), height / 2).fill()
    }
}

func arc(center: NSPoint, radius: CGFloat, from: CGFloat, to: CGFloat, width: CGFloat, color: NSColor, clockwise: Bool = false) {
    let path = NSBezierPath()
    path.appendArc(withCenter: center, radius: radius, startAngle: from, endAngle: to, clockwise: clockwise)
    path.lineWidth = width
    path.lineCapStyle = .round
    color.setStroke()
    path.stroke()
}

func background(_ top: UInt32, _ bottom: UInt32) {
    NSGraphicsContext.saveGraphicsState()
    softShadow(0.28, blur: 30, y: -14)
    hex(bottom).setFill()
    rounded(body, 185).fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: hex(top), ending: hex(bottom))?.draw(in: rounded(body, 185), angle: -90)
}

func shelf() {
    background(0xFBF5EA, 0xEFE3D0)
    let plank = NSRect(x: 196, y: 286, width: 632, height: 48)
    let colors: [(NSRect, CGFloat, UInt32, UInt32)] = [
        (NSRect(x: 236, y: 334, width: 190, height: 268), 0, 0xE8A33D, 0xF5CB83),
        (NSRect(x: 586, y: 334, width: 190, height: 268), 0, 0x2F8F83, 0x83C9BE),
        (NSRect(x: 402, y: 348, width: 220, height: 310), -7, 0xE4573D, 0xF4A08F),
    ]
    for (rect, angle, fill, fold) in colors {
        rotated(around: NSPoint(x: rect.midX, y: rect.minY), by: angle) {
            softShadow(0.18, blur: 16, y: -4)
            document(rect, fill: hex(fill), fold: hex(fold))
        }
    }
    hex(0x3A2A20).setFill()
    rounded(plank, 24).fill()
    for x in [270, 706] as [CGFloat] {
        rounded(NSRect(x: x, y: 226, width: 48, height: 72), 16).fill()
    }
}

func shake() {
    background(0x1F3160, 0x111C3B)
    let page = NSRect(x: 362, y: 292, width: 300, height: 400)
    rotated(around: NSPoint(x: 512, y: 512), by: -8) {
        NSGraphicsContext.saveGraphicsState()
        softShadow(0.35)
        document(page, fill: .white, fold: hex(0xC9D3E8), lines: hex(0xA9B6D1))
        NSGraphicsContext.restoreGraphicsState()
    }
    let coral = hex(0xFF7557)
    arc(center: NSPoint(x: 512, y: 512), radius: 250, from: 150, to: 210, width: 36, color: coral)
    arc(center: NSPoint(x: 512, y: 512), radius: 330, from: 158, to: 202, width: 36, color: coral.withAlphaComponent(0.55))
    arc(center: NSPoint(x: 512, y: 512), radius: 250, from: 30, to: -30, width: 36, color: coral, clockwise: true)
    arc(center: NSPoint(x: 512, y: 512), radius: 330, from: 22, to: -22, width: 36, color: coral.withAlphaComponent(0.55), clockwise: true)
}

func ledge() {
    background(0x2A2D34, 0x17191E)
    hex(0xF2F0EA).setFill()
    rounded(NSRect(x: 196, y: 296, width: 632, height: 44), 22).fill()
    let side: CGFloat = 170
    hex(0xF3B23E).setFill()
    rounded(NSRect(x: 236, y: 340, width: side, height: side), 36).fill()
    hex(0x4CB9A8).setFill()
    rounded(NSRect(x: 426, y: 340, width: side, height: side), 36).fill()
    rotated(around: NSPoint(x: 660, y: 610), by: -18) {
        hex(0xF2604A).setFill()
        rounded(NSRect(x: 575, y: 525, width: side, height: side), 36).fill()
    }
}

func tray() {
    background(0x1C9C8D, 0x0C5F58)
    rotated(around: NSPoint(x: 512, y: 560), by: 10) {
        NSGraphicsContext.saveGraphicsState()
        softShadow(0.25)
        document(NSRect(x: 382, y: 396, width: 260, height: 350), fill: .white, fold: hex(0xB9E4DE), lines: hex(0x9CCFC8))
        NSGraphicsContext.restoreGraphicsState()
    }
    let front = NSBezierPath()
    front.move(to: NSPoint(x: 226, y: 492))
    front.line(to: NSPoint(x: 798, y: 492))
    front.line(to: NSPoint(x: 722, y: 262))
    front.curve(to: NSPoint(x: 676, y: 230), controlPoint1: NSPoint(x: 714, y: 240), controlPoint2: NSPoint(x: 698, y: 230))
    front.line(to: NSPoint(x: 348, y: 230))
    front.curve(to: NSPoint(x: 302, y: 262), controlPoint1: NSPoint(x: 326, y: 230), controlPoint2: NSPoint(x: 310, y: 240))
    front.close()
    NSGraphicsContext.saveGraphicsState()
    softShadow(0.3, blur: 22, y: 6)
    hex(0xFFD166).setFill()
    front.fill()
    NSGraphicsContext.restoreGraphicsState()
}

func grid() {
    background(0xF2705F, 0xD8402F)
    let side: CGFloat = 148
    let gap: CGFloat = 36
    let start = 512 - side * 1.5 - gap
    for row in 0..<3 {
        for column in 0..<3 where !(row == 1 && column == 1) {
            NSColor.white.withAlphaComponent(0.92).setFill()
            rounded(NSRect(x: start + CGFloat(column) * (side + gap), y: start + CGFloat(row) * (side + gap), width: side, height: side), 34).fill()
        }
    }
    rotated(around: NSPoint(x: 512, y: 512), by: -16) {
        NSGraphicsContext.saveGraphicsState()
        softShadow(0.35)
        hex(0xFFD166).setFill()
        rounded(NSRect(x: 512 - side * 0.62, y: 512 - side * 0.62, width: side * 1.24, height: side * 1.24), 40).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}

func render(pixels: Int, _ draw: () -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: 1024, height: 1024)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let options: [(String, String, () -> Void)] = [
    ("a-shelf", "A  Shelf", shelf),
    ("b-shake", "B  Shake", shake),
    ("c-ledge", "C  Ledge", ledge),
    ("d-tray", "D  Tray", tray),
    ("e-grid", "E  Grid", grid),
]

let cell = NSSize(width: 460, height: 620)
let sheet = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(cell.width) * options.count * 2, pixelsHigh: Int(cell.height) * 2, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
sheet.size = NSSize(width: cell.width * CGFloat(options.count), height: cell.height)

var images: [(String, NSBitmapImageRep)] = []
for (file, label, draw) in options {
    let full = render(pixels: 1024, draw)
    try! full.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("\(file).png"))
    images.append((label, full))
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: sheet)
NSGraphicsContext.current?.imageInterpolation = .high
hex(0xE9E9EC).setFill()
NSRect(origin: .zero, size: sheet.size).fill()
for (index, item) in images.enumerated() {
    let x = CGFloat(index) * cell.width
    (item.0 as NSString).draw(at: NSPoint(x: x + 40, y: 560), withAttributes: [.font: NSFont.systemFont(ofSize: 24, weight: .semibold), .foregroundColor: hex(0x222222)])
    item.1.draw(in: NSRect(x: x + 30, y: 150, width: 400, height: 400), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    var small = x + 40
    for size in [96, 64, 48, 32, 16] as [CGFloat] {
        item.1.draw(in: NSRect(x: small, y: 30, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        small += size + 16
    }
}
NSGraphicsContext.restoreGraphicsState()
try! sheet.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("contact-sheet.png"))
print("Wrote logo options to \(output.path)")
