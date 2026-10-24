import SwiftUI

/// Every kind of doodle buddy the app can draw.
enum DoodleType: String, CaseIterable, Codable, Identifiable {
    case blob, cat, dog, bunny, bear, penguin, frog, ghost, cloud, alien, robot

    var id: String { rawValue }

    var defaultName: String {
        switch self {
        case .blob: return "Pip"
        case .cat: return "Miso"
        case .dog: return "Biscuit"
        case .bunny: return "Clover"
        case .bear: return "Bruno"
        case .penguin: return "Waddles"
        case .frog: return "Ribbit"
        case .ghost: return "Boo"
        case .cloud: return "Puff"
        case .alien: return "Zorp"
        case .robot: return "Bolt"
        }
    }

    var species: String { rawValue.capitalized }

    var fill: Color {
        switch self {
        case .blob: return Color(white: 0.98)
        case .cat: return Color(red: 1.0, green: 0.78, blue: 0.5)
        case .dog: return Color(red: 0.93, green: 0.8, blue: 0.62)
        case .bunny: return Color(red: 1.0, green: 0.95, blue: 0.97)
        case .bear: return Color(red: 0.76, green: 0.56, blue: 0.4)
        case .penguin: return Color(red: 0.24, green: 0.29, blue: 0.42)
        case .frog: return Color(red: 0.6, green: 0.88, blue: 0.5)
        case .ghost: return Color(white: 0.97)
        case .cloud: return Color(red: 0.82, green: 0.92, blue: 1.0)
        case .alien: return Color(red: 0.8, green: 0.72, blue: 1.0)
        case .robot: return Color(red: 0.78, green: 0.82, blue: 0.88)
        }
    }

    var movement: Movement {
        switch self {
        case .ghost, .cloud: return .float
        case .frog, .bunny: return .hop
        case .robot: return .roll
        default: return .walk
        }
    }

    var hello: String {
        switch self {
        case .blob: return "Hi! I'm Pip.\nPoke me!"
        case .cat: return "Meow. I'm Miso.\nFeed me attention 🐟"
        case .dog: return "WOOF! I'm Biscuit!\nWho's a good human? 🐶"
        case .bunny: return "Hop hop! I'm Clover 🐰"
        case .bear: return "Bruno here.\nHugs available 🐻"
        case .penguin: return "Waddle waddle 🐧\nNice ice you got here"
        case .frog: return "Ribbit! 🐸\nNice desktop."
        case .ghost: return "Boo! 👻\nI'm going for a float..."
        case .cloud: return "Puff here ☁️\nFloating by!"
        case .alien: return "Greetings, Earthling 👽\nTake me to your snacks"
        case .robot: return "BEEP BOOP 🤖\nBolt online."
        }
    }

    var favoriteTreat: String {
        switch self {
        case .blob: return "🍪"
        case .cat, .penguin: return "🐟"
        case .dog: return "🦴"
        case .bunny: return "🥕"
        case .bear: return "🍯"
        case .frog: return "🪰"
        case .ghost: return "🍬"
        case .cloud: return "🍦"
        case .alien: return "🍕"
        case .robot: return "🔋"
        }
    }

    var pokeSound: String {
        switch self {
        case .cat: return "Purr"
        case .frog: return "Frog"
        case .robot: return "Morse"
        case .alien: return "Submarine"
        case .ghost, .cloud: return "Blow"
        default: return "Pop"
        }
    }

    // Layout inside the 130×120 doodle frame (origin at its centre, y grows downward).

    /// Vertical shift of the eyes/mouth.
    var faceY: CGFloat {
        switch self {
        case .frog: return -12
        case .ghost: return -8
        case .bunny: return 10
        case .penguin: return 4
        case .alien: return -4
        default: return 0
        }
    }

    /// Where the top of the head is, so hats sit on it.
    var headTop: CGFloat {
        switch self {
        case .blob: return -44
        case .cat: return -32
        case .dog: return -45
        case .bunny: return -34
        case .bear: return -46
        case .penguin: return -53
        case .frog: return -40
        case .ghost: return -49
        case .cloud: return -38
        case .alien: return -45
        case .robot: return -43
        }
    }

    /// Head width, used to size headphones.
    var headWidth: CGFloat {
        switch self {
        case .cat: return 104
        case .frog: return 112
        case .cloud: return 116
        case .bear: return 104
        default: return 96
        }
    }

    /// Ears or antennae that poke up above the head.
    var hasTallTop: Bool { [.bunny, .alien, .robot, .cat].contains(self) }
}

enum Movement { case walk, hop, float, roll }

enum Hat: String, CaseIterable, Codable, Identifiable {
    case none, party, topHat, crown, beanie, wizard, cap, bow, flower, halo
    var id: String { rawValue }
    var name: String {
        switch self {
        case .none: return "No Hat"
        case .party: return "Party Hat"
        case .topHat: return "Top Hat"
        case .crown: return "Crown"
        case .beanie: return "Beanie"
        case .wizard: return "Wizard Hat"
        case .cap: return "Cap"
        case .bow: return "Bow"
        case .flower: return "Flower"
        case .halo: return "Halo"
        }
    }
}

enum Glasses: String, CaseIterable, Codable, Identifiable {
    case none, sunglasses, round, hearts
    var id: String { rawValue }
    var name: String {
        switch self {
        case .none: return "No Glasses"
        case .sunglasses: return "Sunglasses"
        case .round: return "Round Glasses"
        case .hearts: return "Heart Glasses"
        }
    }
}

enum Mood { case happy, surprised, love, sleepy, eating, tired }

struct DoodleFace: Equatable {
    var mood: Mood = .happy
    var eyeOffset: CGSize = .zero
    var blinking = false
    var sleeping = false
    var chomp = false
}
