import Foundation

/// The saved description of one pet on screen.
struct PetConfig: Codable, Identifiable, Equatable {
    var id = UUID()
    var type: DoodleType
    var name: String
    var hat: Hat = .none
    var glasses: Glasses = .none
    /// 0 = full, 100 = starving.
    var hunger: Double = 20
    /// Last window position, so a pet that isn't roaming stays where you left it.
    var x: Double?
    var y: Double?

    init(type: DoodleType, hat: Hat = .none) {
        self.type = type
        self.name = type.defaultName
        self.hat = hat
    }
}
