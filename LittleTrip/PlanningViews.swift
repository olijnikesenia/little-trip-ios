import SwiftUI

struct TimeShapeView: View {
    @Binding var plan: WalkPlan
    var back: () -> Void
    var next: () -> Void
    @State private var feedback = 0
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                PageHeader(label: "Time shape · 02 / 03", back: back)
                VStack(alignment: .leading, spacing: 12) {
                    Text("How much\noutside time?").font(.system(size: 42, weight: .semibold, design: .rounded)).tracking(-1.5)
                    Text("Make a little space in your day.").foregroundStyle(HW.muted).font(.system(size: 15))
                }
                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(plan.minutes)").font(.system(size: 75, weight: .medium, design: .rounded)).monospacedDigit().tracking(-4)
                        Text("minutes").font(.system(size: 17)).foregroundStyle(HW.muted)
                    }.padding(.top, 15)
                    GeometryReader { geo in
                        ZStack {
                            MemoryLine(variation: plan.minutes / 15).stroke(HW.green.opacity(0.15), style: StrokeStyle(lineWidth: 26, lineCap: .round))
                            MemoryLine(variation: plan.minutes / 15).trim(from: 0, to: CGFloat(plan.minutes) / 120).stroke(HW.ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            Circle().fill(HW.yellow).frame(width: 28, height: 28).overlay(Image(systemName: "arrow.left.and.right").font(.system(size: 10, weight: .bold))).position(x: geo.size.width * 0.18, y: geo.size.height * 0.74)
                        }.contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            let amount = Int((min(1, max(0, value.location.x / geo.size.width)) * 105 + 15) / 5) * 5
                            if amount != plan.minutes { plan.minutes = amount; feedback += 1 }
                        })
                    }.frame(height: 150).padding(.horizontal, 35)
                        .accessibilityElement(children: .ignore).accessibilityLabel("Walk duration").accessibilityValue("\(plan.minutes) minutes")
                        .accessibilityAdjustableAction { direction in plan.minutes = min(120, max(15, plan.minutes + (direction == .increment ? 5 : -5))); feedback += 1 }
                    Text("DRAG ACROSS THE LINE TO STRETCH YOUR TIME").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(0.9).foregroundStyle(HW.muted).padding(.vertical, 16)
                }.frame(maxWidth: .infinity).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 30))
                HStack(spacing: 10) {
                    ForEach([15, 30, 60, 120], id: \.self) { value in
                        Button { plan.minutes = value; feedback += 1 } label: {
                            Text(value == 120 ? "2 hours" : "\(value) min").font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 44).background(plan.minutes == value ? HW.yellow : .white.opacity(0.7), in: Capsule())
                        }.accessibilityLabel("\(value) minutes").accessibilityAddTraits(plan.minutes == value ? .isSelected : [])
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    Kicker(text: "Make it yours").padding(.bottom, 16)
                    option("A familiar finish", detail: "Remind me to find my way back", symbol: "arrow.uturn.backward", value: $plan.returnToStart)
                    Divider().padding(.vertical, 14)
                    option("Keep it gentle", detail: "Begin with an easy pace", symbol: "feather", value: $plan.easyPace)
                    Divider().padding(.vertical, 14)
                    option("Room for a pause", detail: "Include a coffee or rest prompt", symbol: "cup.and.saucer", value: $plan.includePause)
                }
                ActionButton(title: "Reveal My Way", action: next)
            }.padding(24)
        }.sensoryFeedback(.selection, trigger: feedback)
    }
    private func option(_ title: String, detail: String, symbol: String, value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            HStack(spacing: 12) { Image(systemName: symbol).font(.system(size: 19)).frame(width: 30); VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 15, weight: .medium)); Text(detail).font(.system(size: 11)).foregroundStyle(HW.muted) } }
        }.tint(HW.green)
    }
}

struct RevealView: View {
    @Binding var plan: WalkPlan
    var back: () -> Void
    var start: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var remixFeedback = 0
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 23) {
                PageHeader(label: "Your way · 03 / 03", back: back)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 9) {
                        Kicker(text: "\(plan.mood.title) by nature")
                        Text("A good day\nto get a little lost.").font(.system(size: 37, weight: .semibold, design: .rounded)).tracking(-1.3)
                    }
                    Spacer(); SunSeal(size: 43).padding(.top, 22)
                }
                ZStack(alignment: .bottom) {
                    RoadLandscape(mood: plan.mood, variation: plan.variation ?? 0).opacity(appeared ? 1 : 0.1)
                    HStack { InfoPill(text: "\(plan.minutes) min", symbol: "clock"); InfoPill(text: "\(plan.prompts.count) little chapters", symbol: "point.3.connected.trianglepath.dotted") }.padding(17)
                }.frame(height: 270).clipShape(RoundedRectangle(cornerRadius: 28))
                HStack {
                    Text(plan.mood.intention).font(.system(size: 16, weight: .medium))
                    Spacer()
                    Button { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { plan.remix() }; remixFeedback += 1 } label: { Image(systemName: "shuffle").font(.system(size: 19)).frame(width: 47, height: 47).background(HW.yellow, in: Circle()) }.accessibilityLabel("Remix walk ideas")
                }
                VStack(spacing: 0) {
                    ForEach(Array(plan.prompts.enumerated()), id: \.offset) { i, prompt in
                        HStack(spacing: 13) {
                            Text(String(format: "%02d", i + 1)).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(HW.muted).frame(width: 26)
                            Text(prompt.title).font(.system(size: 14, weight: .medium))
                            Spacer(); Image(systemName: prompt.symbol).font(.system(size: 16)).foregroundStyle(HW.muted)
                        }.padding(.vertical, 16)
                        if i < plan.prompts.count - 1 { Divider() }
                    }
                }.padding(.horizontal, 19).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 22))
                Text("A self-guided walk with timed prompts. Choose your own streets — the illustration is not a map.").font(.system(size: 12)).foregroundStyle(HW.muted).fixedSize(horizontal: false, vertical: true)
                ActionButton(title: "Let's Go Outside", symbol: "arrow.right", yellow: true, action: start)
            }.padding(24)
        }.onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.85)) { appeared = true } }.sensoryFeedback(.selection, trigger: remixFeedback)
    }
}
