import SwiftUI

struct PocketIdea {
    let title: String
    let detail: String
    let symbol: String
    let color: Color
    static let all: [PocketIdea] = [
        .init(title: "Borrow a little yellow.", detail: "A door. A flower. A patch of light. Find a little yellow in the world around you.", symbol: "sun.max", color: HW.yellow),
        .init(title: "A street-sized alphabet.", detail: "Find a letter in something that isn't writing. A branch might be a Y. A railing might be an H.", symbol: "textformat.abc", color: HW.sky),
        .init(title: "Look for a tiny wild thing.", detail: "A leaf between stones or a plant on a windowsill. Notice something growing in its own way.", symbol: "leaf", color: HW.green),
        .init(title: "A frame within a frame.", detail: "Find a doorway or a gap between trees that frames a little scene. What would you call the picture?", symbol: "viewfinder", color: HW.coral),
        .init(title: "Collect three textures.", detail: "Without needing to touch anything, notice three different surfaces: smooth, rough, shiny, worn.", symbol: "square.stack.3d.up", color: HW.yellow),
        .init(title: "Follow a shadow with your eyes.", detail: "Notice a shadow nearby. Can you trace it back to the thing that made it?", symbol: "circle.lefthalf.filled", color: HW.sky),
        .init(title: "Give this corner a name.", detail: "Invent a private name for a place you're passing. The name can be as ordinary or strange as you like.", symbol: "text.bubble", color: HW.coral),
        .init(title: "Find a little blue.", detail: "Look for a blue detail below the sky. A sign, a reflection, or a forgotten bit of paint.", symbol: "drop", color: HW.sky),
        .init(title: "Spot a happy accident.", detail: "Two colors that work together. An unexpected reflection. A shape that almost looks like something else.", symbol: "sparkles", color: HW.yellow),
        .init(title: "The smallest gallery.", detail: "Choose one tiny detail you would photograph if you were making an exhibition about this street.", symbol: "photo.artframe", color: HW.green),
        .init(title: "Write a six-word postcard.", detail: "Describe this exact moment in six words. Or five. No one is counting.", symbol: "pencil.and.outline", color: HW.coral),
        .init(title: "Find something beautifully ordinary.", detail: "Look at an everyday object for a little longer. What is one detail you hadn't noticed?", symbol: "eye", color: HW.green)
    ]
}

struct PocketDeckView: View {
    @EnvironmentObject private var store: WalkStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var order = Array(PocketIdea.all.indices).shuffled()
    @State private var position = 0
    @State private var revealed = false
    @State private var saved: Set<Int> = []
    @State private var feedback = 0
    private var index: Int { order[position] }
    private var idea: PocketIdea { PocketIdea.all[index] }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Kicker(text: "A little detour for your attention")
                    Text("The ordinary\nis full of little things.").font(.system(size: 34, weight: .semibold, design: .rounded)).tracking(-1)
                    ZStack {
                        RoundedRectangle(cornerRadius: 28).fill(HW.ink.opacity(0.07)).rotationEffect(.degrees(-3)).offset(y: 7)
                        RoundedRectangle(cornerRadius: 28).fill(idea.color)
                        VStack(alignment: .leading, spacing: 22) {
                            HStack { Text("A NOTE FOR RIGHT NOW").font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.4); Spacer(); Image(systemName: revealed ? idea.symbol : "sparkle").font(.system(size: 23)) }
                            Spacer(minLength: 5)
                            if revealed {
                                Text(idea.title).font(.system(size: 33, weight: .semibold, design: .rounded)).tracking(-0.8)
                                Text(idea.detail).font(.system(size: 16)).lineSpacing(4)
                            } else {
                                SunSeal(size: 72)
                                Text("There's a little\nsomething out there.").font(.system(size: 31, weight: .semibold, design: .rounded)).tracking(-0.8)
                            }
                            Spacer(minLength: 5)
                            HStack { Text(revealed ? "A suggestion. Always optional." : "Tap to turn this note over").font(.system(size: 11)); Spacer(); Image(systemName: "arrow.turn.up.right") }
                        }.padding(28)
                    }.frame(minHeight: 350)
                        .rotation3DEffect(.degrees(revealed ? 0 : -3), axis: (x: 0, y: 1, z: 0))
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) { revealed.toggle() }; feedback += 1 }
                        .gesture(DragGesture(minimumDistance: 30).onEnded { _ in next() })
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction(named: "Turn note over") { revealed.toggle() }
                        .accessibilityAction(named: "Another idea", next)
                    Text("SWIPE FOR A DIFFERENT PERSPECTIVE").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1).foregroundStyle(HW.muted).frame(maxWidth: .infinity)
                    if revealed {
                        ActionButton(title: saved.contains(index) ? "Kept in Your Moments" : "Keep This Thought", symbol: saved.contains(index) ? "checkmark" : "bookmark") {
                            guard let session = store.active, let id = store.addMoment(), var moment = store.active?.moments.first(where: { $0.id == id }) else { return }
                            moment.note = idea.title + "\n" + idea.detail
                            moment.feeling = .surprising
                            store.updateMoment(moment, sessionID: session.id)
                            if store.errorMessage == nil { saved.insert(index); feedback += 1 }
                        }.disabled(saved.contains(index))
                    }
                    Button(action: next) { Label("Another little idea", systemImage: "shuffle").font(.system(size: 14, weight: .medium)).frame(maxWidth: .infinity).padding(12) }
                }.padding(24)
            }.background(HW.cream).foregroundStyle(HW.ink)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.sensoryFeedback(.selection, trigger: feedback)
    }
    private func next() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { position = (position + 1) % order.count; revealed = false }
        feedback += 1
    }
}

struct LittlePauseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var began = Date()
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: reduceMotion)) { context in
            let elapsed = context.date.timeIntervalSince(began)
            let phase = (sin(elapsed * .pi / 4) + 1) / 2
            VStack(spacing: 30) {
                HStack { Kicker(text: "A small pocket of stillness"); Spacer(); RoundButton(symbol: "xmark", label: "Close pause") { dismiss() } }
                Spacer()
                Text("Nothing to find.\nJust a little pause.").font(.system(size: 35, weight: .semibold, design: .rounded)).tracking(-1).multilineTextAlignment(.center)
                ZStack {
                    Circle().fill(HW.green.opacity(0.12)).frame(width: 245, height: 245).scaleEffect(reduceMotion ? 1 : 0.85 + phase * 0.15)
                    Circle().stroke(HW.green.opacity(0.3), lineWidth: 1).frame(width: 200, height: 200).scaleEffect(reduceMotion ? 1 : 0.75 + phase * 0.25)
                    Circle().fill(LinearGradient(colors: [HW.yellow, Color(hex: 0xF4C248)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 125, height: 125).scaleEffect(reduceMotion ? 1 : 0.95 + phase * 0.05)
                    SunSeal(size: 60)
                }.frame(height: 255).accessibilityHidden(true)
                Text("Find a comfortable place to stop.\nLook up. Let your shoulders settle.").font(.system(size: 16)).lineSpacing(5).multilineTextAlignment(.center).foregroundStyle(HW.muted)
                Text("YOUR WALK TIMER IS PAUSED").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.5).foregroundStyle(HW.muted)
                Spacer()
                ActionButton(title: "Back to My Walk", symbol: "arrow.right", yellow: true) { dismiss() }
            }.padding(26).frame(maxWidth: .infinity, maxHeight: .infinity).background(HW.cream).foregroundStyle(HW.ink)
        }
    }
}
