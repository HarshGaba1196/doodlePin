import AppKit
import Combine
import CoreGraphics

/// What every pet and toy sees on each frame.
@MainActor
struct TickContext {
    let now: TimeInterval
    let dt: Double
    let mouse: CGPoint
    /// Seconds since the last keyboard or mouse input anywhere.
    let inputIdle: Double
    let music: Bool
    let roam: Bool
    let speed: Double
    let toys: [ToyController]
    var gameOn: Bool { toys.contains { $0.isTreat || $0.live } }
}

@MainActor
func playSound(_ name: String) {
    guard Prefs.shared.sounds else { return }
    NSSound(named: NSSound.Name(name))?.play()
}

/// Owns every pet and toy, runs the animation clock, and routes music/battery/calendar events.
@MainActor
final class PetManager {
    static let shared = PetManager()

    let prefs = Prefs.shared
    let music = MusicWatcher()
    let battery = BatteryWatcher()
    let calendar = CalendarWatcher()

    private(set) var pets: [PetController] = []
    private(set) var toys: [ToyController] = []

    private var frameTimer: Timer?
    private var slowTimer: Timer?
    private var bag = Set<AnyCancellable>()
    private var lastFrame = CACurrentMediaTime()
    private var started = false
    private var level: NSWindow.Level = .floating

    private var musicPlaying = false
    private var lastTrack: String?
    private var lastReminder = Date()
    private var nextChatter = Date().addingTimeInterval(.random(in: 120...240))
    private var lastHunger = Date()
    private var lastCalendarCheck = Date.distantPast
    private var greetCooldown: [String: TimeInterval] = [:]

    func start() {
        syncPets(prefs.pets)
        started = true

        prefs.$pets.dropFirst().sink { [weak self] pets in
            MainActor.assumeIsolated { self?.syncPets(pets) }
        }.store(in: &bag)
        prefs.$floatOnTop.sink { [weak self] onTop in
            MainActor.assumeIsolated { self?.applyLevel(onTop: onTop) }
        }.store(in: &bag)
        prefs.$reactMusic.dropFirst().sink { [weak self] on in
            MainActor.assumeIsolated { self?.applyMusicLook(enabled: on) }
        }.store(in: &bag)
        prefs.$reactBattery.dropFirst().sink { [weak self] on in
            MainActor.assumeIsolated { if !on { self?.pets.forEach { $0.state.sweating = false } } }
        }.store(in: &bag)
        prefs.$reactCalendar.sink { [weak self] on in
            MainActor.assumeIsolated { if on { self?.calendar.requestAccess { _ in } } }
        }.store(in: &bag)

        music.onChange = { [weak self] playing, title in self?.musicChanged(playing: playing, title: title) }
        battery.onEvent = { [weak self] event in self?.batteryEvent(event) }
        calendar.onUpcoming = { [weak self] title, minutes in self?.meetingSoon(title: title, minutes: minutes) }

        let frame = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(frame, forMode: .common)
        frameTimer = frame

        let slow = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.slowTick() }
        }
        RunLoop.main.add(slow, forMode: .common)
        slowTimer = slow

        battery.check()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.pets.first?.say(Lines.greeting())
        }
    }

    // MARK: - Pets

    private func syncPets(_ configs: [PetConfig]) {
        for cfg in configs {
            if let pet = pets.first(where: { $0.id == cfg.id }) {
                if pet.config != cfg { pet.apply(cfg) }
            } else {
                let pet = PetController(config: cfg, origin: startOrigin(for: cfg), manager: self)
                pet.setLevel(level)
                pet.state.headphones = musicPlaying && prefs.reactMusic
                pet.state.dancing = pet.state.headphones
                pet.state.sweating = battery.isLow && prefs.reactBattery
                pets.append(pet)
                if started { pet.say(cfg.type.hello) }
            }
        }
        let ids = Set(configs.map(\.id))
        for pet in pets where !ids.contains(pet.id) {
            toys.filter { $0.heldBy == pet.id }.forEach { $0.heldBy = nil }
            pet.dispose()
        }
        pets.removeAll { !ids.contains($0.id) }
    }

    private func startOrigin(for cfg: PetConfig) -> CGPoint {
        if let x = cfg.x, let y = cfg.y {
            let p = CGPoint(x: x, y: y)
            let body = CGPoint(x: x + PetController.bodyOffset.x, y: y + PetController.bodyOffset.y)
            if NSScreen.screens.contains(where: { $0.frame.contains(body) }) { return p }
        }
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        return CGPoint(x: .random(in: (screen.minX + 40)...(screen.maxX - PetController.size.width - 40)),
                       y: screen.maxY - PetController.size.height)
    }

    func addPet(_ type: DoodleType) {
        guard prefs.pets.count < Prefs.maxPets else { return }
        prefs.pets.append(PetConfig(type: type))
    }

    func removePet(_ id: UUID) {
        guard prefs.pets.count > 1 else { return }
        prefs.pets.removeAll { $0.id == id }
    }

    func pet(_ id: UUID) -> PetController? { pets.first { $0.id == id } }

    func petMoved(_ pet: PetController) {
        prefs.update(pet.id) { $0.x = Double(pet.origin.x); $0.y = Double(pet.origin.y) }
    }

    func savePositions() {
        for pet in pets { petMoved(pet) }
    }

    func petAte(_ pet: PetController) {
        prefs.update(pet.id) { $0.hunger = max(0, $0.hunger - 40) }
        prefs.treatsEaten += 1
    }

    func petFetched(_ pet: PetController) {
        prefs.fetches += 1
    }

    private func applyLevel(onTop: Bool) {
        level = onTop ? .floating : NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        pets.forEach { $0.setLevel(level) }
        toys.forEach { $0.window.level = level }
    }

    private var randomAwakePet: PetController? {
        pets.filter { !$0.isAsleep }.randomElement() ?? pets.randomElement()
    }

    // MARK: - Toys & games

    func feed(_ petID: UUID? = nil) {
        let targets = petID.flatMap { id in pet(id).map { [$0] } } ?? pets
        for (i, pet) in targets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) { [weak self] in
                guard let self else { return }
                let screen = PetController.screenFrame(containing: pet.center)
                let start = CGPoint(x: pet.center.x + .random(in: -30...30), y: min(screen.maxY - 30, pet.center.y + 320))
                self.addToy(.treat(pet.config.type.favoriteTreat), at: start, velocity: .zero, live: true)
            }
        }
    }

    func throwBall() {
        guard toys.filter({ !$0.isTreat }).count < 3 else { return }
        let mouse = NSEvent.mouseLocation
        let screen = PetController.screenFrame(containing: mouse)
        let start = CGPoint(x: min(max(mouse.x, screen.minX + 30), screen.maxX - 30), y: min(mouse.y, screen.maxY - 30))
        let target = pets.randomElement()?.center ?? CGPoint(x: screen.midX, y: screen.minY)
        addToy(.ball, at: start, velocity: CGVector(dx: (target.x - start.x) * 0.9, dy: 250), live: true)
        randomAwakePet?.say("BALL!! 🎾", for: 2)
    }

    func putToysAway() {
        toys.forEach { $0.dispose() }
        toys.removeAll()
    }

    private func addToy(_ kind: ToyController.Kind, at p: CGPoint, velocity: CGVector, live: Bool) {
        let toy = ToyController(kind: kind, center: p, velocity: velocity, live: live, manager: self)
        toy.window.level = level
        toys.append(toy)
    }

    func removeToy(_ toy: ToyController) {
        toy.dispose()
        toys.removeAll { $0 === toy }
    }

    // MARK: - Clock

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = min(now - lastFrame, 1.0 / 20)
        lastFrame = now
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
        let ctx = TickContext(now: now, dt: dt, mouse: NSEvent.mouseLocation, inputIdle: idle,
                              music: musicPlaying && prefs.reactMusic, roam: prefs.roam, speed: prefs.speed, toys: toys)

        for toy in toys {
            if let holder = toy.heldBy {
                if let pet = pet(holder) {
                    toy.carry(at: CGPoint(x: pet.center.x, y: pet.center.y + 52))
                } else {
                    toy.heldBy = nil
                }
            } else {
                toy.tick(ctx)
            }
        }
        toys.filter { $0.isExpired(now) }.forEach(removeToy)

        for pet in pets { pet.tick(ctx) }
        greetNeighbours(now)
    }

    /// Two pets that bump into each other say hello.
    private func greetNeighbours(_ now: TimeInterval) {
        guard pets.count > 1 else { return }
        for i in 0..<pets.count - 1 {
            for j in (i + 1)..<pets.count {
                let a = pets[i], b = pets[j]
                guard hypot(a.center.x - b.center.x, a.center.y - b.center.y) < 110, a.canChat, b.canChat else { continue }
                let key = [a.id.uuidString, b.id.uuidString].sorted().joined()
                if let last = greetCooldown[key], now - last < 150 { continue }
                greetCooldown[key] = now
                a.say("Oh hi \(b.config.name)! 👋", for: 3)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    b.say(["Hey \(a.config.name)!", "Sup \(a.config.name) 😎", "Oh! Hi! 😊"].randomElement()!, for: 3)
                    b.hop()
                }
            }
        }
    }

    private func slowTick() {
        let now = Date()

        if now.timeIntervalSince(lastHunger) >= 60 {
            lastHunger = now
            var updated = prefs.pets
            for i in updated.indices { updated[i].hunger = min(100, updated[i].hunger + 0.4) }
            prefs.pets = updated
            if let hungry = pets.filter({ $0.config.hunger > 70 && $0.canChat }).randomElement(), Int.random(in: 0..<10) == 0 {
                hungry.say(Lines.hungry.randomElement()!)
            }
        }

        if prefs.reminders, now.timeIntervalSince(lastReminder) >= Double(prefs.reminderMinutes * 60) {
            lastReminder = now
            randomAwakePet?.say(Lines.reminders.randomElement()!, for: 15)
            pets.forEach { $0.hop() }
        } else if prefs.chatter, now >= nextChatter {
            nextChatter = now.addingTimeInterval(.random(in: 180...360))
            if let pet = pets.filter(\.canChat).randomElement() { pet.say(Lines.random(for: pet.config.type)) }
        }

        if prefs.reactBattery { battery.check() }
        if prefs.reactCalendar, now.timeIntervalSince(lastCalendarCheck) >= 30 {
            lastCalendarCheck = now
            calendar.check()
        }
    }

    // MARK: - Reactions

    private func applyMusicLook(enabled: Bool) {
        let on = musicPlaying && enabled
        for pet in pets {
            pet.state.headphones = on
            pet.state.dancing = on
        }
    }

    private func musicChanged(playing: Bool, title: String?) {
        let wasPlaying = musicPlaying
        musicPlaying = playing
        guard prefs.reactMusic else { return }
        applyMusicLook(enabled: true)
        if playing, let title, title != lastTrack || !wasPlaying {
            lastTrack = title
            randomAwakePet?.say("🎵 Ooh, I love this one!\n\(String(title.prefix(26)))", for: 5)
        } else if !playing && wasPlaying {
            randomAwakePet?.say("Aww, the music\nstopped 😢", for: 4)
        }
    }

    private func batteryEvent(_ event: BatteryWatcher.Event) {
        guard prefs.reactBattery else { return }
        switch event {
        case .pluggedIn:
            pets.forEach { $0.state.sweating = false; $0.hop() }
            randomAwakePet?.say("⚡ Yum, power!\nThanks for plugging in")
        case .unplugged:
            randomAwakePet?.say("Unplugged!\nAdventure mode 🏕")
        case .low(let pct):
            pets.forEach { $0.state.sweating = true }
            randomAwakePet?.say("Battery at \(pct)%...\nI feel weak 🪫", for: 10)
        case .recovered:
            pets.forEach { $0.state.sweating = false }
        case .full:
            randomAwakePet?.say("Battery 100%!\nI'm SO full ⚡")
        }
    }

    private func meetingSoon(title: String, minutes: Int) {
        guard prefs.reactCalendar else { return }
        let name = String(title.prefix(24))
        let text = minutes <= 1 ? "📅 \"\(name)\"\nis starting NOW! Go go go!" : "📅 \"\(name)\"\nstarts in \(minutes) min!"
        let pet = randomAwakePet
        pet?.wake(surprised: false)
        pet?.say(text, for: 20)
        pets.forEach { $0.hop() }
        playSound("Glass")
    }
}
