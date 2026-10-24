import AppKit

/// Builds the menu bar menu and each pet's right-click menu, and handles their actions.
@MainActor
final class MenuBuilder: NSObject, NSMenuDelegate {
    static let shared = MenuBuilder()

    private var manager: PetManager { .shared }
    private var prefs: Prefs { .shared }

    /// Carries which pet a menu item is about, and the chosen value.
    private final class Payload: NSObject {
        let petID: UUID?
        let value: String
        init(_ petID: UUID?, _ value: String) { self.petID = petID; self.value = value }
    }

    // MARK: Menu bar

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(item("Throw a Ball 🎾", #selector(throwBall)))
        menu.addItem(item("Feed Everyone 🍪", #selector(feed(_:))))
        let add = NSMenuItem(title: "Add a Pet", action: nil, keyEquivalent: "")
        add.submenu = typeMenu(petID: nil, current: nil, action: #selector(addPet(_:)))
        add.isEnabled = prefs.pets.count < Prefs.maxPets
        menu.addItem(add)
        if !manager.toys.isEmpty { menu.addItem(item("Put Toys Away", #selector(putToysAway))) }
        menu.addItem(.separator())
        menu.addItem(item("Roam Around", #selector(toggleRoam), on: prefs.roam))
        menu.addItem(item("Float Above Windows", #selector(toggleOnTop), on: prefs.floatOnTop))
        menu.addItem(item("Sound Effects", #selector(toggleSounds), on: prefs.sounds))
        menu.addItem(.separator())
        menu.addItem(item("Settings…", #selector(openSettings), key: ","))
        menu.addItem(item("Quit DoodlePin", #selector(quit), key: "q"))
    }

    // MARK: Pet menu

    func petMenu(for pet: PetController) -> NSMenu {
        let cfg = pet.config
        let menu = NSMenu()
        let title = NSMenuItem(title: "\(cfg.name) the \(cfg.type.species)", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(item("Feed \(cfg.name) \(cfg.type.favoriteTreat)", #selector(feed(_:)), payload: Payload(cfg.id, "")))
        menu.addItem(item("Play Fetch 🎾", #selector(throwBall)))
        menu.addItem(.separator())

        let doodle = NSMenuItem(title: "Change Doodle", action: nil, keyEquivalent: "")
        doodle.submenu = typeMenu(petID: cfg.id, current: cfg.type, action: #selector(changeType(_:)))
        menu.addItem(doodle)

        let hats = NSMenuItem(title: "Hat", action: nil, keyEquivalent: "")
        hats.submenu = NSMenu()
        for hat in Hat.allCases {
            hats.submenu?.addItem(item(hat.name, #selector(changeHat(_:)), on: hat == cfg.hat, payload: Payload(cfg.id, hat.rawValue)))
        }
        menu.addItem(hats)

        let glasses = NSMenuItem(title: "Glasses", action: nil, keyEquivalent: "")
        glasses.submenu = NSMenu()
        for g in Glasses.allCases {
            glasses.submenu?.addItem(item(g.name, #selector(changeGlasses(_:)), on: g == cfg.glasses, payload: Payload(cfg.id, g.rawValue)))
        }
        menu.addItem(glasses)
        menu.addItem(.separator())

        let add = NSMenuItem(title: "Add Another Pet", action: nil, keyEquivalent: "")
        add.submenu = typeMenu(petID: nil, current: nil, action: #selector(addPet(_:)))
        add.isEnabled = prefs.pets.count < Prefs.maxPets
        menu.addItem(add)
        let remove = item("Say Goodbye to \(cfg.name)", #selector(removePet(_:)), payload: Payload(cfg.id, ""))
        remove.isEnabled = prefs.pets.count > 1
        menu.addItem(remove)
        menu.addItem(.separator())
        menu.addItem(item("Settings…", #selector(openSettings)))
        menu.addItem(item("Quit DoodlePin", #selector(quit)))
        return menu
    }

    // MARK: Helpers

    private func item(_ title: String, _ action: Selector, key: String = "", on: Bool? = nil, payload: Payload? = nil) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        i.representedObject = payload
        if let on { i.state = on ? .on : .off }
        return i
    }

    private func typeMenu(petID: UUID?, current: DoodleType?, action: Selector) -> NSMenu {
        let menu = NSMenu()
        for t in DoodleType.allCases {
            menu.addItem(item("\(t.defaultName) the \(t.species)", action, on: current.map { $0 == t }, payload: Payload(petID, t.rawValue)))
        }
        return menu
    }

    private func payload(_ sender: NSMenuItem) -> Payload? { sender.representedObject as? Payload }

    // MARK: Actions

    @objc private func throwBall() { manager.throwBall() }
    @objc private func feed(_ sender: NSMenuItem) { manager.feed(payload(sender)?.petID) }
    @objc private func putToysAway() { manager.putToysAway() }
    @objc private func toggleRoam() { prefs.roam.toggle() }
    @objc private func toggleOnTop() { prefs.floatOnTop.toggle() }
    @objc private func toggleSounds() { prefs.sounds.toggle() }
    @objc private func openSettings() { SettingsWindowController.shared.show() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func addPet(_ sender: NSMenuItem) {
        if let t = payload(sender).flatMap({ DoodleType(rawValue: $0.value) }) { manager.addPet(t) }
    }

    @objc private func removePet(_ sender: NSMenuItem) {
        if let id = payload(sender)?.petID { manager.removePet(id) }
    }

    @objc private func changeType(_ sender: NSMenuItem) {
        guard let p = payload(sender), let id = p.petID, let t = DoodleType(rawValue: p.value) else { return }
        prefs.update(id) { cfg in
            if cfg.name == cfg.type.defaultName { cfg.name = t.defaultName }
            cfg.type = t
        }
    }

    @objc private func changeHat(_ sender: NSMenuItem) {
        guard let p = payload(sender), let id = p.petID, let hat = Hat(rawValue: p.value) else { return }
        prefs.update(id) { $0.hat = hat }
    }

    @objc private func changeGlasses(_ sender: NSMenuItem) {
        guard let p = payload(sender), let id = p.petID, let g = Glasses(rawValue: p.value) else { return }
        prefs.update(id) { $0.glasses = g }
    }
}
