import SwiftUI

struct MemoryPostcard: View {
    let session: WalkSession
    private var style: MemoryStyle { session.cardStyle ?? .postcard }
    private var ink: Color { style == .dusk ? HW.cream : HW.ink }
    private var muted: Color { style == .dusk ? HW.cream.opacity(0.7) : HW.muted }
    private var paper: Color { style == .dusk ? HW.ink : (style == .field ? HW.cream : Color(hex: 0xEFF1D9)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { Text(style == .field ? "LITTLE TRIP / FIELD NOTES" : "LITTLE TRIP / A LITTLE OUTSIDE").font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.2).foregroundStyle(muted); Spacer(); Image(systemName: session.plan.mood.symbol).font(.system(size: 20)) }
            Text(session.plan.mood.title + " looks\ngood on you.").font(.system(size: 36, weight: .semibold, design: .rounded)).tracking(-1)
            ZStack {
                if style == .field {
                    ForEach(0..<8) { i in Rectangle().fill(HW.line).frame(height: 1).offset(y: CGFloat(i) * 28 - 98) }
                } else {
                    Circle().fill(session.plan.mood.color.opacity(style == .dusk ? 0.65 : 0.4)).frame(width: 176, height: 176).offset(x: -50, y: -9)
                    Circle().fill(HW.sky.opacity(0.4)).frame(width: 90, height: 90).offset(x: 89, y: -45)
                }
                MemoryLine(variation: session.plan.variation ?? 0).stroke(HW.cream.opacity(0.95), style: StrokeStyle(lineWidth: 19, lineCap: .round))
                MemoryLine(variation: session.plan.variation ?? 0).stroke(style == .dusk ? HW.yellow : HW.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                Image(systemName: "sparkle").font(.system(size: 29)).foregroundStyle(HW.coral).offset(x: 36, y: 18)
                Circle().fill(HW.yellow).frame(width: 17, height: 17).overlay(Circle().stroke(HW.ink, lineWidth: 2)).offset(x: -70, y: 55)
            }.frame(height: 210).padding(.horizontal, 20).accessibilityHidden(true)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) { Text(session.startedAt.formatted(.dateTime.month(.abbreviated).day().year())).font(.system(size: 14, weight: .semibold)); Text(session.atmosphere).font(.system(size: 12)).foregroundStyle(muted) }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) { Text(session.displayDuration).font(.system(size: 14, weight: .semibold)); Text("\(session.moments.count) moments").font(.system(size: 12)).foregroundStyle(muted) }
            }
            if !session.reflection.isEmpty { Text(session.reflection).font(.system(size: 14)).lineSpacing(3).fixedSize(horizontal: false, vertical: true) }
            Rectangle().fill(ink.opacity(0.15)).frame(height: 1)
            Text("YOUR OWN PATH. YOUR OWN PACE.").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1.7)
        }.padding(26).foregroundStyle(ink).background(paper, in: RoundedRectangle(cornerRadius: 28))
    }
}

struct MemoryView: View {
    @EnvironmentObject private var store: WalkStore
    var id: UUID
    var back: () -> Void
    @State private var reflection = ""
    @State private var atmosphere = "Just outside"
    @State private var confirmDelete = false
    @State private var momentTarget: MomentTarget?
    @State private var shareImage: Image?
    @State private var readyToShare = false
    @State private var reflectionSaved = false
    private let atmospheres = ["Just outside", "Felt sunny", "Soft & quiet", "A little breezy", "Full of color"]
    var body: some View {
        Group {
            if let session = store.session(id) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeader(label: "Way memory", back: back)
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Keep the feeling.").font(.system(size: 34, weight: .semibold, design: .rounded)).tracking(-1)
                            Text("A small piece of a day well wandered.").font(.system(size: 14)).foregroundStyle(HW.muted)
                        }
                        MemoryPostcard(session: session)
                        HStack(spacing: 8) {
                            ForEach(MemoryStyle.allCases) { style in
                                Button { withAnimation(.easeInOut(duration: 0.2)) { store.styleMemory(id: id, style: style) }; readyToShare = false } label: { Text(style.rawValue).font(.system(size: 12, weight: .medium)).frame(maxWidth: .infinity).padding(.vertical, 13).background((session.cardStyle ?? .postcard) == style ? HW.yellow : .white, in: Capsule()) }.accessibilityAddTraits((session.cardStyle ?? .postcard) == style ? .isSelected : [])
                            }
                        }
                        Text("An expressive keepsake, not a GPS trace.").font(.system(size: 10)).foregroundStyle(HW.muted).frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 14) {
                            Kicker(text: "How did it feel?")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) { ForEach(atmospheres, id: \.self) { option in Button { atmosphere = option; reflectionSaved = false; readyToShare = false } label: { Text(option).font(.system(size: 12, weight: .medium)).padding(.horizontal, 15).padding(.vertical, 12).background(atmosphere == option ? HW.yellow : .white, in: Capsule()) }.accessibilityAddTraits(atmosphere == option ? .isSelected : []) } }
                            }
                            TextField("One thing to remember…", text: $reflection, axis: .vertical).lineLimit(3...6).font(.system(size: 15)).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20)).onChange(of: reflection) { _, _ in reflectionSaved = false; readyToShare = false }
                            Button { saveReflection(); reflectionSaved = true; readyToShare = false } label: { Label(reflectionSaved ? "Reflection saved" : "Save reflection", systemImage: reflectionSaved ? "checkmark.circle" : "checkmark").font(.system(size: 13, weight: .semibold)) }
                        }
                        if !session.moments.isEmpty {
                            VStack(alignment: .leading, spacing: 12) { Kicker(text: "Moments you kept"); ForEach(session.moments) { moment in Button { momentTarget = MomentTarget(id: moment.id, sessionID: id) } label: { MomentRow(moment: moment) }.buttonStyle(.plain) } }
                        }
                        if readyToShare, let shareImage {
                            ShareLink(item: shareImage, preview: SharePreview("My Little Trip", image: shareImage)) {
                                HStack { Text("Share Your Memory").fontWeight(.semibold); Spacer(); Image(systemName: "square.and.arrow.up") }.padding(22).foregroundStyle(HW.cream).background(HW.ink, in: Capsule())
                            }
                        } else {
                            ActionButton(title: "Make a Share Card", symbol: "square.and.arrow.up") { makeShareCard() }
                        }
                        Text("The share card includes your reflection, feeling and walk time. Your moment notes and photos stay private.").font(.system(size: 11)).foregroundStyle(HW.muted)
                        Button("Delete this walk", role: .destructive) { confirmDelete = true }.font(.footnote).frame(maxWidth: .infinity).padding(10)
                    }.padding(24)
                }
            } else { ContentUnavailableView("Memory not found", systemImage: "leaf", description: Text("This walk may have been deleted.")) }
        }.onAppear { if let session = store.session(id) { reflection = session.reflection; atmosphere = session.atmosphere } }
            .sheet(item: $momentTarget) { MomentEditor(target: $0) }
            .confirmationDialog("Delete this walk and its saved moments?", isPresented: $confirmDelete, titleVisibility: .visible) { Button("Delete Walk", role: .destructive) { store.deleteMemory(id); back() } }
    }
    private func saveReflection() { store.reflect(id: id, text: String(reflection.prefix(2000)), atmosphere: atmosphere) }
    @MainActor private func makeShareCard() {
        saveReflection()
        guard let session = store.session(id) else { return }
        let renderer = ImageRenderer(content: MemoryPostcard(session: session).frame(width: 380).padding(20).background(HW.cream))
        renderer.scale = 3
        if let uiImage = renderer.uiImage { shareImage = Image(uiImage: uiImage); readyToShare = true }
        else { store.errorMessage = "Your share card could not be created. Please try again." }
    }
}

struct LandscapeView: View {
    @EnvironmentObject private var store: WalkStore
    var back: () -> Void
    var openMemory: (UUID) -> Void
    @State private var filter: WalkMood?
    private var visibleMemories: [WalkSession] { store.memories.filter { filter == nil || $0.plan.mood == filter } }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(label: "Personal landscape", back: back)
                Text("A world\nof little walks.").font(.system(size: 42, weight: .semibold, design: .rounded)).tracking(-1.5)
                Text("Your days outside, growing into something personal.").font(.system(size: 15)).foregroundStyle(HW.muted)
                ZStack {
                    RoundedRectangle(cornerRadius: 28).fill(Color(hex: 0xE8EDD5))
                    if store.memories.isEmpty {
                        RoadLandscape(mood: .fresh, compact: true).opacity(0.6).clipShape(RoundedRectangle(cornerRadius: 28))
                        Image(systemName: "leaf").font(.system(size: 28)).frame(width: 68, height: 68).background(HW.cream, in: Circle())
                    } else {
                        GeometryReader { g in
                            ForEach(Array(store.memories.prefix(12).enumerated()), id: \.element.id) { i, session in
                                let col = i % 3; let row = i / 3
                                MemoryLine(variation: session.plan.variation ?? 0)
                                    .stroke(session.plan.mood.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: g.size.width * 0.45, height: 95)
                                    .rotationEffect(.degrees(Double(i % 3 - 1) * 20))
                                    .position(x: g.size.width * (0.22 + Double(col) * 0.27), y: 50 + Double(row) * 49)
                            }
                        }.padding(10)
                    }
                }.frame(height: 260).accessibilityLabel("Abstract landscape of \(store.memories.count) completed walks")
                if store.memories.isEmpty {
                    VStack(alignment: .leading, spacing: 13) {
                        Text("Your first path starts outside.").font(.system(size: 22, weight: .semibold, design: .rounded))
                        Text("Finish a walk to save its time, mood and moments here. There is no rush to fill this space.").font(.system(size: 14)).foregroundStyle(HW.muted).lineSpacing(4)
                        ActionButton(title: "Find My First Way", yellow: true, action: back).padding(.top, 10)
                    }
                } else {
                    HStack { Kicker(text: "\(store.memories.count) walks, all yours"); Spacer(); Text("Saved on this device").font(.system(size: 10)).foregroundStyle(HW.muted) }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterButton("All", mood: nil)
                            ForEach(WalkMood.allCases) { mood in filterButton(mood.title, mood: mood) }
                        }
                    }
                    if visibleMemories.isEmpty { Text("No \(filter?.title.lowercased() ?? "") walks yet.").font(.subheadline).foregroundStyle(HW.muted).padding(.vertical, 20) }
                    ForEach(visibleMemories) { session in
                        Button { openMemory(session.id) } label: {
                            HStack(spacing: 16) {
                                MemoryLine(variation: session.plan.variation ?? 0).stroke(HW.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round)).padding(9).frame(width: 72, height: 72).background(session.plan.mood.color.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
                                VStack(alignment: .leading, spacing: 7) { Text("A \(session.plan.mood.title.lowercased()) little escape").font(.system(size: 16, weight: .semibold)); Text(session.startedAt.formatted(.dateTime.month(.abbreviated).day()) + " · " + session.displayDuration).font(.system(size: 12)).foregroundStyle(HW.muted); Text("\(session.moments.count) saved moments").font(.system(size: 11)).foregroundStyle(HW.muted) }
                                Spacer(); Image(systemName: "arrow.up.right").font(.system(size: 14))
                            }.padding(15).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 24))
                        }.buttonStyle(PressButtonStyle())
                    }
                }
            }.padding(24)
        }
    }
    private func filterButton(_ title: String, mood: WalkMood?) -> some View {
        Button { filter = mood } label: { Text(title).font(.system(size: 12, weight: .medium)).padding(.horizontal, 16).padding(.vertical, 10).background(filter == mood ? HW.yellow : .white, in: Capsule()) }.accessibilityAddTraits(filter == mood ? .isSelected : [])
    }
}
