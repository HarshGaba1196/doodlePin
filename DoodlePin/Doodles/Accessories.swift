import SwiftUI

/// A hat, drawn into a 70×64 box whose bottom edge sits on the head.
struct HatView: View {
    let hat: Hat

    var body: some View {
        Canvas { ctx, _ in HatView.draw(hat, in: ctx) }
            .frame(width: 70, height: 64)
            .rotationEffect(.degrees([.bow, .flower, .halo].contains(hat) ? 0 : -7), anchor: .bottom)
    }

    private static let outline = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)

    private static func paint(_ ctx: GraphicsContext, _ path: Path, _ color: Color) {
        ctx.fill(path, with: .color(color))
        ctx.stroke(path, with: .color(ink), style: outline)
    }

    private static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    static func draw(_ hat: Hat, in ctx: GraphicsContext) {
        switch hat {
        case .none:
            break

        case .party:
            var cone = Path()
            cone.move(to: CGPoint(x: 18, y: 62)); cone.addLine(to: CGPoint(x: 35, y: 16)); cone.addLine(to: CGPoint(x: 52, y: 62)); cone.closeSubpath()
            ctx.fill(cone, with: .color(Color(red: 1, green: 0.45, blue: 0.65)))
            for (x, y) in [(29.0, 50.0), (41.0, 44.0), (34.0, 32.0)] {
                ctx.fill(circle(x, y, 3), with: .color(Color(red: 1, green: 0.9, blue: 0.3)))
            }
            ctx.stroke(cone, with: .color(ink), style: outline)
            paint(ctx, circle(35, 13, 7), Color(red: 1, green: 0.85, blue: 0.2))

        case .topHat:
            paint(ctx, Path(roundedRect: CGRect(x: 19, y: 18, width: 32, height: 38), cornerRadius: 3), Color(red: 0.15, green: 0.15, blue: 0.2))
            ctx.fill(Path(CGRect(x: 20, y: 45, width: 30, height: 7)), with: .color(Color(red: 0.9, green: 0.2, blue: 0.3)))
            paint(ctx, Path(roundedRect: CGRect(x: 8, y: 54, width: 54, height: 8), cornerRadius: 4), Color(red: 0.15, green: 0.15, blue: 0.2))

        case .crown:
            var c = Path()
            c.move(to: CGPoint(x: 15, y: 60)); c.addLine(to: CGPoint(x: 15, y: 30)); c.addLine(to: CGPoint(x: 25, y: 44))
            c.addLine(to: CGPoint(x: 35, y: 24)); c.addLine(to: CGPoint(x: 45, y: 44)); c.addLine(to: CGPoint(x: 55, y: 30))
            c.addLine(to: CGPoint(x: 55, y: 60)); c.closeSubpath()
            paint(ctx, c, Color(red: 1, green: 0.82, blue: 0.2))
            ctx.fill(circle(35, 51, 4), with: .color(.red))
            ctx.fill(circle(24, 53, 3), with: .color(.blue))
            ctx.fill(circle(46, 53, 3), with: .color(.green))
            for (x, y) in [(15.0, 28.0), (35.0, 22.0), (55.0, 28.0)] {
                paint(ctx, circle(x, y, 3.5), Color(red: 1, green: 0.82, blue: 0.2))
            }

        case .beanie:
            var dome = Path()
            dome.move(to: CGPoint(x: 12, y: 56)); dome.addQuadCurve(to: CGPoint(x: 58, y: 56), control: CGPoint(x: 35, y: 10)); dome.closeSubpath()
            paint(ctx, dome, Color(red: 0.2, green: 0.65, blue: 0.7))
            paint(ctx, circle(35, 30, 8), Color(white: 0.96))
            let band = Path(roundedRect: CGRect(x: 10, y: 50, width: 50, height: 12), cornerRadius: 4)
            paint(ctx, band, Color(red: 0.12, green: 0.5, blue: 0.55))
            for x in stride(from: 16.0, through: 54.0, by: 6.0) {
                var rib = Path(); rib.move(to: CGPoint(x: x, y: 53)); rib.addLine(to: CGPoint(x: x, y: 59))
                ctx.stroke(rib, with: .color(ink.opacity(0.4)), lineWidth: 1.5)
            }

        case .wizard:
            var cone = Path()
            cone.move(to: CGPoint(x: 15, y: 58)); cone.addQuadCurve(to: CGPoint(x: 44, y: 2), control: CGPoint(x: 28, y: 26))
            cone.addLine(to: CGPoint(x: 55, y: 58)); cone.closeSubpath()
            paint(ctx, cone, Color(red: 0.45, green: 0.3, blue: 0.8))
            ctx.draw(Text("★").font(.system(size: 11)).foregroundColor(.yellow), at: CGPoint(x: 33, y: 44))
            ctx.draw(Text("★").font(.system(size: 8)).foregroundColor(.yellow), at: CGPoint(x: 41, y: 26))
            paint(ctx, Path(ellipseIn: CGRect(x: 5, y: 53, width: 60, height: 10)), Color(red: 0.45, green: 0.3, blue: 0.8))

        case .cap:
            paint(ctx, Path(ellipseIn: CGRect(x: 36, y: 52, width: 32, height: 10)), Color(red: 0.15, green: 0.3, blue: 0.75))
            var dome = Path()
            dome.move(to: CGPoint(x: 13, y: 58)); dome.addQuadCurve(to: CGPoint(x: 57, y: 58), control: CGPoint(x: 35, y: 20)); dome.closeSubpath()
            paint(ctx, dome, Color(red: 0.25, green: 0.45, blue: 0.9))
            paint(ctx, circle(35, 39, 3), Color(red: 0.15, green: 0.3, blue: 0.75))

        case .bow:
            let pink = Color(red: 1, green: 0.45, blue: 0.65)
            var l = Path(); l.move(to: CGPoint(x: 48, y: 52)); l.addLine(to: CGPoint(x: 35, y: 43)); l.addLine(to: CGPoint(x: 35, y: 61)); l.closeSubpath()
            var r = Path(); r.move(to: CGPoint(x: 48, y: 52)); r.addLine(to: CGPoint(x: 61, y: 43)); r.addLine(to: CGPoint(x: 61, y: 61)); r.closeSubpath()
            paint(ctx, l, pink); paint(ctx, r, pink)
            paint(ctx, circle(48, 52, 4.5), Color(red: 0.9, green: 0.3, blue: 0.5))

        case .flower:
            for i in 0..<5 {
                let a = Double(i) / 5 * 2 * .pi - .pi / 2
                paint(ctx, circle(48 + cos(a) * 8, 50 + sin(a) * 8, 6), .white)
            }
            paint(ctx, circle(48, 50, 5.5), Color(red: 1, green: 0.8, blue: 0.2))

        case .halo:
            let ring = Path(ellipseIn: CGRect(x: 14, y: 22, width: 42, height: 12))
            ctx.stroke(ring, with: .color(Color(red: 1, green: 0.85, blue: 0.25)), lineWidth: 5)
            ctx.stroke(ring, with: .color(ink.opacity(0.6)), lineWidth: 1)
        }
    }
}

/// Glasses, drawn over the eyes. `spacing` is the gap between the eyes.
struct GlassesView: View {
    let glasses: Glasses
    let spacing: CGFloat

    var body: some View {
        let dx = spacing / 2 + 12
        ZStack {
            switch glasses {
            case .none:
                EmptyView()
            case .sunglasses:
                ForEach([CGFloat(-1), 1], id: \.self) { side in
                    RoundedRectangle(cornerRadius: 7).fill(Color.black.opacity(0.9))
                        .overlay(Capsule().fill(Color.white.opacity(0.55)).frame(width: 9, height: 2.5).rotationEffect(.degrees(-30)).offset(x: -5, y: -4))
                        .frame(width: 28, height: 21)
                        .offset(x: side * dx)
                }
                Capsule().fill(ink).frame(width: spacing + 4, height: 3).offset(y: -4)
            case .round:
                ForEach([CGFloat(-1), 1], id: \.self) { side in
                    Circle().fill(Color.white.opacity(0.15)).overlay(Circle().stroke(ink, lineWidth: 2.4))
                        .frame(width: 30, height: 30)
                        .offset(x: side * dx)
                }
                Capsule().fill(ink).frame(width: max(spacing - 2, 4), height: 2.4).offset(y: -3)
            case .hearts:
                ForEach([CGFloat(-1), 1], id: \.self) { side in
                    HeartShape().fill(Color(red: 1, green: 0.35, blue: 0.55).opacity(0.8))
                        .overlay(HeartShape().stroke(ink, lineWidth: 2))
                        .frame(width: 30, height: 27)
                        .offset(x: side * dx, y: 1)
                }
                Capsule().fill(ink).frame(width: spacing, height: 2.4).offset(y: -4)
            }
        }
    }
}

/// Headphones the pets wear while music is playing.
struct HeadphonesView: View {
    let type: DoodleType

    var body: some View {
        let w = type.headWidth
        let cupY = 60 + type.faceY - 4
        let peak = 60 + type.headTop - 8
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 65 - w / 2 + 4, y: cupY))
                p.addQuadCurve(to: CGPoint(x: 65 + w / 2 - 4, y: cupY), control: CGPoint(x: 65, y: 2 * peak - cupY))
            }
            .stroke(ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            ForEach([CGFloat(-1), 1], id: \.self) { side in
                RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.95, green: 0.3, blue: 0.4))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ink, lineWidth: 2.2))
                    .frame(width: 16, height: 28)
                    .position(x: 65 + side * (w / 2 - 2), y: cupY)
            }
        }
        .frame(width: 130, height: 120)
    }
}
