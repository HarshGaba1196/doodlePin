import AppKit

/// Content view for pet and toy windows: turns raw mouse events into clicks, drags and context menus.
/// Hosted SwiftUI content sits inside it purely for drawing.
final class InteractiveView: NSView {
    var onClick: ((Int) -> Void)?
    var onDragBegan: (() -> Void)?
    var onDragMoved: ((CGPoint) -> Void)?
    var onDragEnded: (() -> Void)?
    var menuProvider: (() -> NSMenu?)?

    private var startMouse = CGPoint.zero
    private var startOrigin = CGPoint.zero
    private var moved = false

    override func hitTest(_ point: NSPoint) -> NSView? {
        frame.contains(point) ? self : nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        startMouse = NSEvent.mouseLocation
        startOrigin = window?.frame.origin ?? .zero
        moved = false
    }

    override func mouseDragged(with event: NSEvent) {
        let m = NSEvent.mouseLocation
        let dx = m.x - startMouse.x, dy = m.y - startMouse.y
        if !moved && hypot(dx, dy) > 3 {
            moved = true
            onDragBegan?()
        }
        if moved { onDragMoved?(CGPoint(x: startOrigin.x + dx, y: startOrigin.y + dy)) }
    }

    override func mouseUp(with event: NSEvent) {
        if moved {
            onDragEnded?()
        } else {
            onClick?(event.clickCount)
        }
        moved = false
    }

    override func rightMouseDown(with event: NSEvent) {
        if let menu = menuProvider?() {
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }
}

/// Borderless, transparent, never-key panel used for pets and toys.
final class FloatingPanel: NSPanel {
    convenience init(size: CGSize, origin: CGPoint) {
        self.init(contentRect: NSRect(origin: origin, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
