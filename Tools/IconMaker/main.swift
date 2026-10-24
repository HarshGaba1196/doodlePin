// Renders the app icon PNGs (and optionally a preview sheet of every doodle).
// Usage: see scripts/make-icon.sh
import AppKit
import SwiftUI

struct AppIconArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.5), Color(red: 1.0, green: 0.6, blue: 0.42)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(
                    ZStack {
                        ForEach(0..<14, id: \.self) { i in
                            Text(i % 2 == 0 ? "✦" : "•")
                                .font(.system(size: i % 2 == 0 ? 54 : 40))
                                .foregroundColor(.white.opacity(0.45))
                                .offset(x: CGFloat((i * 137) % 700) - 350, y: CGFloat((i * 211) % 700) - 350)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 185, style: .continuous))
                .frame(width: 824, height: 824)
                .shadow(color: .black.opacity(0.3), radius: 18, y: 12)

            DoodleView(type: .blob, hat: .party)
                .scaleEffect(4.6)
                .offset(y: 70)
                .shadow(color: .black.opacity(0.2), radius: 6, y: 8)
        }
        .frame(width: 1024, height: 1024)
    }
}

struct PreviewSheet: View {
    let hats: [Hat] = [.party, .topHat, .crown, .beanie, .wizard, .cap, .bow, .flower, .halo, .none, .crown]
    let glasses: [Glasses] = [.none, .sunglasses, .none, .round, .none, .hearts, .none, .none, .none, .sunglasses, .none]
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(DoodleType.allCases.prefix(6).enumerated()), id: \.offset) { i, t in
                    MiniDoodle(type: t, scale: 1).frame(width: 150)
                }
            }
            HStack(spacing: 0) {
                ForEach(Array(DoodleType.allCases.dropFirst(6).enumerated()), id: \.offset) { i, t in
                    MiniDoodle(type: t, scale: 1).frame(width: 150)
                }
                DoodleView(type: .cat, headphones: true, face: DoodleFace(mood: .eating, chomp: true))
                    .padding(.top, 56).frame(width: 150, height: 176)
            }
            HStack(spacing: 0) {
                ForEach(Array(DoodleType.allCases.enumerated()), id: \.offset) { i, t in
                    MiniDoodle(type: t, hat: hats[i], glasses: glasses[i], scale: 0.75).frame(width: 110)
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.25, green: 0.35, blue: 0.5))
    }
}

/// Transparent artwork for the website.
struct SiteLineup: View {
    let cast: [(DoodleType, Hat, Glasses)] = [
        (.cat, .none, .sunglasses), (.dog, .crown, .none), (.bunny, .flower, .none), (.blob, .party, .none),
        (.penguin, .topHat, .none), (.ghost, .halo, .none), (.frog, .bow, .hearts), (.bear, .beanie, .none),
        (.alien, .none, .round), (.robot, .cap, .none), (.cloud, .wizard, .none),
    ]
    var body: some View {
        HStack(alignment: .bottom, spacing: -6) {
            ForEach(Array(cast.enumerated()), id: \.offset) { _, c in
                MiniDoodle(type: c.0, hat: c.1, glasses: c.2, scale: 0.8)
            }
        }
        .padding(8)
    }
}

struct SiteSingle: View {
    let type: DoodleType; var hat: Hat = .none; var glasses: Glasses = .none; var headphones = false; var mood: Mood = .happy
    var body: some View {
        DoodleView(type: type, hat: hat, glasses: glasses, headphones: headphones, face: DoodleFace(mood: mood, chomp: true))
            .padding(.top, 56).frame(width: 150, height: 180)
    }
}

@MainActor
func savePNG<V: View>(_ view: V, scale: CGFloat, to url: URL) {
    let r = ImageRenderer(content: view)
    r.scale = scale
    guard let cg = r.cgImage else { fatalError("render failed") }
    let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
    try! data.write(to: url)
}

MainActor.assumeIsolated {
    let args = CommandLine.arguments
    if args.count > 2 && args[1] == "--site" {
        let dir = URL(fileURLWithPath: args[2])
        savePNG(SiteLineup(), scale: 2, to: dir.appendingPathComponent("lineup.png"))
        savePNG(AppIconArt(), scale: 0.25, to: dir.appendingPathComponent("icon.png"))
        savePNG(SiteSingle(type: .cat, headphones: true), scale: 2, to: dir.appendingPathComponent("dance.png"))
        savePNG(SiteSingle(type: .dog, mood: .eating), scale: 2, to: dir.appendingPathComponent("eat.png"))
        savePNG(SiteSingle(type: .ghost), scale: 2, to: dir.appendingPathComponent("float.png"))
        savePNG(SiteSingle(type: .penguin, hat: .wizard, glasses: .hearts), scale: 2, to: dir.appendingPathComponent("dressup.png"))
        savePNG(SiteSingle(type: .alien, mood: .surprised), scale: 2, to: dir.appendingPathComponent("calendar.png"))
        return
    }
    let outDir = URL(fileURLWithPath: args[1])
    // macOS icon set: 16, 32, 128, 256, 512 at 1x and 2x.
    for size in [16, 32, 128, 256, 512] {
        for mult in [1, 2] {
            let px = CGFloat(size * mult)
            let name = mult == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
            savePNG(AppIconArt(), scale: px / 1024, to: outDir.appendingPathComponent(name))
        }
    }
    if args.count > 2 {
        savePNG(PreviewSheet(), scale: 1.5, to: URL(fileURLWithPath: args[2]))
    }
}
