import SwiftUI

let ink = Color.black
let doodleLine = StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round)

/// Draws one doodle in a 130×120 frame. Hats, ears and antennae may poke out above it.
struct DoodleView: View {
    var type: DoodleType
    var hat: Hat = .none
    var glasses: Glasses = .none
    var headphones = false
    var face = DoodleFace()

    var body: some View {
        ZStack {
            bodyShape
            faceView.offset(y: type.faceY)
            extras
            if headphones { HeadphonesView(type: type) }
            if hat != .none { HatView(hat: hat).offset(y: type.headTop + 6 - 32) }
            if face.sleeping {
                Text("z Z z")
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black.opacity(0.75))
                    .shadow(color: .white, radius: 2)
                    .offset(x: 56, y: -50)
                    .transition(.opacity)
            }
        }
        .frame(width: 130, height: 120)
    }

    private func outlined<S: Shape>(_ shape: S, _ color: Color? = nil) -> some View {
        shape.fill(color ?? type.fill).overlay(shape.stroke(ink, style: doodleLine))
    }

    private let sides: [CGFloat] = [-1, 1]

    // MARK: Bodies

    @ViewBuilder private var bodyShape: some View {
        switch type {
        case .blob:
            outlined(BlobShape()).frame(width: 100, height: 88)

        case .cat:
            outlined(CatShape()).frame(width: 108, height: 100)

        case .dog:
            let brown = Color(red: 0.6, green: 0.42, blue: 0.3)
            ZStack {
                outlined(BlobShape()).frame(width: 96, height: 90)
                ForEach(sides, id: \.self) { side in
                    outlined(Ellipse(), brown).frame(width: 30, height: 56)
                        .rotationEffect(.degrees(-18 * side))
                        .offset(x: side * 54, y: -12)
                }
                Ellipse().fill(brown.opacity(0.55)).frame(width: 30, height: 26).offset(x: 17, y: -6)
            }

        case .bunny:
            ZStack {
                ForEach(sides, id: \.self) { side in
                    ZStack {
                        outlined(Capsule()).frame(width: 24, height: 58)
                        Capsule().fill(Color.pink.opacity(0.45)).frame(width: 10, height: 38)
                    }
                    .rotationEffect(.degrees(side * 10))
                    .offset(x: side * 20, y: -52)
                }
                outlined(BlobShape()).frame(width: 94, height: 84).offset(y: 8)
            }

        case .bear:
            ZStack {
                ForEach(sides, id: \.self) { side in
                    ZStack {
                        outlined(Circle()).frame(width: 32, height: 32)
                        Circle().fill(Color(red: 0.92, green: 0.75, blue: 0.62)).frame(width: 14, height: 14)
                    }
                    .offset(x: side * 37, y: -34)
                }
                outlined(Ellipse()).frame(width: 106, height: 92)
                outlined(Ellipse(), Color(red: 0.96, green: 0.86, blue: 0.74)).frame(width: 46, height: 32).offset(y: 22)
            }

        case .penguin:
            let orange = Color(red: 1, green: 0.62, blue: 0.2)
            ZStack {
                ForEach(sides, id: \.self) { side in
                    outlined(Ellipse()).frame(width: 20, height: 44)
                        .rotationEffect(.degrees(side * 25))
                        .offset(x: side * 47, y: 12)
                    outlined(Ellipse(), orange).frame(width: 24, height: 12).offset(x: side * 18, y: 53)
                }
                outlined(Ellipse()).frame(width: 96, height: 106)
                Ellipse().fill(Color.white).frame(width: 74, height: 76).offset(y: 8)
            }

        case .frog:
            ZStack {
                outlined(Ellipse()).frame(width: 116, height: 76).offset(y: 14)
                HStack(spacing: 4) {
                    outlined(Circle()).frame(width: 40, height: 40)
                    outlined(Circle()).frame(width: 40, height: 40)
                }
                .offset(y: -22)
                Ellipse().fill(type.fill).frame(width: 60, height: 20).offset(y: -8)
            }

        case .ghost:
            outlined(GhostShape()).frame(width: 96, height: 110)

        case .cloud:
            outlined(CloudShape()).frame(width: 124, height: 84)

        case .alien:
            ZStack {
                ForEach(sides, id: \.self) { side in
                    Capsule().fill(ink).frame(width: 3, height: 26)
                        .rotationEffect(.degrees(side * 25))
                        .offset(x: side * 20, y: -50)
                    outlined(Circle(), Color(red: 1, green: 0.9, blue: 0.3)).frame(width: 12, height: 12)
                        .offset(x: side * 26, y: -62)
                }
                outlined(AlienHeadShape()).frame(width: 104, height: 90)
            }

        case .robot:
            ZStack {
                Capsule().fill(ink).frame(width: 3, height: 18).offset(y: -52)
                outlined(Circle(), .red).frame(width: 12, height: 12).offset(y: -62)
                outlined(RoundedRectangle(cornerRadius: 18)).frame(width: 100, height: 86)
                ForEach(sides, id: \.self) { side in
                    outlined(RoundedRectangle(cornerRadius: 3)).frame(width: 10, height: 24).offset(x: side * 55)
                }
            }
        }
    }

    @ViewBuilder private var extras: some View {
        switch type {
        case .cat:
            HStack(spacing: 58) { whiskers.scaleEffect(x: -1); whiskers }.offset(y: 16)
        case .robot:
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { _ in Rectangle().fill(ink.opacity(0.55)).frame(width: 2, height: 6) }
            }
            .offset(y: 32)
        default:
            EmptyView()
        }
    }

    private var whiskers: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 2)); p.addLine(to: CGPoint(x: 18, y: 0))
            p.move(to: CGPoint(x: 0, y: 10)); p.addLine(to: CGPoint(x: 18, y: 10))
        }
        .stroke(ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        .frame(width: 18, height: 12)
    }

    // MARK: Face

    private var eyeSpacing: CGFloat { type == .frog ? 22 : 14 }

    private var faceView: some View {
        ZStack {
            HStack(spacing: eyeSpacing) { eye; eye }.offset(y: -6)
            if glasses != .none { GlassesView(glasses: glasses, spacing: eyeSpacing).offset(y: -6) }
            if type != .robot {
                HStack(spacing: 50) {
                    Circle().fill(Color.pink.opacity(0.45)).frame(width: 13, height: 8)
                    Circle().fill(Color.pink.opacity(0.45)).frame(width: 13, height: 8)
                }
                .offset(y: 12)
            }
            nose
            mouth.offset(y: mouthY)
        }
    }

    private var mouthY: CGFloat {
        switch type {
        case .dog, .bear: return 24
        case .penguin: return 15
        default: return 20
        }
    }

    @ViewBuilder private var nose: some View {
        switch type {
        case .dog, .bear:
            Ellipse().fill(ink).frame(width: 16, height: 11)
                .overlay(Ellipse().fill(Color.white.opacity(0.6)).frame(width: 5, height: 3).offset(x: -3, y: -2))
                .offset(y: 13)
        case .bunny:
            Ellipse().fill(Color(red: 1, green: 0.5, blue: 0.65)).frame(width: 9, height: 6).offset(y: 12)
        default:
            EmptyView()
        }
    }

    @ViewBuilder private var eye: some View {
        ZStack {
            if type == .robot {
                RoundedRectangle(cornerRadius: 5).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 5).stroke(ink, lineWidth: 2))
                    .frame(width: 24, height: 22)
            } else {
                Ellipse().fill(Color.white).overlay(Ellipse().stroke(ink, lineWidth: 2))
                    .frame(width: 22, height: 26)
            }
            if face.mood == .love {
                Text("❤️").font(.system(size: 13))
            } else if face.sleeping || face.blinking {
                ClosedEye().stroke(ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round)).frame(width: 16, height: 6)
            } else {
                let size: CGFloat = face.mood == .surprised ? 7 : 10
                Group {
                    if type == .robot {
                        RoundedRectangle(cornerRadius: 1).fill(Color(red: 0.1, green: 0.6, blue: 0.9)).frame(width: size, height: size)
                    } else if type == .cat {
                        Capsule().fill(ink).frame(width: size * 0.55, height: size * 1.3)
                    } else {
                        Circle().fill(ink).frame(width: size, height: size)
                            .overlay(Circle().fill(Color.white).frame(width: 3, height: 3).offset(x: -2, y: -2))
                    }
                }
                .offset(face.eyeOffset)
            }
        }
        .frame(width: 24, height: 26)
    }

    @ViewBuilder private var mouth: some View {
        if type == .penguin {
            beak(open: face.mood == .surprised || (face.mood == .eating && face.chomp))
        } else {
            switch face.mood {
            case .surprised:
                Ellipse().stroke(ink, lineWidth: 2.5).frame(width: 10, height: 12)
            case .sleepy:
                Capsule().fill(ink).frame(width: 10, height: 3)
            case .eating:
                if face.chomp {
                    Ellipse().fill(ink).frame(width: 16, height: 12)
                } else {
                    Capsule().fill(ink).frame(width: 16, height: 3)
                }
            case .tired:
                WavyMouth().stroke(ink, style: StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round)).frame(width: 20, height: 5)
            case .happy, .love:
                happyMouth
            }
        }
    }

    @ViewBuilder private var happyMouth: some View {
        let stroke = StrokeStyle(lineWidth: 2.3, lineCap: .round)
        switch type {
        case .cat, .bear:
            CatMouth().stroke(ink, style: stroke).frame(width: 18, height: 7)
        case .dog:
            ZStack(alignment: .top) {
                Capsule().fill(Color(red: 1, green: 0.45, blue: 0.55)).overlay(Capsule().stroke(ink, lineWidth: 1.8))
                    .frame(width: 11, height: 16).offset(y: 3)
                CatMouth().fill(type.fill).overlay(CatMouth().stroke(ink, style: stroke)).frame(width: 18, height: 7)
            }
            .frame(width: 18, height: 20)
            .offset(y: 5)
        case .bunny:
            VStack(spacing: 0) {
                CatMouth().stroke(ink, style: stroke).frame(width: 18, height: 7)
                HStack(spacing: 0) {
                    Rectangle().fill(Color.white).overlay(Rectangle().stroke(ink, lineWidth: 1.5)).frame(width: 5, height: 6)
                    Rectangle().fill(Color.white).overlay(Rectangle().stroke(ink, lineWidth: 1.5)).frame(width: 5, height: 6)
                }
                .offset(y: -3)
            }
        case .robot:
            RoundedRectangle(cornerRadius: 2).stroke(ink, lineWidth: 2).frame(width: 24, height: 7)
        default:
            SmileMouth().stroke(ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round)).frame(width: 22, height: 10)
        }
    }

    private func beak(open: Bool) -> some View {
        let orange = Color(red: 1, green: 0.62, blue: 0.2)
        return VStack(spacing: open ? 4 : 0) {
            Triangle(pointingDown: true).fill(orange).overlay(Triangle(pointingDown: true).stroke(ink, style: doodleLine)).frame(width: 18, height: 10)
            if open {
                Triangle().fill(orange).overlay(Triangle().stroke(ink, style: doodleLine)).frame(width: 14, height: 6)
            }
        }
    }
}

/// A doodle scaled down for menus, lists and pickers, with room above for hats and ears.
struct MiniDoodle: View {
    var type: DoodleType
    var hat: Hat = .none
    var glasses: Glasses = .none
    var scale: CGFloat

    var body: some View {
        DoodleView(type: type, hat: hat, glasses: glasses)
            .padding(.top, 56)
            .frame(width: 140, height: 176)
            .scaleEffect(scale)
            .frame(width: 140 * scale, height: 176 * scale)
    }
}
