import AppKit
import SwiftUI

/// One pet: its window, how it moves, and how it reacts.
@MainActor
final class PetController {
    static let size = CGSize(width: 240, height: 280)
    /// Centre of the pet's body, measured from the window's bottom-left corner.
    static let bodyOffset = CGPoint(x: 120, y: 70)
    /// How far below the window's bottom edge the "ground" is, so feet touch the Dock/screen edge.
    static let footInset: CGFloat = 12

    let state: PetState
    let window: FloatingPanel
    private let interactive: InteractiveView
    private weak var manager: PetManager?

    var config: PetConfig { state.config }
    var id: UUID { state.config.id }

    private(set) var origin: CGPoint {
        didSet { if origin != oldValue { window.setFrameOrigin(origin) } }
    }
    var center: CGPoint { CGPoint(x: origin.x + Self.bodyOffset.x, y: origin.y + Self.bodyOffset.y) }

    private enum Activity {
        case idle(until: TimeInterval)
        case walking(toX: CGFloat)
        case floating(to: CGPoint)
        case eating(until: TimeInterval)
        case holding(until: TimeInterval)
    }

    private var activity: Activity = .idle(until: 0)
    private var velocity = CGVector.zero
    private(set) var dragging = false
    private var dragSamples: [(CGPoint, TimeInterval)] = []
    private var phase = Double.random(in: 0...10)
    private var facing: CGFloat = 1
    private var pokes = 0
    private var chompClock = 0.0
    private var hideBubble: DispatchWorkItem?
    private var blinkWork: DispatchWorkItem?

    var isAsleep: Bool { state.face.sleeping }
    var isBusy: Bool {
        switch activity {
        case .eating, .holding: return true
        default: return false
        }
    }
    var canChat: Bool { !isAsleep && !isBusy && !dragging && state.message == nil }

    init(config: PetConfig, origin: CGPoint, manager: PetManager) {
        state = PetState(config: config)
        self.origin = origin
        self.manager = manager
        window = FloatingPanel(size: Self.size, origin: origin)
        interactive = InteractiveView(frame: NSRect(origin: .zero, size: Self.size))
        let host = NSHostingView(rootView: PetView(s: state))
        host.frame = interactive.bounds
        host.autoresizingMask = [.width, .height]
        interactive.addSubview(host)
        window.contentView = interactive

        interactive.onClick = { [weak self] count in
            if count >= 2 { self?.trick() } else { self?.poke() }
        }
        interactive.onDragBegan = { [weak self] in self?.dragBegan() }
        interactive.onDragMoved = { [weak self] o in self?.dragMoved(to: o) }
        interactive.onDragEnded = { [weak self] in self?.dragEnded() }
        interactive.menuProvider = { [weak self] in
            guard let self else { return nil }
            return MenuBuilder.shared.petMenu(for: self)
        }

        window.orderFrontRegardless()
        scheduleBlink()
    }

    func dispose() {
        blinkWork?.cancel()
        hideBubble?.cancel()
        window.orderOut(nil)
    }

    func setLevel(_ level: NSWindow.Level) {
        window.level = level
    }

    func apply(_ cfg: PetConfig) {
        let old = state.config
        state.config = cfg
        if cfg.type != old.type {
            activity = .idle(until: CACurrentMediaTime() + 1)
            velocity = .zero
            hop()
            say(cfg.type.hello)
        } else if cfg.hat != old.hat || cfg.glasses != old.glasses {
            hop()
            say(Lines.outfit(cfg), for: 3)
        }
    }

    static func screenFrame(containing p: CGPoint) -> CGRect {
        (NSScreen.screens.first { $0.frame.contains(p) } ?? NSScreen.main ?? NSScreen.screens[0]).visibleFrame
    }

    // MARK: - Per-frame update

    func tick(_ c: TickContext) {
        phase += c.dt
        let mouseDistance = hypot(c.mouse.x - center.x, c.mouse.y - center.y)
        let hovering = dragging || mouseDistance < 58
        if window.ignoresMouseEvents == hovering { window.ignoresMouseEvents = !hovering }

        updateSleep(c)
        updateEyes(c, mouseDistance: mouseDistance)
        updateChomp(c)
        state.notePhase = state.dancing ? (phase * 0.7).truncatingRemainder(dividingBy: 1) : 0

        if dragging { return }

        if case .holding(let until) = activity, c.now > until { finishFetch(c) }
        if case .eating(let until) = activity, c.now > until { finishEating(c) }

        // Stand still while the pointer is on the pet so it can be clicked, unless it's mid-flight.
        let groundY = Self.screenFrame(containing: center).minY - Self.footInset
        let airborne = config.type.movement != .float && (origin.y > groundY + 0.5 || velocity.dy > 0)
        if hovering && velocity == .zero && !airborne {
            idleAnimation(c)
        } else if config.type.movement == .float {
            floatStep(c)
        } else {
            groundStep(c)
        }
        checkToys(c)
    }

    private func updateSleep(_ c: TickContext) {
        if isAsleep {
            if c.inputIdle < 0.5 { wake(surprised: true) }
        } else if c.inputIdle > 90, !isBusy, !c.music, !c.gameOn {
            withAnimation(.easeInOut(duration: 0.4)) {
                state.face.sleeping = true
                state.face.mood = .sleepy
            }
            say("Nap time... 💤", for: 3)
        }
    }

    func wake(surprised: Bool) {
        guard isAsleep else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            state.face.sleeping = false
            state.face.mood = surprised ? .surprised : .happy
        }
        if surprised {
            say(Lines.wake.randomElement()!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.state.face.mood == .surprised { self?.state.face.mood = .happy }
            }
        }
    }

    private func updateEyes(_ c: TickContext, mouseDistance: CGFloat) {
        var target = c.mouse
        if let toy = nearestToy(c) { target = toy.center }
        let eye = CGPoint(x: center.x, y: center.y + 6 - config.type.faceY)
        let dx = target.x - eye.x, dy = target.y - eye.y
        let dist = max(hypot(dx, dy), 1)
        let reach = min(dist / 40, 1) * 5
        let offset = CGSize(width: dx / dist * reach, height: -dy / dist * reach)
        if abs(offset.width - state.face.eyeOffset.width) > 0.3 || abs(offset.height - state.face.eyeOffset.height) > 0.3 {
            state.face.eyeOffset = offset
        }

        let near = mouseDistance < 40 && !dragging
        if near && state.face.mood == .happy {
            state.face.mood = .surprised
        } else if !near && state.face.mood == .surprised && !state.bounce && !dragging {
            state.face.mood = .happy
        }
    }

    private func updateChomp(_ c: TickContext) {
        guard state.face.mood == .eating else { return }
        chompClock += c.dt
        if chompClock > 0.14 {
            chompClock = 0
            state.face.chomp.toggle()
        }
    }

    // MARK: - Movement

    private func groundStep(_ c: TickContext) {
        let screen = Self.screenFrame(containing: center)
        let groundY = screen.minY - Self.footInset
        let minX = screen.minX + 50 - Self.bodyOffset.x
        let maxX = screen.maxX - 50 - Self.bodyOffset.x
        var o = origin

        guard c.roam else {
            velocity = .zero
            idleAnimation(c)
            return
        }

        // Falling, or flying after being thrown.
        if o.y > groundY + 0.5 || velocity.dy > 0 {
            velocity.dy -= 2400 * c.dt
            o.x += velocity.dx * c.dt
            o.y += velocity.dy * c.dt
            if o.x < minX { o.x = minX; velocity.dx = abs(velocity.dx) * 0.5 }
            if o.x > maxX { o.x = maxX; velocity.dx = -abs(velocity.dx) * 0.5 }
            let maxY = screen.maxY - 50 - Self.bodyOffset.y
            if o.y > maxY { o.y = maxY; velocity.dy = -abs(velocity.dy) * 0.4 }
            if o.y <= groundY {
                o.y = groundY
                if velocity.dy < -600 {
                    velocity.dy = -velocity.dy * 0.35
                    velocity.dx *= 0.7
                    hop()
                } else {
                    velocity = .zero
                }
            }
            origin = o
            state.tilt = max(-25, min(25, Double(velocity.dx) * 0.02))
            state.bob = 0
            return
        }

        o.y = groundY
        var targetX: CGFloat?
        var speed = 55 * c.speed
        if !isBusy, let toy = chaseTarget(c) {
            targetX = toy.center.x
            speed *= 2.6
        } else {
            switch activity {
            case .walking(let x):
                targetX = x
            case .idle(let until) where c.now > until && !c.music:
                let x = CGFloat.random(in: (screen.minX + 60)...(screen.maxX - 60))
                activity = .walking(toX: x)
                targetX = x
            case .floating:
                activity = .idle(until: c.now + 1)
            default:
                break
            }
        }

        if let tx = targetX, !isBusy, abs(tx - center.x) >= 6 {
            facing = tx > center.x ? 1 : -1
            o.x += facing * min(speed * c.dt, abs(tx - center.x))
            o.x = min(max(o.x, minX), maxX)
            gaitAnimation()
        } else {
            if case .walking = activity { activity = .idle(until: c.now + .random(in: 3...9)) }
            idleAnimation(c)
        }
        origin = o
    }

    private func floatStep(_ c: TickContext) {
        let screen = Self.screenFrame(containing: center)
        let bounds = screen.insetBy(dx: 60, dy: 60)
        var o = origin

        // Drifting after being thrown.
        if hypot(velocity.dx, velocity.dy) > 20 {
            o.x += velocity.dx * c.dt
            o.y += velocity.dy * c.dt
            let k = pow(0.08, c.dt)
            velocity.dx *= k
            velocity.dy *= k
            let cx = o.x + Self.bodyOffset.x, cy = o.y + Self.bodyOffset.y
            if cx < bounds.minX { o.x = bounds.minX - Self.bodyOffset.x; velocity.dx = abs(velocity.dx) }
            if cx > bounds.maxX { o.x = bounds.maxX - Self.bodyOffset.x; velocity.dx = -abs(velocity.dx) }
            if cy < bounds.minY { o.y = bounds.minY - Self.bodyOffset.y; velocity.dy = abs(velocity.dy) }
            if cy > bounds.maxY { o.y = bounds.maxY - Self.bodyOffset.y; velocity.dy = -abs(velocity.dy) }
            origin = o
            state.tilt = max(-25, min(25, Double(velocity.dx) * 0.02))
            return
        }
        velocity = .zero
        state.bob = c.music ? -CGFloat(abs(sin(phase * .pi * 2))) * 7 : CGFloat(sin(phase * 2.2) * 5)

        guard c.roam, !isBusy else {
            state.tilt *= 0.9
            return
        }

        var target: CGPoint?
        var speed = 45 * c.speed
        if let toy = chaseTarget(c) {
            target = toy.center
            speed *= 3
        } else {
            switch activity {
            case .floating(let p):
                target = p
            case .idle(let until) where c.now > until && !c.music:
                let p = CGPoint(x: .random(in: bounds.minX...bounds.maxX), y: .random(in: bounds.minY...bounds.maxY))
                activity = .floating(to: p)
                target = p
                if Int.random(in: 0..<5) == 0 && canChat { say(Lines.floating.randomElement()!, for: 3) }
            case .walking:
                activity = .idle(until: c.now + 1)
            default:
                break
            }
        }

        if let t = target {
            let dx = t.x - center.x, dy = t.y - center.y
            let dist = hypot(dx, dy)
            if dist < 5 {
                if case .floating = activity { activity = .idle(until: c.now + .random(in: 2...6)) }
            } else {
                let step = min(speed * c.dt, dist)
                o.x += dx / dist * step
                o.y += dy / dist * step
            }
            state.tilt += ((dx > 0 ? 8 : -8) - state.tilt) * 0.05
        } else {
            state.tilt = c.music ? sin(phase * .pi * 2) * 9 : state.tilt * 0.95
        }
        origin = o
    }

    private func gaitAnimation() {
        switch config.type.movement {
        case .walk:
            state.bob = -CGFloat(abs(sin(phase * 10))) * 4
            state.tilt = sin(phase * 10) * 5
        case .hop:
            state.bob = -CGFloat(abs(sin(phase * 5))) * 16
            state.tilt = Double(facing) * 6
        case .roll:
            state.bob = CGFloat(sin(phase * 45)) * 0.7
            state.tilt = Double(facing) * 4
        case .float:
            break
        }
    }

    private func idleAnimation(_ c: TickContext) {
        if c.music && !isBusy && !isAsleep {
            state.bob = -CGFloat(abs(sin(phase * .pi * 2))) * 7
            state.tilt = sin(phase * .pi * 2) * 9
        } else if config.type.movement == .float {
            state.bob = CGFloat(sin(phase * 2.2) * 5)
            state.tilt *= 0.9
        } else {
            state.bob *= 0.8
            state.tilt *= 0.85
        }
    }

    // MARK: - Toys

    private func nearestToy(_ c: TickContext) -> ToyController? {
        c.toys.min { hypot($0.center.x - center.x, $0.center.y - center.y) < hypot($1.center.x - center.x, $1.center.y - center.y) }
    }

    /// The toy this pet wants to run after: any treat, or a ball the user has thrown.
    private func chaseTarget(_ c: TickContext) -> ToyController? {
        c.toys
            .filter { $0.heldBy == nil && ($0.isTreat || $0.live) }
            .min { hypot($0.center.x - center.x, $0.center.y - center.y) < hypot($1.center.x - center.x, $1.center.y - center.y) }
    }

    private func checkToys(_ c: TickContext) {
        guard !isBusy, !dragging else { return }
        for toy in c.toys where toy.heldBy == nil && !toy.userHolding {
            guard hypot(toy.center.x - center.x, toy.center.y - (center.y + 10)) < 52 else { continue }
            if toy.isTreat {
                eat(toy, c)
                return
            } else if toy.live {
                catchBall(toy, c)
                return
            }
        }
    }

    private func eat(_ toy: ToyController, _ c: TickContext) {
        wake(surprised: false)
        let favorite = toy.emoji == config.type.favoriteTreat
        manager?.removeToy(toy)
        activity = .eating(until: c.now + 1.8)
        state.face.mood = .eating
        say(favorite ? "My FAVOURITE! 😍\nNom nom nom" : "Nom nom nom 😋", for: 2.5)
        playSound("Bottle")
        manager?.petAte(self)
    }

    private func finishEating(_ c: TickContext) {
        activity = .idle(until: c.now + 2)
        state.face.mood = .happy
        state.face.chomp = false
        hop()
        say(Lines.ate.randomElement()!)
    }

    private func catchBall(_ ball: ToyController, _ c: TickContext) {
        wake(surprised: false)
        ball.heldBy = id
        ball.live = false
        activity = .holding(until: c.now + 1.1)
        hop()
        say("Got it! 🎾", for: 1.5)
        playSound("Pop")
    }

    private func finishFetch(_ c: TickContext) {
        activity = .idle(until: c.now + 1.5)
        guard let ball = c.toys.first(where: { $0.heldBy == id }) else { return }
        ball.heldBy = nil
        ball.live = false // the human has to throw it again
        ball.velocity = CGVector(dx: max(-1300, min(1300, (c.mouse.x - center.x) * 1.6)), dy: .random(in: 900...1200))
        say(Lines.fetch.randomElement()!)
        manager?.petFetched(self)
    }

    // MARK: - Interaction

    private func dragBegan() {
        dragging = true
        velocity = .zero
        dragSamples = []
        wake(surprised: false)
        state.face.mood = .surprised
    }

    private func dragMoved(to o: CGPoint) {
        origin = o
        dragSamples.append((o, CACurrentMediaTime()))
        if dragSamples.count > 6 { dragSamples.removeFirst() }
    }

    private func dragEnded() {
        dragging = false
        state.face.mood = .happy
        var v = CGVector.zero
        if let first = dragSamples.first, let last = dragSamples.last, last.1 - first.1 > 0.005,
           CACurrentMediaTime() - last.1 < 0.1 {
            let dt = last.1 - first.1
            v = CGVector(dx: (last.0.x - first.0.x) / dt, dy: (last.0.y - first.0.y) / dt)
        }
        let speed = hypot(v.dx, v.dy)
        if speed > 2500 { v = CGVector(dx: v.dx / speed * 2500, dy: v.dy / speed * 2500) }
        velocity = Prefs.shared.roam ? v : .zero
        activity = .idle(until: CACurrentMediaTime() + 2)
        if speed > 700 && Prefs.shared.roam {
            say(Lines.thrown.randomElement()!, for: 2.5)
            spinOnce()
            playSound("Blow")
        }
        manager?.petMoved(self)
    }

    func poke() {
        wake(surprised: false)
        pokes += 1
        Prefs.shared.pokes += 1
        hop()
        if pokes % 7 == 0 {
            state.face.mood = .love
            say("Okay okay, I love\nyou too ❤️")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if self?.state.face.mood == .love { self?.state.face.mood = .happy }
            }
        } else if config.hunger > 70 && Bool.random() {
            say(Lines.hungry.randomElement()!)
        } else {
            say(Lines.random(for: config.type))
        }
        playSound(config.type.pokeSound)
    }

    func trick() {
        spinOnce()
        say(Lines.tricks.randomElement()!)
        playSound("Glass")
    }

    private func spinOnce() {
        withAnimation(.easeInOut(duration: 0.7)) { state.spin = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in self?.state.spin = false }
    }

    func hop() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { state.bounce = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { self?.state.bounce = false }
        }
    }

    /// Shows a speech bubble, then lets it fade.
    func say(_ text: String, for seconds: Double = 6) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { state.message = text }
        hideBubble?.cancel()
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.state.message = nil }
        }
        hideBubble = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func scheduleBlink() {
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.state.face.blinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) { [weak self] in self?.state.face.blinking = false }
            self.scheduleBlink()
        }
        blinkWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 2...5), execute: work)
    }
}
