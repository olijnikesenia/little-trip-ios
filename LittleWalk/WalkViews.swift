import SwiftUI
import PhotosUI

struct MomentTarget: Identifiable { var id: UUID; var sessionID: UUID }

struct FlowView: View {
    @EnvironmentObject private var store: WalkStore
    var back: () -> Void
    var finished: (UUID) -> Void
    @State private var momentTarget: MomentTarget?
    @State private var finishPrompt = false
    @State private var markFeedback = 0
    @State private var lastChapter = 0
    @State private var showPocket = false
    @State private var showPause = false
    @State private var resumeAfterPause = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let session = store.active {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let elapsed = session.elapsed(at: context.date)
                    let progress = session.progress(at: context.date)
                    let index = session.promptIndex(at: context.date)
                    let prompt = session.plan.prompts[index]
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                RoundButton(symbol: "arrow.down.left", label: "Home, keep walk open", action: back)
                                Spacer()
                                HStack(spacing: 7) { Circle().fill(session.isPaused ? HW.coral : HW.green).frame(width: 6, height: 6); Kicker(text: session.isPaused ? "Taking a pause" : "In your own flow") }
                                Spacer()
                                RoundButton(symbol: session.isPaused ? "play.fill" : "pause.fill", label: session.isPaused ? "Resume walk" : "Pause walk") { store.togglePause() }
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 5) {
                                Text(timeString(elapsed)).font(.system(size: 62, weight: .medium, design: .rounded)).monospacedDigit().tracking(-2)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 5) { Kicker(text: "Time outside"); Text("of \(session.plan.minutes) min").font(.system(size: 14)).foregroundStyle(HW.muted) }
                            }.accessibilityElement(children: .combine).accessibilityLabel("Time outside: \(Int(elapsed) / 60) minutes, \(Int(elapsed) % 60) seconds")
                            ZStack(alignment: .bottomLeading) {
                                RoadLandscape(mood: session.plan.mood, progress: progress, variation: session.plan.variation ?? 0)
                                InfoPill(text: session.plan.mood.title + " way", symbol: session.plan.mood.symbol).padding(17)
                            }.frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 28))
                            HStack(spacing: 6) { ForEach(0..<session.plan.prompts.count, id: \.self) { i in Capsule().fill(i <= index ? session.plan.mood.color : HW.line).frame(height: 4) } }
                            VStack(alignment: .leading, spacing: 14) {
                                HStack { Kicker(text: progress >= 1 ? "Your time is yours" : "Chapter \(index + 1) of \(session.plan.prompts.count)"); Spacer(); Image(systemName: prompt.symbol).font(.system(size: 22)).foregroundStyle(HW.muted) }
                                Text(progress >= 1 ? "A little more you." : prompt.title).font(.system(size: 30, weight: .semibold, design: .rounded)).tracking(-0.7)
                                Text(progress >= 1 ? "Your planned time is complete. Keep wandering if you like, or finish to save this little piece of your day." : prompt.detail).font(.system(size: 15)).lineSpacing(4).foregroundStyle(HW.muted).fixedSize(horizontal: false, vertical: true)
                            }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 24))
                            ActionButton(title: "Leave a Mark", symbol: "plus", yellow: true) {
                                if let id = store.addMoment() { markFeedback += 1; momentTarget = MomentTarget(id: id, sessionID: session.id) }
                            }
                            HStack(spacing: 10) {
                                Button { showPocket = true } label: { Label("A little detour", systemImage: "sparkles").font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 17).background(HW.sky.opacity(0.3), in: RoundedRectangle(cornerRadius: 18)) }
                                Button {
                                    resumeAfterPause = !session.isPaused
                                    if resumeAfterPause { store.togglePause() }
                                    showPause = true
                                } label: { Label("Just a pause", systemImage: "sun.horizon").font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 17).background(HW.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 18)) }
                            }
                            if !session.moments.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Kicker(text: "\(session.moments.count) moments along the way")
                                    ForEach(session.moments) { moment in
                                        Button { momentTarget = MomentTarget(id: moment.id, sessionID: session.id) } label: { MomentRow(moment: moment) }.buttonStyle(.plain)
                                    }
                                }
                            }
                            Button { finishPrompt = true } label: { Text("Finish this walk").font(.system(size: 14, weight: .medium)).frame(maxWidth: .infinity).padding(14) }.accessibilityIdentifier("finishWalk")
                        }.padding(24)
                    }.onChange(of: index) { _, value in if scenePhase == .active { lastChapter = value } }
                }
            } else { ContentUnavailableView("Your walk is saved", systemImage: "checkmark.circle", description: Text("Find it in your Personal Landscape.")) }
        }
        .sensoryFeedback(.success, trigger: markFeedback)
        .sensoryFeedback(.selection, trigger: lastChapter)
        .sheet(item: $momentTarget) { target in MomentEditor(target: target) }
        .sheet(isPresented: $showPocket) { PocketDeckView() }
        .sheet(isPresented: $showPause, onDismiss: {
            if resumeAfterPause, store.active?.isPaused == true { store.togglePause() }
            resumeAfterPause = false
        }) { LittlePauseView() }
        .confirmationDialog("Finish your walk and save a memory?", isPresented: $finishPrompt, titleVisibility: .visible) {
            Button("Finish & Save Memory") { if let id = store.finish() { finished(id) } }
            Button("Keep Wandering", role: .cancel) {}
        }
    }
    private func timeString(_ seconds: Double) -> String { let s = Int(seconds); return String(format: "%02d:%02d", s / 60, s % 60) }
}

struct MomentRow: View {
    @EnvironmentObject private var store: WalkStore
    let moment: WalkMoment
    var body: some View {
        HStack(spacing: 12) {
            if let name = moment.photoName, let photo = UIImage(contentsOfFile: store.photoURL(name).path) {
                Image(uiImage: photo).resizable().scaledToFill().frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 13))
            } else {
                Image(systemName: moment.feeling.symbol).font(.system(size: 18)).frame(width: 44, height: 44).background(HW.yellow.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
            }
            VStack(alignment: .leading, spacing: 4) { Text(moment.note.isEmpty ? "A \(moment.feeling.rawValue.lowercased()) moment" : moment.note).font(.system(size: 13, weight: .medium)).lineLimit(2); Text(moment.date, style: .time).font(.system(size: 10)).foregroundStyle(HW.muted) }
            Spacer(); Image(systemName: "arrow.up.right").font(.system(size: 12)).foregroundStyle(HW.muted)
        }.padding(12).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct MomentEditor: View {
    @EnvironmentObject private var store: WalkStore
    @Environment(\.dismiss) private var dismiss
    let target: MomentTarget
    @State private var note = ""
    @State private var feeling: MomentFeeling = .lovely
    @State private var photoSelection: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isLoading = false
    @State private var removePhoto = false
    @State private var confirmDelete = false
    @State private var photoError: String?
    private var moment: WalkMoment? { store.session(target.sessionID)?.moments.first { $0.id == target.id } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack { Kicker(text: "A little thing worth keeping"); Spacer(); SunSeal(size: 30) }
                    Text("Leave a mark.").font(.system(size: 34, weight: .semibold, design: .rounded)).tracking(-1)
                    Text("The moment is already saved. Add a few words or a photo if you like.").font(.system(size: 14)).foregroundStyle(HW.muted)
                    TextField("What caught your eye?", text: $note, axis: .vertical).lineLimit(4...8).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20)).accessibilityIdentifier("momentNote")
                    HStack(spacing: 8) {
                        ForEach(MomentFeeling.allCases) { value in
                            Button { feeling = value } label: { VStack(spacing: 9) { Image(systemName: value.symbol); Text(value.rawValue).font(.system(size: 9, weight: .medium)) }.frame(maxWidth: .infinity).frame(height: 66).background(feeling == value ? HW.yellow : .white, in: RoundedRectangle(cornerRadius: 17)) }.accessibilityAddTraits(feeling == value ? .isSelected : [])
                        }
                    }
                    if let preview = previewImage {
                        Image(uiImage: preview).resizable().scaledToFill().frame(height: 240).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 22))
                        Button("Remove photo") { photoData = nil; photoSelection = nil; removePhoto = true }.font(.footnote)
                    }
                    PhotosPicker(selection: $photoSelection, matching: .images, photoLibrary: .shared()) {
                        Label(isLoading ? "Loading photo…" : "Choose a photo", systemImage: "photo.badge.plus").font(.system(size: 15, weight: .medium)).frame(maxWidth: .infinity).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20))
                    }.disabled(isLoading)
                    Text("Only the photo you choose is imported. This moment stays on your device.").font(.system(size: 11)).foregroundStyle(HW.muted)
                    ActionButton(title: "Keep This Moment", symbol: "checkmark", action: save).disabled(isLoading).opacity(isLoading ? 0.5 : 1)
                    Button("Delete moment", role: .destructive) { confirmDelete = true }.font(.footnote).frame(maxWidth: .infinity).padding(8)
                }.padding(24)
            }.background(HW.cream).foregroundStyle(HW.ink)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }.onAppear { if let m = moment { note = m.note; feeling = m.feeling } }
            .onChange(of: photoSelection) { _, selection in
                guard let selection else { return }
                isLoading = true
                Task { @MainActor in
                    defer { isLoading = false }
                    do {
                        guard let bytes = try await selection.loadTransferable(type: Data.self), let source = UIImage(data: bytes) else { photoError = "This photo could not be opened."; return }
                        let scale = min(1, 1600 / max(source.size.width, source.size.height))
                        let size = CGSize(width: max(1, source.size.width * scale), height: max(1, source.size.height * scale))
                        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
                        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in UIColor.white.setFill(); ctx.fill(CGRect(origin: .zero, size: size)); source.draw(in: CGRect(origin: .zero, size: size)) }
                        photoData = image.jpegData(compressionQuality: 0.83)
                        removePhoto = false
                    } catch { photoError = "The photo is unavailable. If it is in iCloud, download it to your device and try again." }
                }
            }
            .alert("Photo unavailable", isPresented: Binding(get: { photoError != nil }, set: { if !$0 { photoError = nil } })) { Button("OK") { photoError = nil } } message: { Text(photoError ?? "") }
            .confirmationDialog("Delete this saved moment?", isPresented: $confirmDelete, titleVisibility: .visible) { Button("Delete Moment", role: .destructive) { store.deleteMoment(target.id, sessionID: target.sessionID); dismiss() } }
    }
    private var previewImage: UIImage? {
        if let photoData { return UIImage(data: photoData) }
        if !removePhoto, let name = moment?.photoName { return UIImage(contentsOfFile: store.photoURL(name).path) }
        return nil
    }
    private func save() {
        guard var updated = moment else { return }
        updated.note = String(note.prefix(2000)).trimmingCharacters(in: .whitespacesAndNewlines); updated.feeling = feeling
        do {
            if let photoData { updated.photoName = try store.savePhoto(photoData) }
            else if removePhoto { updated.photoName = nil }
            let oldPhoto = moment?.photoName
            store.updateMoment(updated, sessionID: target.sessionID)
            if store.errorMessage == nil, let oldPhoto, oldPhoto != updated.photoName { try? FileManager.default.removeItem(at: store.photoURL(oldPhoto)) }
            if store.errorMessage == nil { dismiss() }
        } catch { photoError = "The photo could not be saved. Please check your device storage." }
    }
}
