import Foundation

/// Everything the pets say.
enum Lines {
    static let general = [
        "Why don't skeletons fight?\nNo guts. 💀",
        "I told my Mac a joke.\nIt didn't get it. No cache.",
        "Fun fact: octopuses\nhave 3 hearts. ❤️❤️❤️",
        "You're doing great.\nSeriously. ✨",
        "A group of flamingos\nis a 'flamboyance' 🦩",
        "Bugs? In YOUR code?\nNever. 🐛",
        "Honey never spoils.\nUnlike my jokes 🍯",
        "Bananas are berries.\nStrawberries aren't 🍌",
        "Ctrl+Z for life?\nStill waiting... ⌛",
        "You look nice today\n(I can't see, but still)",
        "Wombat poop is\ncube-shaped. 🟫",
        "Take a deep breath.\nIn... and out... 🌬",
        "More trees on Earth\nthan stars in the galaxy 🌳",
        "Psst... double-click me\nfor a trick!",
        "Grab me and throw me!\nI dare you 😤",
    ]

    static func special(for type: DoodleType) -> [String] {
        switch type {
        case .blob: return ["I'm 100% blob.\nNo bones about it.", "Squish me. Go on."]
        case .cat: return ["I knocked your coffee\noff the desk. Sorry not sorry ☕", "If I fits, I sits 📦", "Pet me. No. Yes. No."]
        case .dog: return ["Ball? BALL?! 🎾", "I love you.\nI love everyone! 🐶", "Is that... a squirrel?! 🐿"]
        case .bunny: return ["Carrots are\na lifestyle 🥕", "Boing boing boing!"]
        case .bear: return ["Hug? 🐻", "Is it hibernation\nseason yet? 😴"]
        case .penguin: return ["It's cold in here.\nPerfect. 🐧", "Tuxedo. Always.\nI'm always ready 🎩"]
        case .frog: return ["Ribbit.", "I'm not lazy,\nI'm on lily-pad mode 🪷"]
        case .ghost: return ["Boo!", "I'm not see-through,\nI'm just shy 👻"]
        case .cloud: return ["Chance of hugs:\n100% ☁️", "Feeling a bit\nfoggy today 🌫"]
        case .alien: return ["Take me to\nyour charger 👽", "Your planet has\nexcellent memes 🛸"]
        case .robot: return ["01001000 01101001 🤖", "Calculating fun...\n100% complete."]
        }
    }

    static func random(for type: DoodleType) -> String {
        if Int.random(in: 0..<10) < 3, let s = special(for: type).randomElement() { return s }
        return general.randomElement()!
    }

    static func greeting() -> String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning! ☀️\nCoffee first?"
        case 12..<17: return "Good afternoon!\nKeep going 💪"
        case 17..<22: return "Good evening! 🌆\nAlmost done?"
        default: return "It's late... 🌙\nGo to sleep, human."
        }
    }

    static let reminders = ["Stretch break! 🙆\nYou've earned it", "Water time 💧\nGlug glug", "Look away from\nthe screen for 20s 👀", "Roll your shoulders!\nYour back says thanks"]
    static let hungry = ["My tummy is rumbling 🥺\nRight-click me → Feed", "Is it snack time?\nIt feels like snack time.", "I could eat a\nwhole cookie. Or two. 🍪"]
    static let tricks = ["Ta-daaa! 🎉", "Did you see that?!\nA backflip! 🤸", "I've been practicing\nall week 😤"]
    static let thrown = ["Wheeeee! 🎢", "I CAN FLY! 🚀", "Again! Again!", "Woah woah WOAH"]
    static let wake = ["Huh?! I'm awake!\nI wasn't sleeping 😳", "Five more minutes...", "*yawn* Oh, hi!"]
    static let floating = ["Wooooo~ 👻", "Just passing\nthrough...", "Floating is my\ncardio 💨", "Wheee, drifting~"]
    static let fetch = ["Again! Again! 🐾", "Throw it again!!", "Fetch is my\nfavourite sport 🏆"]
    static let ate = ["Yum! Thank you ❤️", "Burp! 'scuse me 😳", "That hit the spot!"]

    static func outfit(_ cfg: PetConfig) -> String {
        if cfg.glasses == .sunglasses { return "Looking cool 😎" }
        if cfg.hat != .none { return "Do you like my\n\(cfg.hat.name.lowercased())? ✨" }
        if cfg.glasses != .none { return "I can see\nso clearly now 🤓" }
        return "Feeling breezy!"
    }
}
