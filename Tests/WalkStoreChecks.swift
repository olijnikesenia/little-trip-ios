import Foundation

@main struct WalkStoreChecks {
    static func main() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("LittleWalkTests-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        let t0 = Date(timeIntervalSince1970: 1800000000)
        let store = WalkStore(directory: folder)
        precondition(store.active == nil && store.memories.isEmpty, "No fabricated walks on first launch")
        var plan = WalkPlan(); plan.mood = .curious; plan.minutes = 30; plan.includePause = true
        precondition(plan.prompts[2].symbol == "cup.and.saucer", "Rest option changes the plan")
        store.start(plan, at: t0)
        let id = store.active!.id
        store.start(WalkPlan(), at: t0)
        precondition(store.active?.id == id, "Starting again does not overwrite an active walk")
        precondition(store.active!.elapsed(at: t0.addingTimeInterval(60)) == 60)
        store.togglePause(at: t0.addingTimeInterval(60))
        precondition(store.active!.elapsed(at: t0.addingTimeInterval(600)) == 60, "Pause excludes idle time")
        let reopened = WalkStore(directory: folder)
        precondition(reopened.active!.isPaused && reopened.active!.accumulated == 60, "Paused walk restores after relaunch")
        reopened.togglePause(at: t0.addingTimeInterval(600))
        precondition(reopened.active!.elapsed(at: t0.addingTimeInterval(690)) == 150, "Resume continues, excluding pause")
        let runningReload = WalkStore(directory: folder)
        precondition(runningReload.active!.elapsed(at: t0.addingTimeInterval(690)) == 150, "Running timer restores without drift")
        let momentID = runningReload.addMoment(at: t0.addingTimeInterval(650))!
        var moment = runningReload.active!.moments.first!
        moment.note = "A blue door"; moment.feeling = .surprising
        let photoName = try runningReload.savePhoto(Data([1,2,3]))
        moment.photoName = photoName
        runningReload.updateMoment(moment, sessionID: id)
        let finishedID = runningReload.finish(at: t0.addingTimeInterval(720))!
        precondition(finishedID == id && runningReload.active == nil)
        precondition(runningReload.memories.first!.elapsed(at: t0.addingTimeInterval(9999)) == 180, "Finished timer stops")
        precondition(runningReload.finish() == nil && runningReload.memories.count == 1, "Finish is idempotent")
        runningReload.reflect(id: id, text: "Lovely afternoon", atmosphere: "Felt sunny")
        let saved = WalkStore(directory: folder)
        precondition(saved.memories.first!.moments.first!.note == "A blue door")
        precondition(saved.memories.first!.reflection == "Lovely afternoon")
        precondition(saved.memories.first!.plan.mood == .curious)
        saved.deleteMoment(momentID, sessionID: id)
        precondition(!FileManager.default.fileExists(atPath: saved.photoURL(photoName).path), "Deleting moment deletes its imported photo")
        saved.deleteMemory(id)
        precondition(WalkStore(directory: folder).memories.isEmpty, "Deletion persists")
        var invalid = WalkPlan(); invalid.minutes = 0
        saved.start(invalid, at: t0)
        precondition(saved.active!.plan.minutes == 15)
        precondition(saved.active!.promptIndex(at: t0.addingTimeInterval(99999)) == saved.active!.plan.prompts.count - 1, "Last chapter is bounded")
        var shortPlan = WalkPlan(); shortPlan.minutes = 15
        var longPlan = WalkPlan(); longPlan.minutes = 120
        precondition(shortPlan.prompts.count == 3 && longPlan.prompts.count == 6, "Chapter count adapts to time")
        var remixPlan = WalkPlan(); remixPlan.variation = 0
        let before = remixPlan.prompts
        remixPlan.variation = 1
        precondition(before != remixPlan.prompts, "Variations change the plan")
        let legacy = Data("{\"mood\":\"fresh\",\"minutes\":30,\"returnToStart\":true,\"easyPace\":true,\"includePause\":false}".utf8)
        let legacyPlan = try JSONDecoder().decode(WalkPlan.self, from: legacy)
        precondition(legacyPlan.variation == nil && legacyPlan.prompts.count == 4, "Existing plans still decode")
        let persistent = WalkStore(directory: folder)
        let memoryID = persistent.finish(at: t0.addingTimeInterval(120))!
        persistent.styleMemory(id: memoryID, style: .dusk)
        precondition(WalkStore(directory: folder).session(memoryID)?.cardStyle == .dusk, "Memory style persists")
        precondition(saved.active!.elapsed(at: t0.addingTimeInterval(-100)) == 0, "Clock change never produces negative elapsed time")
        let brokenFolder = folder.appendingPathComponent("corrupt")
        try FileManager.default.createDirectory(at: brokenFolder, withIntermediateDirectories: true)
        let damaged = Data("not valid JSON".utf8)
        try damaged.write(to: brokenFolder.appendingPathComponent("walks.json"))
        let protected = WalkStore(directory: brokenFolder)
        protected.start(plan, at: t0)
        precondition(protected.active == nil && protected.errorMessage != nil)
        let preserved = try Data(contentsOf: brokenFolder.appendingPathComponent("walks.json"))
        precondition(preserved == damaged, "Unreadable saved data is not overwritten")
        print("PASS: fresh state, plans, start protection, pause/resume, relaunch, moments, photo storage, finish, reflection, deletion, timer boundaries")
    }
}
