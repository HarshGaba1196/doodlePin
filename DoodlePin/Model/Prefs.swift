import Foundation
import Combine

/// All user settings and pet data, persisted in UserDefaults.
final class Prefs: ObservableObject {
    static let shared = Prefs()
    static let maxPets = 8
    private let d = UserDefaults.standard

    @Published var pets: [PetConfig] { didSet { savePets() } }
    @Published var roam: Bool { didSet { d.set(roam, forKey: "roam") } }
    @Published var speed: Double { didSet { d.set(speed, forKey: "speed") } }
    @Published var floatOnTop: Bool { didSet { d.set(floatOnTop, forKey: "floatOnTop") } }
    @Published var sounds: Bool { didSet { d.set(sounds, forKey: "sounds") } }
    @Published var chatter: Bool { didSet { d.set(chatter, forKey: "chatter") } }
    @Published var reminders: Bool { didSet { d.set(reminders, forKey: "reminders") } }
    @Published var reminderMinutes: Int { didSet { d.set(reminderMinutes, forKey: "reminderMinutes") } }
    @Published var reactMusic: Bool { didSet { d.set(reactMusic, forKey: "reactMusic") } }
    @Published var reactBattery: Bool { didSet { d.set(reactBattery, forKey: "reactBattery") } }
    @Published var reactCalendar: Bool { didSet { d.set(reactCalendar, forKey: "reactCalendar") } }
    @Published var fetches: Int { didSet { d.set(fetches, forKey: "fetches") } }
    @Published var treatsEaten: Int { didSet { d.set(treatsEaten, forKey: "treatsEaten") } }
    @Published var pokes: Int { didSet { d.set(pokes, forKey: "pokes") } }

    var hasLaunchedBefore: Bool {
        get { d.bool(forKey: "hasLaunchedBefore") }
        set { d.set(newValue, forKey: "hasLaunchedBefore") }
    }

    private init() {
        d.register(defaults: [
            "roam": true, "speed": 1.0, "floatOnTop": true, "sounds": true, "chatter": true,
            "reminders": true, "reminderMinutes": 45,
            "reactMusic": true, "reactBattery": true, "reactCalendar": false,
        ])
        if let data = d.data(forKey: "pets"),
           let saved = try? JSONDecoder().decode([PetConfig].self, from: data), !saved.isEmpty {
            pets = saved
        } else {
            pets = [PetConfig(type: .blob, hat: .party)]
        }
        roam = d.bool(forKey: "roam")
        speed = d.double(forKey: "speed")
        floatOnTop = d.bool(forKey: "floatOnTop")
        sounds = d.bool(forKey: "sounds")
        chatter = d.bool(forKey: "chatter")
        reminders = d.bool(forKey: "reminders")
        reminderMinutes = d.integer(forKey: "reminderMinutes")
        reactMusic = d.bool(forKey: "reactMusic")
        reactBattery = d.bool(forKey: "reactBattery")
        reactCalendar = d.bool(forKey: "reactCalendar")
        fetches = d.integer(forKey: "fetches")
        treatsEaten = d.integer(forKey: "treatsEaten")
        pokes = d.integer(forKey: "pokes")
    }

    func update(_ id: UUID, _ change: (inout PetConfig) -> Void) {
        guard let i = pets.firstIndex(where: { $0.id == id }) else { return }
        var p = pets[i]
        change(&p)
        if p != pets[i] { pets[i] = p }
    }

    private func savePets() {
        if let data = try? JSONEncoder().encode(pets) { d.set(data, forKey: "pets") }
    }
}
