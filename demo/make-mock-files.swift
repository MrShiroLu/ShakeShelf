// Generates the fictional files used in the demo. Run from the project root:
//   swift demo/make-mock-files.swift
import AppKit

let root = URL(fileURLWithPath: "demo/mock-files")

func art(_ name: String, _ colors: [NSColor], shapes: Int, seed: UInt64) {
    var random = seed
    func next() -> CGFloat {
        random = random &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(random >> 40) / CGFloat(1 << 24)
    }
    let size = NSSize(width: 1200, height: 1200)
    let image = NSImage(size: size, flipped: false) { rect in
        NSGradient(colors: colors)?.draw(in: rect, angle: 60)
        for index in 0..<shapes {
            let radius = 120 + next() * 320
            let center = NSPoint(x: next() * size.width, y: next() * size.height)
            colors[index % colors.count].blended(withFraction: 0.35, of: .white)?.withAlphaComponent(0.28).setFill()
            NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
        }
        return true
    }
    let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent(name))
}

func text(_ name: String, _ contents: String) {
    try! contents.write(to: root.appendingPathComponent(name), atomically: true, encoding: .utf8)
}

func pdf(_ name: String, title: String, lines: [String]) {
    var box = CGRect(x: 0, y: 0, width: 612, height: 792)
    let context = CGContext(root.appendingPathComponent(name) as CFURL, mediaBox: &box, nil)!
    context.beginPDFPage(nil)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    (title as NSString).draw(at: NSPoint(x: 64, y: 690), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 34)])
    NSColor.systemIndigo.setFill()
    NSRect(x: 64, y: 672, width: 96, height: 5).fill()
    for (index, line) in lines.enumerated() {
        (line as NSString).draw(
            at: NSPoint(x: 64, y: 630 - CGFloat(index) * 26),
            withAttributes: [.font: NSFont.systemFont(ofSize: 15), .foregroundColor: NSColor.darkGray]
        )
    }
    context.endPDFPage()
    context.closePDF()
}

art("Pictures/aurora.png", [.systemTeal, .systemIndigo, .systemPurple], shapes: 7, seed: 11)
art("Pictures/sunset.png", [.systemOrange, .systemPink, .systemPurple], shapes: 6, seed: 23)
art("Pictures/dunes.png", [.systemYellow, .systemOrange, .brown], shapes: 8, seed: 37)
art("Projects/Brand Kit/palette.png", [.systemGreen, .systemMint, .systemBlue], shapes: 5, seed: 41)

pdf("Documents/product-brief.pdf", title: "Product Brief", lines: [
    "Goal: collect files from anywhere, drop them once.",
    "Audience: anyone tired of juggling Finder windows.",
    "Scope: a shake gesture and a floating shelf.",
    "Sample document. All content is fictional.",
])
text("Documents/meeting-notes.md", """
# Weekly sync

- Shelf opens in the screen corner
- Thumbnails stay small and sharp
- Sample document, all content is fictional

""")
text("Documents/budget.csv", """
item,amount
Design,1200
Hosting,240
Testing,380

""")
text("Documents/roadmap.txt", """
Roadmap (sample)

Q1  Shelf basics
Q2  Launch at login
Q3  Sharing

""")
text("Projects/logo.svg", """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <rect width="200" height="200" rx="44" fill="#4F46E5"/>
  <path d="M50 120h100l-14 34H64z" fill="#fff"/>
  <path d="M100 42v62M76 82l24 24 24-24" fill="none" stroke="#fff" stroke-width="14" stroke-linecap="round"/>
</svg>

""")
print("Mock files written to \(root.path)")
