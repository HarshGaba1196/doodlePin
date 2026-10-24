import Foundation

/// Listens for Apple Music and Spotify's public "now playing" broadcasts. Needs no permissions.
@MainActor
final class MusicWatcher {
    var onChange: ((_ playing: Bool, _ title: String?) -> Void)?

    private static let sources = [
        "com.apple.Music.playerInfo",
        "com.apple.iTunes.playerInfo",
        "com.spotify.client.PlaybackStateChanged",
    ]
    private var observers: [NSObjectProtocol] = []

    init() {
        let center = DistributedNotificationCenter.default()
        for name in Self.sources {
            let token = center.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { [weak self] note in
                let state = note.userInfo?["Player State"] as? String
                let title = note.userInfo?["Name"] as? String
                MainActor.assumeIsolated {
                    self?.onChange?(state == "Playing", title)
                }
            }
            observers.append(token)
        }
    }
}
