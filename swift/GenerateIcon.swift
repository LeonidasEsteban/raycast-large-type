import AppKit

let size = NSSize(width: 512, height: 512)
let image = NSImage(size: size)
image.lockFocus()

let bg = NSGradient(colors: [
    NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.12, alpha: 1.0),
    NSColor(calibratedRed: 0.02, green: 0.02, blue: 0.03, alpha: 1.0),
])!
bg.draw(in: NSRect(origin: .zero, size: size), angle: 270)

let text = "Aa"
let font = NSFont.systemFont(ofSize: 320, weight: .bold)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
]
let attr = NSAttributedString(string: text, attributes: attrs)
let textSize = attr.size()
let origin = NSPoint(
    x: (size.width - textSize.width) / 2,
    y: (size.height - textSize.height) / 2 - 10
)
attr.draw(at: origin)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else {
    FileHandle.standardError.write(Data("Failed to render icon\n".utf8))
    exit(1)
}

let url = URL(fileURLWithPath: "assets/extension-icon.png")
do {
    try png.write(to: url)
    print("wrote \(url.path)")
} catch {
    FileHandle.standardError.write(Data("Failed to write icon: \(error)\n".utf8))
    exit(1)
}
