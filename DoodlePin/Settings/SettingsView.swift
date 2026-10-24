import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            PetsTab().tabItem { Label("Pets", systemImage: "pawprint.fill") }
            BehaviorTab().tabItem { Label("Behavior", systemImage: "figure.walk") }
            ReactionsTab().tabItem { Label("Reactions", systemImage: "sparkles") }
            GeneralTab().tabItem { Label("General", systemImage: "gearshape") }
        }
        .padding(16)
        .frame(width: 660, height: 560)
    }
}

// MARK: - Pets

private struct PetsTab: View {
    @EnvironmentObject var prefs: Prefs
    @State private var selection: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(prefs.pets) { pet in
                        HStack(spacing: 8) {
                            MiniDoodle(type: pet.type, hat: pet.hat, glasses: pet.glasses, scale: 0.28)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(pet.name).font(.headline)
                                Text(pet.type.species).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .tag(pet.id)
                    }
                }
                Divider()
                HStack(spacing: 4) {
                    Menu {
                        ForEach(DoodleType.allCases) { t in
                            Button("\(t.defaultName) the \(t.species)") { add(t) }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .disabled(prefs.pets.count >= Prefs.maxPets)
                    .help("Add a pet")

                    Button {
                        if let id = selection {
                            PetManager.shared.removePet(id)
                            selection = prefs.pets.first?.id
                        }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .disabled(prefs.pets.count <= 1 || selection == nil)
                    .help("Remove the selected pet")
                    Spacer()
                    Text("\(prefs.pets.count)/\(Prefs.maxPets)").font(.caption).foregroundStyle(.secondary)
                }
                .padding(8)
            }
            .frame(width: 200)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if let binding = selectedPet {
                PetEditor(pet: binding)
            } else {
                Text("Select a pet").foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
        .onAppear { if selection == nil { selection = prefs.pets.first?.id } }
    }

    private func add(_ t: DoodleType) {
        PetManager.shared.addPet(t)
        selection = prefs.pets.last?.id
    }

    private var selectedPet: Binding<PetConfig>? {
        guard let id = selection, let current = prefs.pets.first(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { prefs.pets.first { $0.id == id } ?? current },
            set: { new in prefs.update(id) { $0 = new } }
        )
    }
}

private struct PetEditor: View {
    @Binding var pet: PetConfig

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .bottom, spacing: 20) {
                    MiniDoodle(type: pet.type, hat: pet.hat, glasses: pet.glasses, scale: 0.9)
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Name", text: $pet.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                        HStack {
                            Text("Tummy")
                            ProgressView(value: 100 - pet.hunger, total: 100)
                                .tint(pet.hunger > 70 ? .orange : .green)
                        }
                        Button("Feed \(pet.name) \(pet.type.favoriteTreat)") { PetManager.shared.feed(pet.id) }
                    }
                    .padding(.bottom, 12)
                }

                section("Doodle") {
                    ForEach(DoodleType.allCases) { t in
                        tile(selected: pet.type == t, label: t.species) {
                            if pet.name == pet.type.defaultName { pet.name = t.defaultName }
                            pet.type = t
                        } content: {
                            MiniDoodle(type: t, scale: 0.36)
                        }
                    }
                }

                section("Hat") {
                    ForEach(Hat.allCases) { h in
                        tile(selected: pet.hat == h, label: h == .none ? "None" : h.name) {
                            pet.hat = h
                        } content: {
                            MiniDoodle(type: pet.type, hat: h, scale: 0.36)
                        }
                    }
                }

                section("Glasses") {
                    ForEach(Glasses.allCases) { g in
                        tile(selected: pet.glasses == g, label: g == .none ? "None" : g.name) {
                            pet.glasses = g
                        } content: {
                            MiniDoodle(type: pet.type, glasses: g, scale: 0.36)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(68), spacing: 6), count: 6), spacing: 6) {
                content()
            }
        }
    }

    private func tile<C: View>(selected: Bool, label: String, action: @escaping () -> Void, @ViewBuilder content: () -> C) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                content()
                Text(label).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(width: 66, height: 82)
            .background(RoundedRectangle(cornerRadius: 10).fill(selected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Color.accentColor : .clear, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Behavior

private struct BehaviorTab: View {
    @EnvironmentObject var prefs: Prefs

    var body: some View {
        Form {
            Section {
                Toggle("Roam around the screen", isOn: $prefs.roam)
                LabeledContent("Speed") {
                    HStack {
                        Image(systemName: "tortoise")
                        Slider(value: $prefs.speed, in: 0.5...2)
                        Image(systemName: "hare")
                    }
                }
                .disabled(!prefs.roam)
            } footer: {
                Text("Walkers stroll along the bottom of the screen, frogs and bunnies hop, the robot rolls, and ghosts and clouds float anywhere. Grab and throw a pet to send it flying.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Toggle("Float above other windows", isOn: $prefs.floatOnTop)
                Toggle("Sound effects", isOn: $prefs.sounds)
            }
            Section {
                Toggle("Chat now and then", isOn: $prefs.chatter)
                Toggle("Stretch and water reminders", isOn: $prefs.reminders)
                Stepper("Every \(prefs.reminderMinutes) minutes", value: $prefs.reminderMinutes, in: 15...120, step: 15)
                    .disabled(!prefs.reminders)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Reactions

private struct ReactionsTab: View {
    @EnvironmentObject var prefs: Prefs
    @State private var calendarAuthorized = CalendarWatcher.isAuthorized
    @State private var calendarDenied = CalendarWatcher.isDenied

    var body: some View {
        Form {
            Section {
                Toggle("Dance to music 🎧", isOn: $prefs.reactMusic)
            } footer: {
                caption("Pets put on headphones and dance while Apple Music or Spotify is playing.")
            }
            Section {
                Toggle("React to battery 🔋", isOn: $prefs.reactBattery)
            } footer: {
                caption("Pets cheer when you plug in, and get tired and sweaty when the battery runs low.")
            }
            Section {
                Toggle("Meeting heads-ups 📅", isOn: $prefs.reactCalendar)
                    .onChange(of: prefs.reactCalendar) { _, on in
                        if on { PetManager.shared.calendar.requestAccess { _ in refresh() } }
                    }
                if prefs.reactCalendar && calendarDenied {
                    HStack {
                        Label("Calendar access is turned off", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                        Spacer()
                        Button("Open Privacy Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                        }
                    }
                }
            } footer: {
                caption("A pet reminds you 10 minutes before an event and again when it starts. Your calendar never leaves your Mac.")
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        calendarAuthorized = CalendarWatcher.isAuthorized
        calendarDenied = CalendarWatcher.isDenied
    }

    private func caption(_ s: String) -> some View {
        Text(s).font(.caption).foregroundStyle(.secondary)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @EnvironmentObject var prefs: Prefs
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Open DoodlePin when I log in", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in setLaunchAtLogin(on) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
            }
            Section("Play") {
                HStack {
                    Button("Throw a Ball 🎾") { PetManager.shared.throwBall() }
                    Button("Feed Everyone 🍪") { PetManager.shared.feed() }
                    Button("Put Toys Away") { PetManager.shared.putToysAway() }
                }
            }
            Section("Stats") {
                LabeledContent("Balls fetched", value: "\(prefs.fetches)")
                LabeledContent("Treats eaten", value: "\(prefs.treatsEaten)")
                LabeledContent("Pokes", value: "\(prefs.pokes)")
            }
            Section {
                HStack {
                    Text("DoodlePin \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Quit DoodlePin") { NSApp.terminate(nil) }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Couldn't change this: \(error.localizedDescription)"
        }
        let enabled = SMAppService.mainApp.status == .enabled
        if enabled != launchAtLogin { launchAtLogin = enabled }
    }
}
