import SwiftUI

/// Everything about a pet that its view draws.
final class PetState: ObservableObject {
    @Published var config: PetConfig
    @Published var message: String?
    @Published var face = DoodleFace()
    @Published var bounce = false
    @Published var spin = false
    @Published var bob: CGFloat = 0
    @Published var tilt: Double = 0
    @Published var headphones = false
    @Published var dancing = false
    @Published var notePhase: Double = 0
    @Published var sweating = false

    init(config: PetConfig) { self.config = config }
}

struct PetView: View {
    @ObservedObject var s: PetState

    var body: some View {
        ZStack(alignment: .bottom) {
            doodle.padding(.bottom, 10)
            if let m = s.message {
                Bubble(text: m).padding(.bottom, bubbleLift)
            }
        }
        .frame(width: PetController.size.width, height: PetController.size.height, alignment: .bottom)
    }

    private var bubbleLift: CGFloat {
        if s.config.hat != .none { return 10 + 120 + 50 }
        return 10 + 120 + (s.config.type.hasTallTop ? 26 : 4)
    }

    private var face: DoodleFace {
        var f = s.face
        if s.sweating && f.mood == .happy { f.mood = .tired }
        return f
    }

    private var doodle: some View {
        ZStack {
            DoodleView(type: s.config.type, hat: s.config.hat, glasses: s.config.glasses, headphones: s.headphones, face: face)
            if s.dancing { notes }
            if s.sweating { Text("💧").font(.system(size: 15)).offset(x: 50, y: -26) }
        }
        .frame(width: 130, height: 120)
        .scaleEffect(x: s.bounce ? 0.92 : 1, y: s.bounce ? 1.15 : 1, anchor: .bottom)
        .offset(y: s.bounce ? -12 : 0)
        .rotationEffect(.degrees(s.spin ? 360 : 0))
        .rotationEffect(.degrees(s.tilt), anchor: .bottom)
        .offset(y: s.bob)
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 4, x: 1, y: 3)
    }

    private var notes: some View {
        ZStack {
            note("♪", phase: s.notePhase, x: 58)
            note("♫", phase: (s.notePhase + 0.5).truncatingRemainder(dividingBy: 1), x: -58)
        }
    }

    private func note(_ t: String, phase: Double, x: CGFloat) -> some View {
        Text(t)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.black.opacity(0.8))
            .offset(x: x + CGFloat(sin(phase * 6)) * 4, y: -20 - CGFloat(phase) * 40)
            .opacity(1 - phase)
    }
}

struct Bubble: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.custom("Marker Felt", size: 14))
            .foregroundColor(.black.opacity(0.85))
            .multilineTextAlignment(.center)
            .fixedSize()
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ink, style: StrokeStyle(lineWidth: 1.8, dash: [5, 2])))
            )
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
            .id(text)
            .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
    }
}
