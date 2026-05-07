import Cocoa

final class OverlayView: NSView {
    let label = NSTextField(labelWithString: "")

    init(text: String, frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true

        label.stringValue = text
        label.textColor = .white
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 200, weight: .medium)
        label.cell?.usesSingleLineMode = false
        label.cell?.wraps = true

        addSubview(label)
        let margin: CGFloat = 80
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: margin),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -margin),
            label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: margin),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -margin),
        ])

        autoFitFontSize(in: frame.size, margin: margin)
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    private func autoFitFontSize(in size: NSSize, margin: CGFloat) {
        let maxWidth = size.width - margin * 2
        let maxHeight = size.height - margin * 2
        var fontSize: CGFloat = min(size.height * 0.6, 480)

        while fontSize > 24 {
            let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let bounds = (label.stringValue as NSString).boundingRect(
                with: NSSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs
            )
            if bounds.width <= maxWidth && bounds.height <= maxHeight {
                break
            }
            fontSize -= 8
        }

        label.font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
    }

    override func mouseDown(with event: NSEvent) {
        NSApp.terminate(nil)
    }
}

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Esc = 53, Return = 36, Space = 49
        if event.keyCode == 53 || event.keyCode == 36 || event.keyCode == 49 {
            NSApp.terminate(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}

let args = CommandLine.arguments
guard args.count > 1 else {
    FileHandle.standardError.write(Data("usage: LargeType <text>\n".utf8))
    exit(1)
}
let text = args.dropFirst().joined(separator: " ")

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

guard let screen = NSScreen.main else { exit(1) }
let frame = screen.frame

let window = OverlayWindow(
    contentRect: frame,
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
window.level = .screenSaver
window.isOpaque = false
window.backgroundColor = NSColor.black.withAlphaComponent(0.85)
window.hasShadow = false
window.ignoresMouseEvents = false
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
window.isReleasedWhenClosed = false

let view = OverlayView(text: text, frame: frame)
window.contentView = view

window.makeKeyAndOrderFront(nil)
NSApp.activate(ignoringOtherApps: true)
app.run()
