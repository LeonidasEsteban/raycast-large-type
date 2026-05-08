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
        // ~8% horizontal padding, ~6% vertical (with sensible minimums for tiny screens).
        // Bigger horizontal padding gives the text breathing room from the left/right edges,
        // matching Alfred's Cmd+L look.
        let horizontalPadding: CGFloat = max(120, frame.width * 0.08)
        let verticalPadding: CGFloat = max(80, frame.height * 0.06)
        let maxWidth = frame.width - horizontalPadding * 2
        let maxHeight = frame.height - verticalPadding * 2

        // Pin the label to exactly maxWidth and tell NSTextField to wrap at that width.
        // Without preferredMaxLayoutWidth + an explicit width constraint, the field uses
        // its single-line intrinsic width and overflows the screen on long text.
        label.preferredMaxLayoutWidth = maxWidth
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: maxWidth),
        ])

        let fontSize = OverlayView.bestFontSize(
            for: text,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
        label.font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    /// Binary-searches for the largest font size where the text fits within
    /// the available area (maxWidth × maxHeight), allowing wrapping. Starts
    /// from a generous upper bound so very short text can render very large.
    static func bestFontSize(
        for text: String,
        maxWidth: CGFloat,
        maxHeight: CGFloat
    ) -> CGFloat {
        let minSize: CGFloat = 16
        let maxSize: CGFloat = max(maxHeight, 32)

        func fits(_ fontSize: CGFloat) -> Bool {
            let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let bounds = (text as NSString).boundingRect(
                with: NSSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs
            )
            return bounds.width <= maxWidth && bounds.height <= maxHeight
        }

        if fits(maxSize) { return maxSize }
        if !fits(minSize) { return minSize }

        // Binary search to within 1pt
        var lo = minSize
        var hi = maxSize
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if fits(mid) {
                lo = mid
            } else {
                hi = mid
            }
        }
        return lo
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
window.backgroundColor = .clear
window.hasShadow = false
window.ignoresMouseEvents = false
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
window.isReleasedWhenClosed = false

let overlay = OverlayView(text: text, frame: frame)
overlay.translatesAutoresizingMaskIntoConstraints = false

// Liquid Glass on macOS 26+ (Tahoe), VisualEffectView blur as fallback.
let backgroundView: NSView
if #available(macOS 26.0, *) {
    let glass = NSGlassEffectView(frame: frame)
    glass.tintColor = NSColor.black.withAlphaComponent(0.35)
    glass.cornerRadius = 0
    glass.contentView = overlay
    backgroundView = glass
} else {
    let blur = NSVisualEffectView(frame: frame)
    blur.material = .hudWindow
    blur.blendingMode = .behindWindow
    blur.state = .active
    blur.addSubview(overlay)
    NSLayoutConstraint.activate([
        overlay.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
        overlay.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
        overlay.topAnchor.constraint(equalTo: blur.topAnchor),
        overlay.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
    ])
    backgroundView = blur
}
backgroundView.autoresizingMask = [.width, .height]
window.contentView = backgroundView

window.makeKeyAndOrderFront(nil)
NSApp.activate(ignoringOtherApps: true)
app.run()
