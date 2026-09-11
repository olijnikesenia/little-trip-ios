import SwiftUI

enum HW {
    static let cream = Color(hex: 0xF7F4E9)
    static let green = Color(hex: 0x68C94C)
    static let yellow = Color(hex: 0xFFD34E)
    static let sky = Color(hex: 0x78CAF2)
    static let road = Color(hex: 0x42484F)
    static let coral = Color(hex: 0xFF715B)
    static let ink = Color(hex: 0x20344A)
    static let muted = Color(hex: 0x677368)
    static let line = Color(hex: 0xE4E5D8)
}

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}

extension WalkMood {
    var color: Color {
        switch self { case .clear: return HW.yellow; case .fresh: return HW.green; case .curious: return HW.coral; case .fast: return HW.sky; case .quiet: return Color(hex: 0xBDC9A5) }
    }
}

struct Kicker: View {
    var text: String
    var body: some View { Text(text.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(HW.muted) }
}

struct ActionButton: View {
    var title: String
    var symbol = "arrow.up.right"
    var yellow = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title).font(.system(size: 17, weight: .semibold)); Spacer(); Image(systemName: symbol).font(.system(size: 19, weight: .medium)) }
                .foregroundStyle(yellow ? HW.ink : HW.cream)
                .padding(.horizontal, 24).frame(minHeight: 62)
                .background(yellow ? HW.yellow : HW.ink, in: Capsule())
        }.buttonStyle(PressButtonStyle())
    }
}

struct PressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.8 : 1).scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
    }
}

struct RoundButton: View {
    let symbol: String
    let label: String
    var action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 18, weight: .medium)).foregroundStyle(HW.ink).frame(width: 48, height: 48).background(.white.opacity(0.75), in: Circle()).overlay(Circle().stroke(HW.line, lineWidth: 1)) }.accessibilityLabel(label).buttonStyle(PressButtonStyle())
    }
}

struct PageHeader: View {
    let label: String
    var back: () -> Void
    var body: some View { HStack { RoundButton(symbol: "arrow.left", label: "Back", action: back); Spacer(); Kicker(text: label); Spacer(); Color.clear.frame(width: 48, height: 48) } }
}

struct InfoPill: View {
    var text: String
    var symbol: String
    var body: some View { Label(text, systemImage: symbol).font(.system(size: 11, weight: .medium)).foregroundStyle(HW.ink).padding(.horizontal, 12).padding(.vertical, 8).background(.white.opacity(0.8), in: Capsule()) }
}

struct SunSeal: View {
    var size: CGFloat = 48
    var body: some View {
        ZStack {
            ForEach(0..<12) { i in Capsule().fill(HW.ink).frame(width: 2, height: size * 0.14).offset(y: -size * 0.39).rotationEffect(.degrees(Double(i) * 30)) }
            Circle().stroke(HW.ink, lineWidth: 1.8).frame(width: size * 0.43, height: size * 0.43)
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

struct WayLine: Shape {
    var bend: CGFloat = 0.5
    var animatableData: CGFloat { get { bend } set { bend = newValue } }
    func path(in rect: CGRect) -> Path {
        let w = rect.width; let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.36, y: h * 1.12))
        p.addCurve(to: CGPoint(x: w * 0.58, y: h * 0.64), control1: CGPoint(x: w * -0.05, y: h * 0.75), control2: CGPoint(x: w * 0.87, y: h * 0.93))
        p.addCurve(to: CGPoint(x: w * (0.35 + bend * 0.08), y: h * 0.32), control1: CGPoint(x: w * (0.16 - bend * 0.1), y: h * 0.39), control2: CGPoint(x: w * (0.06 + bend * 0.1), y: h * 0.50))
        p.addCurve(to: CGPoint(x: w * 0.62, y: -h * 0.12), control1: CGPoint(x: w * (0.92 + bend * 0.1), y: h * 0.02), control2: CGPoint(x: w * 0.24, y: h * 0.03))
        return p
    }
}

struct PebbleTree: View {
    var size: CGFloat = 42
    var body: some View {
        ZStack {
            Ellipse().fill(HW.ink.opacity(0.09)).frame(width: size * 1.2, height: size * 0.35).offset(x: 7, y: size * 0.36)
            Capsule().fill(Color(hex: 0x8F7953)).frame(width: 4, height: size * 0.5).offset(y: size * 0.35)
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0x97DB69), Color(hex: 0x48A849)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: size * 0.82, height: size)
            Ellipse().fill(.white.opacity(0.14)).frame(width: size * 0.28, height: size * 0.55).rotationEffect(.degrees(20)).offset(x: -size * 0.12, y: -size * 0.12)
        }.frame(width: size * 1.3, height: size * 1.5)
    }
}

struct RoadLandscape: View {
    var mood: WalkMood
    var progress: Double = 0
    var compact = false
    var variation = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ripplePoint: CGPoint = .zero
    @State private var rippleSize: CGFloat = 0
    @State private var rippleOpacity: Double = 0
    @State private var tapFeedback = 0
    private var bend: CGFloat { CGFloat(WalkMood.allCases.firstIndex(of: mood) ?? 0) * 0.25 + CGFloat(variation % 7) * 0.09 }
    var body: some View {
        GeometryReader { g in
            let w = g.size.width; let h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0xE9F0D3), Color(hex: 0xDFEBC7), Color(hex: 0xEDF0D3)], startPoint: .top, endPoint: .bottom)
                Ellipse().fill(mood.color.opacity(0.32)).frame(width: w * 1.15, height: h * 0.94).rotationEffect(.degrees(-25)).offset(x: -w * 0.4, y: h * 0.06)
                Ellipse().fill(HW.sky.opacity(0.6)).frame(width: w * 0.51, height: h * 0.95).rotationEffect(.degrees(25)).offset(x: w * 0.51, y: -h * 0.31)
                Ellipse().stroke(.white.opacity(0.32), lineWidth: 1).frame(width: w * 0.60, height: h * 0.96).rotationEffect(.degrees(25)).offset(x: w * 0.48, y: -h * 0.25)
                Circle().fill(HW.yellow.opacity(0.7)).frame(width: w * 0.43).offset(x: w * 0.44, y: h * 0.49)
                WayLine(bend: bend).stroke(Color(hex: 0xC7D3B4), style: StrokeStyle(lineWidth: compact ? 46 : 69, lineCap: .round)).offset(y: 7)
                WayLine(bend: bend).stroke(HW.cream, style: StrokeStyle(lineWidth: compact ? 42 : 63, lineCap: .round))
                WayLine(bend: bend).stroke(HW.road, style: StrokeStyle(lineWidth: compact ? 31 : 48, lineCap: .round))
                WayLine(bend: bend).stroke(HW.cream.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [7, 11]))
                PebbleTree(size: compact ? 23 : 41).position(x: w * 0.14, y: h * 0.21)
                PebbleTree(size: compact ? 18 : 30).position(x: w * 0.22, y: h * 0.27)
                PebbleTree(size: compact ? 28 : 49).position(x: w * 0.80, y: h * 0.68)
                PebbleTree(size: compact ? 16 : 26).position(x: w * 0.86, y: h * 0.81)
                if !compact {
                    VStack(spacing: 0) { Image(systemName: mood.symbol).font(.system(size: 22, weight: .medium)).frame(width: 54, height: 54).background(HW.yellow, in: Circle()).overlay(Circle().stroke(.white, lineWidth: 3)); Capsule().fill(HW.ink.opacity(0.12)).frame(width: 20, height: 5).padding(.top, 7) }.position(x: w * 0.48, y: h * (0.57 - progress * 0.15))
                    HStack(spacing: 6) { Circle().fill(HW.green).frame(width: 6, height: 6); Text("A LITTLE WANDER").font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1.5) }.padding(9).background(HW.cream.opacity(0.94), in: Capsule()).position(x: w * 0.72, y: h * 0.18)
                }
                Circle().stroke(HW.yellow, lineWidth: 3).frame(width: rippleSize, height: rippleSize).position(ripplePoint).opacity(rippleOpacity)
            }.clipped().animation(reduceMotion ? nil : .easeInOut(duration: 0.7), value: mood)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: variation)
                .onTapGesture { location in
                    guard !compact else { return }
                    ripplePoint = location; rippleSize = 12; rippleOpacity = 0.9; tapFeedback += 1
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.9)) { rippleSize = 115; rippleOpacity = 0 }
                }
                .sensoryFeedback(.selection, trigger: tapFeedback)
        }.accessibilityHidden(true)
    }
}

struct MemoryLine: Shape {
    var variation: Int = 0
    func path(in r: CGRect) -> Path {
        var p = Path(); let w = r.width; let h = r.height
        let shift = CGFloat(variation % 5) * 0.025
        p.move(to: CGPoint(x: w * 0.18, y: h * 0.74))
        p.addCurve(to: CGPoint(x: w * 0.58, y: h * 0.21), control1: CGPoint(x: -w * 0.04, y: h * 0.26), control2: CGPoint(x: w * 0.25, y: -h * 0.1))
        p.addCurve(to: CGPoint(x: w * 0.68, y: h * 0.76), control1: CGPoint(x: w * (1.12 - shift), y: h * 0.6), control2: CGPoint(x: w * 0.29, y: h * (0.37 + shift)))
        p.addCurve(to: CGPoint(x: w * 0.18, y: h * 0.74), control1: CGPoint(x: w * 1.02, y: h * 1.12), control2: CGPoint(x: w * 0.42, y: h * 1.1))
        return p
    }
}
