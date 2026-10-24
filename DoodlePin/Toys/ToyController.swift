import AppKit
import SwiftUI

final class ToyState: ObservableObject {
    @Published var rotation: Double = 0
}

/// A ball or a treat: a tiny window with simple physics that you can grab and throw.
@MainActor
final class ToyController {
    enum Kind: Equatable {
        case ball
        case treat(String)
    }

    static let size: CGFloat = 44

    let kind: Kind
    let window: FloatingPanel
    private let state = ToyState()
    private weak var manager: PetManager?

    var center: CGPoint
    var velocity: CGVector
    /// A ball is "live" once the human throws it; pets only chase live balls.
    var live: Bool
    /// The pet currently carrying this toy.
    var heldBy: UUID?
    private(set) var userHolding = false
    private var lastActive = CACurrentMediaTime()
    private var samples: [(CGPoint, TimeInterval)] = []

    var isTreat: Bool { if case .treat = kind { return true } else { return false } }
    var emoji: String? { if case .treat(let e) = kind { return e } else { return nil } }

    init(kind: Kind, center: CGPoint, velocity: CGVector, live: Bool, manager: PetManager) {
        self.kind = kind
        self.center = center
        self.velocity = velocity
        self.live = live
        self.manager = manager
        window = FloatingPanel(size: CGSize(width: Self.size, height: Self.size),
                               origin: CGPoint(x: center.x - Self.size / 2, y: center.y - Self.size / 2))
        let view = InteractiveView(frame: NSRect(x: 0, y: 0, width: Self.size, height: Self.size))
        let host = NSHostingView(rootView: ToyView(state: state, kind: kind))
        host.frame = view.bounds
        view.addSubview(host)
        window.contentView = view

        view.onDragBegan = { [weak self] in
            guard let self else { return }
            self.userHolding = true
            self.heldBy = nil
            self.samples = []
        }
        view.onDragMoved = { [weak self] o in
            guard let self else { return }
            self.center = CGPoint(x: o.x + Self.size / 2, y: o.y + Self.size / 2)
            self.sync()
            self.samples.append((self.center, CACurrentMediaTime()))
            if self.samples.count > 6 { self.samples.removeFirst() }
        }
        view.onDragEnded = { [weak self] in self?.release() }
        view.onClick = { [weak self] count in
            guard let self else { return }
            if count >= 2 {
                self.manager?.removeToy(self)
            } else {
                // A click kicks it into the air.
                self.velocity = CGVector(dx: .random(in: -350...350), dy: 750)
                self.live = true
                self.lastActive = CACurrentMediaTime()
            }
        }
        window.orderFrontRegardless()
    }

    private func release() {
        userHolding = false
        lastActive = CACurrentMediaTime()
        velocity = .zero
        if let first = samples.first, let last = samples.last, last.1 - first.1 > 0.005, CACurrentMediaTime() - last.1 < 0.1 {
            let dt = last.1 - first.1
            velocity = CGVector(dx: (last.0.x - first.0.x) / dt, dy: (last.0.y - first.0.y) / dt)
            let speed = hypot(velocity.dx, velocity.dy)
            if speed > 3000 { velocity = CGVector(dx: velocity.dx / speed * 3000, dy: velocity.dy / speed * 3000) }
        }
        live = true
    }

    func tick(_ c: TickContext) {
        let pointerNear = hypot(c.mouse.x - center.x, c.mouse.y - center.y) < Self.size / 2
        let grabbable = userHolding || pointerNear
        if window.ignoresMouseEvents == grabbable { window.ignoresMouseEvents = !grabbable }
        guard !userHolding else { return }

        let screen = PetController.screenFrame(containing: center)
        let r = Self.size / 2 - 4
        let bounce: CGFloat = isTreat ? 0.25 : 0.7
        velocity.dy -= 1800 * c.dt
        center.x += velocity.dx * c.dt
        center.y += velocity.dy * c.dt

        if center.y - r < screen.minY {
            center.y = screen.minY + r
            velocity.dy = abs(velocity.dy) > 80 ? -velocity.dy * bounce : 0
            velocity.dx *= isTreat ? 0.6 : 0.97
            if abs(velocity.dx) < 5 { velocity.dx = 0 }
        }
        if center.y + r > screen.maxY { center.y = screen.maxY - r; velocity.dy = -abs(velocity.dy) * bounce }
        if center.x - r < screen.minX { center.x = screen.minX + r; velocity.dx = abs(velocity.dx) * bounce }
        if center.x + r > screen.maxX { center.x = screen.maxX - r; velocity.dx = -abs(velocity.dx) * bounce }

        if !isTreat { state.rotation += Double(velocity.dx / r) * c.dt * 180 / .pi }
        if hypot(velocity.dx, velocity.dy) > 40 { lastActive = c.now }
        sync()
    }

    /// Carried by a pet: sit on its head.
    func carry(at p: CGPoint) {
        center = p
        velocity = .zero
        lastActive = CACurrentMediaTime()
        sync()
    }

    func sync() {
        window.setFrameOrigin(CGPoint(x: center.x - Self.size / 2, y: center.y - Self.size / 2))
    }

    func isExpired(_ now: TimeInterval) -> Bool {
        heldBy == nil && !userHolding && now - lastActive > (isTreat ? 90 : 180)
    }

    func dispose() {
        window.orderOut(nil)
    }
}

struct ToyView: View {
    @ObservedObject var state: ToyState
    let kind: ToyController.Kind

    var body: some View {
        Group {
            switch kind {
            case .ball:
                BallDoodle().frame(width: 34, height: 34)
            case .treat(let emoji):
                Text(emoji).font(.system(size: 30))
            }
        }
        .rotationEffect(.degrees(state.rotation))
        .frame(width: ToyController.size, height: ToyController.size)
        .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
    }
}

struct BallDoodle: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.85, green: 0.95, blue: 0.3))
            Path { p in
                p.move(to: CGPoint(x: 7, y: 4)); p.addQuadCurve(to: CGPoint(x: 7, y: 30), control: CGPoint(x: 19, y: 17))
                p.move(to: CGPoint(x: 27, y: 4)); p.addQuadCurve(to: CGPoint(x: 27, y: 30), control: CGPoint(x: 15, y: 17))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            Circle().stroke(ink, lineWidth: 2.5)
        }
    }
}
