import SwiftUI

@main
struct LittleTripApp: App {
    @StateObject private var store = WalkStore()
    var body: some Scene {
        WindowGroup {
            WayHome().environmentObject(store).tint(HW.ink).preferredColorScheme(.light)
                .alert("A little interruption", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                    Button("OK") { store.errorMessage = nil }
                } message: { Text(store.errorMessage ?? "") }
        }
    }
}

enum WayScreen: Hashable {
    case time, reveal, flow, landscape, memory(UUID)
}

struct WayHome: View {
    @EnvironmentObject private var store: WalkStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [WayScreen] = []
    @State private var plan = WalkPlan()
    @State private var showAbout = false
    @State private var feedback = 0

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            HStack(spacing: 9) {
                                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath").font(.system(size: 22, weight: .semibold))
                                Text("little trip").font(.system(size: 24, weight: .bold, design: .rounded)).tracking(-1)
                            }.accessibilityLabel("Little Trip")
                            Spacer()
                            RoundButton(symbol: "square.grid.2x2", label: "Personal Landscape") { path.append(.landscape) }
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Kicker(text: "Less planning. More wandering."); Spacer(); SunSeal(size: 34) }
                            Text("A little outside.\nA lot more you.").font(.system(size: 43, weight: .semibold, design: .rounded)).tracking(-1.9).lineSpacing(-2).fixedSize(horizontal: false, vertical: true)
                        }
                        ZStack(alignment: .bottomLeading) {
                            RoadLandscape(mood: plan.mood)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.mood.title + " state of mind").font(.system(size: 16, weight: .semibold))
                                Text("Swipe to find your feeling").font(.system(size: 11)).foregroundStyle(HW.muted)
                            }.padding(14).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17)).padding(16)
                        }.frame(height: min(305, max(218, geo.size.height * 0.34))).clipShape(RoundedRectangle(cornerRadius: 30))
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 25).onEnded { value in
                                let moods = WalkMood.allCases; let i = moods.firstIndex(of: plan.mood) ?? 0
                                choose(moods[(i + (value.translation.width < 0 ? 1 : moods.count - 1)) % moods.count])
                            })
                            .accessibilityElement(children: .ignore).accessibilityLabel("Mood: \(plan.mood.title)")
                            .accessibilityValue(plan.mood.subtitle)
                            .accessibilityAdjustableAction { direction in
                                let moods = WalkMood.allCases; let i = moods.firstIndex(of: plan.mood) ?? 0
                                choose(moods[(i + (direction == .increment ? 1 : moods.count - 1)) % moods.count])
                            }
                        VStack(alignment: .leading, spacing: 13) {
                            HStack { Kicker(text: "How do you feel?"); Spacer(); Text("01 / 03").font(.system(size: 10, design: .monospaced)).foregroundStyle(HW.muted) }
                            HStack(spacing: 7) {
                                ForEach(WalkMood.allCases) { mood in
                                    Button { choose(mood) } label: {
                                        VStack(spacing: 8) { Image(systemName: mood.symbol).font(.system(size: 21, weight: .regular)).frame(height: 25); Text(mood.title).font(.system(size: 10, weight: .semibold)) }
                                            .frame(maxWidth: .infinity).frame(height: 77)
                                            .background(plan.mood == mood ? mood.color : Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))
                                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(plan.mood == mood ? HW.ink.opacity(0.15) : HW.line, lineWidth: 1))
                                    }.buttonStyle(PressButtonStyle()).accessibilityLabel("\(mood.title) mood").accessibilityAddTraits(plan.mood == mood ? .isSelected : [])
                                }
                            }
                            Text(plan.mood.subtitle).font(.system(size: 13)).foregroundStyle(HW.muted).frame(maxWidth: .infinity)
                        }
                        ActionButton(title: store.active == nil ? "Create My Way" : "Return to My Walk", yellow: true) {
                            path.append(store.active == nil ? .time : .flow)
                        }
                        Button { showAbout = true } label: {
                            HStack(spacing: 5) { Image(systemName: "arrow.up.right"); Text("Your pace. Your path. A little inspiration.") }.font(.system(size: 11)).foregroundStyle(HW.muted).frame(maxWidth: .infinity).padding(.vertical, 3)
                        }
                    }.padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 22)
                }.background(HW.cream)
            }.foregroundStyle(HW.ink).toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: WayScreen.self) { screen in
                    Group {
                        switch screen {
                        case .time: TimeShapeView(plan: $plan, back: pop) { path.append(.reveal) }
                        case .reveal: RevealView(plan: $plan, back: pop) { store.start(plan); if store.active != nil { path.append(.flow) } }
                        case .flow: FlowView(back: { path = [] }) { id in path = [.memory(id)] }
                        case .landscape: LandscapeView(back: pop) { path.append(.memory($0)) }
                        case .memory(let id): MemoryView(id: id, back: pop)
                        }
                    }.toolbar(.hidden, for: .navigationBar).background(HW.cream).foregroundStyle(HW.ink)
                }
                .sheet(isPresented: $showAbout) { AboutView() }
                .sensoryFeedback(.selection, trigger: feedback)
        }
    }
    private func choose(_ mood: WalkMood) { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) { plan.mood = mood }; feedback += 1 }
    private func pop() { if !path.isEmpty { path.removeLast() } }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    SunSeal(size: 55)
                    Text("A companion for\na little outside.").font(.system(size: 32, weight: .semibold, design: .rounded))
                    Text("Little Trip turns a mood and a little free time into a self-guided walk. Choose your own streets and let the prompts help you notice more.")
                    Label("Walk ideas, not turn-by-turn directions", systemImage: "point.topleft.down.to.point.bottomright.curvepath").font(.headline)
                    Text("The road illustrations are expressive shapes, not geographic routes. Little Trip does not measure distance, track your position, or check nearby conditions.").foregroundStyle(HW.muted)
                    Label("Your memories stay with you", systemImage: "lock").font(.headline)
                    Text("Walks, notes and selected photos are saved on this device. No account, ads or analytics. Everything works offline once a selected photo is available on your device. Sharing a memory is always your choice.").foregroundStyle(HW.muted)
                    Text("You can delete individual moments and saved walks from their detail screens. Uninstalling the app removes its local data. Your device backup settings may also apply.").font(.footnote).foregroundStyle(HW.muted)
                    Kicker(text: "Little Trip · Version 1.0")
                }.padding(26)
            }.background(HW.cream).foregroundStyle(HW.ink)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
