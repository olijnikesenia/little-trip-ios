import Foundation
import Combine

enum WalkMood: String, Codable, CaseIterable, Identifiable {
    case clear, fresh, curious, fast, quiet
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .clear: return "sun.max"
        case .fresh: return "leaf"
        case .curious: return "sparkle.magnifyingglass"
        case .fast: return "wind"
        case .quiet: return "moon"
        }
    }
    var subtitle: String {
        switch self {
        case .clear: return "A little room to breathe."
        case .fresh: return "Follow your greener side."
        case .curious: return "Make space for a small discovery."
        case .fast: return "Find your own kind of momentum."
        case .quiet: return "Let the day get a little softer."
        }
    }
    var intention: String {
        switch self {
        case .clear: return "Unhurried steps. A clearer head."
        case .fresh: return "Look for leaves, light and open sky."
        case .curious: return "Notice the details you usually pass."
        case .fast: return "A steady pace that feels good to you."
        case .quiet: return "Less rush. More room for yourself."
        }
    }
    var prompts: [WalkPrompt] {
        switch self {
        case .clear: return [
            .init(title: "Let the day settle", detail: "Begin on a familiar, comfortable path. Give yourself a few easy breaths.", symbol: "sun.horizon"),
            .init(title: "Look a little further", detail: "Notice the sky, the shape of a roof, or the light at the end of a street.", symbol: "cloud.sun"),
            .init(title: "Keep one small thing", detail: "Find a detail you would like to remember. Leave a mark if you feel like it.", symbol: "bookmark"),
            .init(title: "Bring the calm with you", detail: "Ease your pace. Think of one thing that feels clearer now.", symbol: "sun.max")]
        case .fresh: return [
            .init(title: "Find a hint of green", detail: "Choose a familiar path with trees or plants, if one is available to you.", symbol: "leaf"),
            .init(title: "Notice what's growing", detail: "Look for a new leaf, a patch of moss, or a plant finding its own space.", symbol: "tree"),
            .init(title: "A moment in the open", detail: "Pause somewhere comfortable. Look up and let your eyes follow the branches.", symbol: "cloud.sun"),
            .init(title: "Take the fresh feeling home", detail: "Notice a color you want to carry into the rest of your day.", symbol: "leaf.fill")]
        case .curious: return [
            .init(title: "Start with a question", detail: "What is one detail on this street you have never really looked at?", symbol: "sparkle.magnifyingglass"),
            .init(title: "Follow a small detail", detail: "Look for an unusual door, a pattern in the pavement, or an interesting window.", symbol: "door.left.hand.open"),
            .init(title: "Collect a little surprise", detail: "Save a note or photo of something that made you slow down and look.", symbol: "camera"),
            .init(title: "See the familiar differently", detail: "As you finish, look at an everyday place with the eyes of a first-time visitor.", symbol: "eye")]
        case .fast: return [
            .init(title: "Find an easy rhythm", detail: "Warm up with a pace that feels comfortable. Choose your own path.", symbol: "figure.walk"),
            .init(title: "Let your steps flow", detail: "Keep a steady rhythm that suits you. Slow down whenever you need.", symbol: "wind"),
            .init(title: "Make a little space", detail: "Relax your shoulders and notice how your surroundings change as you move.", symbol: "arrow.up.right"),
            .init(title: "Ease into the finish", detail: "Gradually soften your pace and enjoy the last part of your walk.", symbol: "sun.horizon")]
        case .quiet: return [
            .init(title: "Leave the rush behind", detail: "Choose a comfortable path you know. Let your pace become your own.", symbol: "moon"),
            .init(title: "Find a softer sound", detail: "Notice leaves moving, your footsteps, or another gentle sound around you.", symbol: "waveform"),
            .init(title: "Pause without a plan", detail: "If there is a comfortable place to rest, take a moment just for yourself.", symbol: "bench"),
            .init(title: "Keep a quiet thought", detail: "What felt peaceful today? A few words are enough to remember it.", symbol: "text.bubble")]
        }
    }
}

struct WalkPrompt: Codable, Equatable {
    var title: String
    var detail: String
    var symbol: String
}

struct WalkPlan: Codable, Equatable {
    var mood: WalkMood = .fresh
    var minutes: Int = 30
    var returnToStart = true
    var easyPace = true
    var includePause = false
    // Optional for compatibility with walks saved before variations were added.
    var variation: Int? = Int.random(in: 0...999_999)
    var targetSeconds: TimeInterval { Double(minutes * 60) }
    var prompts: [WalkPrompt] {
        let seed = abs(variation ?? 0)
        let count = minutes <= 20 ? 3 : (minutes <= 45 ? 4 : (minutes <= 90 ? 5 : 6))
        let extras = mood.extraPrompts
        var middle = [mood.prompts[1], mood.prompts[2]] + extras
        let offset = seed % middle.count
        middle = Array(middle[offset...] + middle[..<offset])
        if (seed / middle.count) % 2 == 1 { middle.reverse() }
        var steps = [mood.prompts[0]] + Array(middle.prefix(count - 2)) + [mood.prompts[3]]
        if includePause {
            steps[steps.count / 2] = .init(title: "A pause of your own", detail: "Stop somewhere comfortable for a rest or a coffee, if you find a place you like.", symbol: "cup.and.saucer")
        }
        if returnToStart {
            steps[steps.count - 1].detail += " Choose your own way back to where you began."
        }
        if easyPace { steps[0].detail += " Keep the pace gentle." }
        return steps
    }
    mutating func remix() { variation = ((variation ?? 0) + Int.random(in: 1...5)) % 1_000_000 }
}

extension WalkMood {
    var extraPrompts: [WalkPrompt] {
        switch self {
        case .clear: return [
            .init(title: "Borrow a color from the sky", detail: "Find that same color somewhere at street level. It might be hiding in plain sight.", symbol: "paintpalette"),
            .init(title: "Let one thought drift", detail: "Pick a thought that can wait until later. Give this next stretch to what is around you.", symbol: "cloud"),
            .init(title: "Spot a little symmetry", detail: "Look for two things that belong together: windows, trees, shadows or doorways.", symbol: "square.grid.2x2"),
            .init(title: "Watch the light move", detail: "Notice where sunlight meets shade. Stay for a moment if you like what you see.", symbol: "sun.max"),
            .init(title: "Take the wide view", detail: "Instead of looking for one thing, notice the whole scene: colors, shapes and space.", symbol: "viewfinder")]
        case .fresh: return [
            .init(title: "Find three shades of green", detail: "A leaf is rarely just one color. Look for three different greens around you.", symbol: "paintpalette"),
            .init(title: "A tiny wild thing", detail: "Notice a plant growing somewhere unexpected. No need to leave your path to find one.", symbol: "leaf"),
            .init(title: "Trace a branch with your eyes", detail: "Follow one branch from trunk to tip. Notice how it makes its own little trip.", symbol: "tree"),
            .init(title: "Listen for a natural rhythm", detail: "Leaves, rain or wind: is there something around you keeping its own time?", symbol: "waveform"),
            .init(title: "Find a patch of open sky", detail: "Look between buildings or trees and notice the shape of the sky they frame.", symbol: "cloud.sun")]
        case .curious: return [
            .init(title: "Find an accidental pattern", detail: "Look for repeating bricks, railings or shadows. What breaks the pattern?", symbol: "square.grid.3x3"),
            .init(title: "A door with a story", detail: "Notice an interesting doorway. Imagine a title for the story behind it.", symbol: "door.left.hand.open"),
            .init(title: "Collect a letter", detail: "Find the first letter of your name on a sign, or in the shape of something nearby.", symbol: "textformat.abc"),
            .init(title: "Old beside new", detail: "Look for two details from different times sharing the same street.", symbol: "clock.arrow.circlepath"),
            .init(title: "A very small gallery", detail: "Find a detail that could belong in a gallery: a texture, a sign or a splash of color.", symbol: "photo.artframe")]
        case .fast: return [
            .init(title: "Find a steady soundtrack", detail: "Let the sound of your steps set a rhythm. There is no target to keep up with.", symbol: "waveform"),
            .init(title: "Choose a small landmark", detail: "Pick something ahead on your chosen path. Notice three details before you reach it.", symbol: "flag"),
            .init(title: "Let the scenery change", detail: "Notice a transition: sunlight to shade, a wide street to a narrow one, or a new color.", symbol: "arrow.up.right"),
            .init(title: "Give your eyes a break", detail: "At a comfortable place to pause, look into the distance before moving on.", symbol: "eye"),
            .init(title: "A rhythm of your own", detail: "Does this pace feel right today? Adjust it to suit yourself.", symbol: "figure.walk")]
        case .quiet: return [
            .init(title: "Notice a small movement", detail: "A leaf, a cloud, a curtain: let your eyes follow something moving gently.", symbol: "wind"),
            .init(title: "Find the space between", detail: "Look at the gaps between branches, buildings or shadows.", symbol: "square.dashed"),
            .init(title: "Name the quiet in one word", detail: "If this part of your day had a single word, what would it be?", symbol: "text.bubble"),
            .init(title: "Find a soft edge", detail: "Notice something rounded or worn smooth. Let your attention rest there briefly.", symbol: "circle"),
            .init(title: "A moment without a photo", detail: "Look at something you like and keep it just for yourself.", symbol: "eye")]
        }
    }
}

enum MemoryStyle: String, Codable, CaseIterable, Identifiable {
    case field = "Field note", postcard = "Postcard", dusk = "Blue hour"
    var id: String { rawValue }
}

enum MomentFeeling: String, Codable, CaseIterable, Identifiable {
    case lovely = "Lovely", peaceful = "Peaceful", surprising = "Surprising", alive = "Alive"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .lovely: return "sun.max"; case .peaceful: return "leaf"; case .surprising: return "sparkles"; case .alive: return "wind" }
    }
}

struct WalkMoment: Codable, Identifiable, Equatable {
    var id = UUID()
    var date = Date()
    var note = ""
    var feeling: MomentFeeling = .lovely
    var photoName: String?
}

struct WalkSession: Codable, Identifiable {
    var id = UUID()
    var plan: WalkPlan
    var startedAt: Date
    var accumulated: TimeInterval = 0
    var runningSince: Date?
    var endedAt: Date?
    var moments: [WalkMoment] = []
    var reflection = ""
    var atmosphere = "Just outside"
    var cardStyle: MemoryStyle?
    var isPaused: Bool { runningSince == nil }
    func elapsed(at now: Date = Date()) -> TimeInterval {
        max(0, accumulated + (runningSince.map { max(0, now.timeIntervalSince($0)) } ?? 0))
    }
    func progress(at now: Date = Date()) -> Double { min(1, elapsed(at: now) / plan.targetSeconds) }
    func promptIndex(at now: Date = Date()) -> Int { min(plan.prompts.count - 1, Int(progress(at: now) * Double(plan.prompts.count))) }
    var displayDuration: String {
        let seconds = Int(elapsed())
        return seconds < 60 ? "\(seconds) sec" : "\(seconds / 60) min"
    }
}

struct WalkData: Codable {
    var active: WalkSession?
    var memories: [WalkSession] = []
}

final class WalkStore: ObservableObject {
    @Published private(set) var data = WalkData()
    @Published var errorMessage: String?
    private let directory: URL
    private var lastSaved = WalkData()
    private var loadFailed = false
    private var dataURL: URL { directory.appendingPathComponent("walks.json") }
    var active: WalkSession? { data.active }
    var memories: [WalkSession] { data.memories.sorted { $0.startedAt > $1.startedAt } }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LittleTrip", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: dataURL.path) {
                data = try JSONDecoder().decode(WalkData.self, from: Data(contentsOf: dataURL))
            }
            lastSaved = data
        } catch { loadFailed = true; errorMessage = "Your saved walks could not be opened. Please try reopening Little Trip. Your existing file has been kept." }
    }
    @discardableResult private func save() -> Bool {
        guard !loadFailed else {
            data = lastSaved
            errorMessage = "Your saved walks could not be opened. Your existing file has been kept. Please reopen Little Trip before making changes."
            return false
        }
        do {
            try JSONEncoder().encode(data).write(to: dataURL, options: .atomic)
            lastSaved = data
            errorMessage = nil
            return true
        } catch {
            data = lastSaved
            errorMessage = "Your latest changes could not be saved. Please check your device storage."
            return false
        }
    }
    func start(_ plan: WalkPlan, at date: Date = Date()) {
        guard data.active == nil else { return }
        var validated = plan
        validated.minutes = min(120, max(15, plan.minutes))
        data.active = WalkSession(plan: validated, startedAt: date, runningSince: date)
        save()
    }
    func togglePause(at date: Date = Date()) {
        guard var session = data.active else { return }
        if session.isPaused { session.runningSince = date }
        else { session.accumulated = session.elapsed(at: date); session.runningSince = nil }
        data.active = session
        save()
    }
    @discardableResult func addMoment(at date: Date = Date()) -> UUID? {
        guard data.active != nil else { return nil }
        let moment = WalkMoment(date: date)
        data.active?.moments.append(moment)
        return save() ? moment.id : nil
    }
    func updateMoment(_ moment: WalkMoment, sessionID: UUID) {
        if data.active?.id == sessionID, let index = data.active?.moments.firstIndex(where: { $0.id == moment.id }) {
            data.active?.moments[index] = moment
        } else if let i = data.memories.firstIndex(where: { $0.id == sessionID }), let j = data.memories[i].moments.firstIndex(where: { $0.id == moment.id }) {
            data.memories[i].moments[j] = moment
        }
        save()
    }
    func deleteMoment(_ id: UUID, sessionID: UUID) {
        let photo = session(sessionID)?.moments.first(where: { $0.id == id })?.photoName
        if data.active?.id == sessionID { data.active?.moments.removeAll { $0.id == id } }
        else if let i = data.memories.firstIndex(where: { $0.id == sessionID }) { data.memories[i].moments.removeAll { $0.id == id } }
        if save(), let photo { try? FileManager.default.removeItem(at: photoURL(photo)) }
    }
    @discardableResult func finish(at date: Date = Date()) -> UUID? {
        guard var session = data.active else { return nil }
        session.accumulated = session.elapsed(at: date)
        session.runningSince = nil
        session.endedAt = date
        data.memories.append(session)
        data.active = nil
        return save() ? session.id : nil
    }
    func session(_ id: UUID) -> WalkSession? { data.active?.id == id ? data.active : data.memories.first { $0.id == id } }
    func reflect(id: UUID, text: String, atmosphere: String) {
        guard let i = data.memories.firstIndex(where: { $0.id == id }) else { return }
        data.memories[i].reflection = text
        data.memories[i].atmosphere = atmosphere
        save()
    }
    func styleMemory(id: UUID, style: MemoryStyle) {
        guard let index = data.memories.firstIndex(where: { $0.id == id }) else { return }
        data.memories[index].cardStyle = style
        save()
    }
    func deleteMemory(_ id: UUID) {
        let photos = session(id)?.moments.compactMap(\.photoName) ?? []
        data.memories.removeAll { $0.id == id }
        guard save() else { return }
        for name in photos { try? FileManager.default.removeItem(at: photoURL(name)) }
    }
    func photoURL(_ name: String) -> URL { directory.appendingPathComponent(name) }
    func savePhoto(_ bytes: Data) throws -> String {
        let name = UUID().uuidString + ".jpg"
        try bytes.write(to: photoURL(name), options: .atomic)
        return name
    }
}
