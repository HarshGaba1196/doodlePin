import SwiftUI

struct BlobShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addCurve(to: CGPoint(x: w, y: h * 0.55), control1: CGPoint(x: w * 0.88, y: h * 0.02), control2: CGPoint(x: w * 1.02, y: h * 0.25))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h), control1: CGPoint(x: w * 0.98, y: h * 0.9), control2: CGPoint(x: w * 0.75, y: h))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.58), control1: CGPoint(x: w * 0.22, y: h), control2: CGPoint(x: -0.02 * w, y: h * 0.88))
        p.addCurve(to: CGPoint(x: w * 0.5, y: 0), control1: CGPoint(x: w * 0.02, y: h * 0.22), control2: CGPoint(x: w * 0.15, y: -0.02 * h))
        return p.offsetBy(dx: r.minX, dy: r.minY)
    }
}

struct CatShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.08, y: h * 0.45))
        p.addLine(to: CGPoint(x: w * 0.12, y: 0))
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.22))
        p.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.22), control: CGPoint(x: w * 0.5, y: h * 0.18))
        p.addLine(to: CGPoint(x: w * 0.88, y: 0))
        p.addLine(to: CGPoint(x: w * 0.92, y: h * 0.45))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h), control1: CGPoint(x: w * 1.02, y: h * 0.85), control2: CGPoint(x: w * 0.8, y: h))
        p.addCurve(to: CGPoint(x: w * 0.08, y: h * 0.45), control1: CGPoint(x: w * 0.2, y: h), control2: CGPoint(x: -0.02 * w, y: h * 0.85))
        p.closeSubpath()
        return p.offsetBy(dx: r.minX, dy: r.minY)
    }
}

struct GhostShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h * 0.45))
        p.addCurve(to: CGPoint(x: w, y: h * 0.45), control1: CGPoint(x: 0, y: -h * 0.12), control2: CGPoint(x: w, y: -h * 0.12))
        p.addLine(to: CGPoint(x: w, y: h * 0.9))
        let waves = 4
        for i in 0..<waves {
            let x0 = w - CGFloat(i) * w / CGFloat(waves)
            let x1 = x0 - w / CGFloat(waves)
            p.addQuadCurve(to: CGPoint(x: x1, y: h * 0.9), control: CGPoint(x: (x0 + x1) / 2, y: i % 2 == 0 ? h * 1.08 : h * 0.78))
        }
        p.closeSubpath()
        return p.offsetBy(dx: r.minX, dy: r.minY)
    }
}

struct CloudShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.15, y: h * 0.95))
        p.addQuadCurve(to: CGPoint(x: w * 0.1, y: h * 0.5), control: CGPoint(x: -w * 0.08, y: h * 0.8))
        p.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.2), control: CGPoint(x: w * 0.1, y: h * 0.18))
        p.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.18), control: CGPoint(x: w * 0.52, y: -h * 0.12))
        p.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.5), control: CGPoint(x: w * 0.95, y: h * 0.15))
        p.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.95), control: CGPoint(x: w * 1.08, y: h * 0.8))
        p.closeSubpath()
        return p.offsetBy(dx: r.minX, dy: r.minY)
    }
}

/// Wide at the top, narrow at the chin.
struct AlienHeadShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addCurve(to: CGPoint(x: w, y: h * 0.42), control1: CGPoint(x: w * 0.85, y: 0), control2: CGPoint(x: w, y: h * 0.15))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h), control1: CGPoint(x: w, y: h * 0.75), control2: CGPoint(x: w * 0.7, y: h))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.42), control1: CGPoint(x: w * 0.3, y: h), control2: CGPoint(x: 0, y: h * 0.75))
        p.addCurve(to: CGPoint(x: w * 0.5, y: 0), control1: CGPoint(x: 0, y: h * 0.15), control2: CGPoint(x: w * 0.15, y: 0))
        return p.offsetBy(dx: r.minX, dy: r.minY)
    }
}

struct HeartShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: h))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.3), control1: CGPoint(x: w * 0.15, y: h * 0.75), control2: CGPoint(x: 0, y: h * 0.55))
        p.addArc(center: CGPoint(x: w * 0.25, y: h * 0.28), radius: w * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: w * 0.75, y: h * 0.28), radius: w * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: w * 0.5, y: h), control1: CGPoint(x: w, y: h * 0.55), control2: CGPoint(x: w * 0.85, y: h * 0.75))
        p.closeSubpath()
        return p.offsetBy(dx: r.minX, dy: r.minY)
    }
}

struct Triangle: Shape {
    var pointingDown = false
    func path(in r: CGRect) -> Path {
        var p = Path()
        if pointingDown {
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        } else {
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        }
        p.closeSubpath()
        return p
    }
}

/// A little "w" mouth, as on cats and dogs.
struct CatMouth: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX + w / 2, y: r.minY), control: CGPoint(x: r.minX + w / 4, y: r.minY + h))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.minX + w * 0.75, y: r.minY + h))
        return p
    }
}

struct SmileMouth: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.2))
        return p
    }
}

struct WavyMouth: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let steps = 4
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        for i in 1...steps {
            let x = r.minX + r.width * CGFloat(i) / CGFloat(steps)
            p.addLine(to: CGPoint(x: x, y: i % 2 == 0 ? r.midY : r.minY))
        }
        return p
    }
}

struct ClosedEye: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY))
        return p
    }
}
