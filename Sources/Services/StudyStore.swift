import SwiftUI
import SwiftData
import UserNotifications
import AppKit

@MainActor final class StudyStore: ObservableObject {
    let audio = AmbientAudio()
    let container: ModelContainer
    let context: ModelContext
    private var isSanitizing = false
    @Published var settings: UserSettings {
        didSet {
            guard !isSanitizing else { return }
            let sanitized = settings.sanitized()
            if sanitized != settings {
                isSanitizing = true
                settings = sanitized
                isSanitizing = false
            }
            persistSettings()
            scheduleNotification()
        }
    }
    @Published var active: ActiveTimer?
    @Published var now = Date()
    @Published var sessions: [StudySession] = []
    @Published var exams: [StudyExam] = []
    @Published var subjects: [Subject] = []
    @Published var menuCompletion = false
    @Published var completionPulse: UUID?
    @Published var completed: StudySession?
    @Published var error: String?
    @Published var focus = false
    @Published var openTimer = false
    @Published var cycles = 0
    private var ticker: Timer?
    private var sleepObserver: NSObjectProtocol?
    @Published var statusMessage: String?
    @Published var nextSubject: UUID? { didSet { defaults.set(nextSubject?.uuidString, forKey: "nextSubject") } }
    @Published var nextMode: TimerMode? { didSet { defaults.set(nextMode?.rawValue, forKey: "nextMode") } }
    @Published var finishDate = Date()
    @Published var correctingEnd = false
    var pauseOnSleep: Bool {
        get { defaults.object(forKey: "pauseOnSleep") as? Bool ?? true }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "pauseOnSleep") }
    }
    var showMenuTime: Bool {
        get { defaults.object(forKey: "showMenuTime") as? Bool ?? true }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "showMenuTime") }
    }
    var stateText: String {
        guard let a = active else { return nextSubject == nil ? "Pronto per studiare" : "Prossima sessione pronta" }
        if a.isBreak { return a.pausedAt == nil ? "Intervallo in corso" : "Intervallo in attesa" }
        return a.pausedAt == nil ? "Studio in corso" : "Sessione sospesa"
    }
    var actionTitle: String {
        guard let a = active else { return "Inizia a studiare" }
        return a.pausedAt == nil ? "Sospendi" : a.isBreak ? "Avvia pausa" : "Riprendi"
    }
    var studying: Bool { active.map { !$0.isBreak && $0.pausedAt == nil } ?? false }
    var liveToday: Double { today + activeContribution(in: day) }
    var liveWeekly: Double { weekly + activeContribution(in: week) }
    func activeContribution(in interval: DateInterval) -> Double {
        guard let a = active, !a.isBreak else { return 0 }
        if let spans = a.activity(until: now) {
            var remaining = a.target ?? .greatestFiniteMagnitude
            return spans.reduce(0) { total, span in
                let seconds = min(remaining, span.end.timeIntervalSince(span.start))
                remaining -= seconds
                let end = span.start.addingTimeInterval(seconds)
                return total + max(0, min(end, interval.end).timeIntervalSince(max(span.start, interval.start)))
            }
        }
        return interval.contains(a.start) ? min(a.elapsed(at: now), a.target ?? .greatestFiniteMagnitude) : 0
    }
    func prepareNext(_ a: ActiveTimer) { nextSubject = a.subjectID; nextMode = a.mode }
    func skipBreak() {
        guard let a = active, a.isBreak else { return }
        prepareNext(a); active = nil; persistActive(); scheduleNotification()
    }
    func pauseForSleep(at date: Date = Date()) {
        guard pauseOnSleep, active?.pausedAt == nil, active != nil else { return }
        active?.pause(at: date); now = date; statusMessage = "Timer sospeso durante lo stop. Riprendi quando sei pronto."
        persistActive(); scheduleNotification()
    }
    private let defaults: UserDefaults
    private let systemIntegration: Bool
    init(inMemory: Bool = false, defaults: UserDefaults = .standard, archiveURL: URL? = nil) throws {
        self.defaults = defaults
        systemIntegration = !inMemory && archiveURL == nil
        let schema = Schema([StudySession.self, Subject.self, StudyExam.self])
        let configuration: ModelConfiguration
        if inMemory { configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) }
        else if let archiveURL { configuration = ModelConfiguration(schema: schema, url: archiveURL) }
        else {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Komorebi Study", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("Study.store"))
        }
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        var loadedSettings = defaults.data(forKey: "settings").flatMap { try? JSONDecoder().decode(UserSettings.self, from: $0) } ?? UserSettings()
        loadedSettings.sanitize()
        settings = loadedSettings
        active = defaults.data(forKey: "active").flatMap { try? JSONDecoder().decode(ActiveTimer.self, from: $0) }
        cycles = defaults.integer(forKey: "cycles")
        nextSubject = defaults.string(forKey: "nextSubject").flatMap(UUID.init(uuidString:))
        nextMode = defaults.string(forKey: "nextMode").flatMap(TimerMode.init(rawValue:))
        try migrateSubjectColorIDs(archiveURL: inMemory ? nil : configuration.url)
        refresh()
        if subjects.isEmpty && !defaults.bool(forKey: "seeded") {
            context.insert(Subject(name: "Studio", icon: "book.closed")); save(); defaults.set(true, forKey: "seeded")
        }
        if systemIntegration { ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in Task { @MainActor in self?.tick() } }
        if let ticker { RunLoop.main.add(ticker, forMode: .common) } }
        if systemIntegration {
            sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                let sleepDate = Date()
                Task { @MainActor in self?.pauseForSleep(at: sleepDate) }
            }
            if active?.pausedAt == nil, active != nil {
                let checkpoint = defaults.object(forKey: "lastCheckpoint") as? Date
                active?.pause(at: max(active!.start, checkpoint ?? active!.start))
                statusMessage = "Sessione recuperata e sospesa. Controlla il tempo prima di riprendere."
                persistActive()
            }
        }
        tick(); scheduleNotification()
    }
    /// Runs before the UI and timer start. A failed backup/save aborts opening without a partial migration.
    @discardableResult func migrateSubjectColorIDs(archiveURL: URL? = nil) throws -> Int {
        let rewrites = try context.fetch(FetchDescriptor<Subject>()).compactMap { subject -> (Subject, String)? in
            let canonical = SubjectColorID.canonical(subject.color)
            return canonical == subject.color ? nil : (subject, canonical)
        }
        guard !rewrites.isEmpty else { return 0 }
        if let archiveURL {
            let keys = ["settings", "active", "cycles", "nextSubject", "nextMode", "pauseOnSleep", "showMenuTime", "seeded", "lastCheckpoint"]
            var preferences: [String: Any] = [:]
            for key in keys { preferences[key] = defaults.object(forKey: key) }
            try ColorIDMigrationBackup.create(archiveURL: archiveURL, preferences: preferences)
        }
        for (subject, canonical) in rewrites { subject.color = canonical }
        do { try context.save() } catch { context.rollback(); throw error }
        return rewrites.count
    }
    func persistSettings() { if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: "settings") } }
    func persistActive() {
        if let active, let data = try? JSONEncoder().encode(active) { defaults.set(data, forKey: "active") }
        else { defaults.removeObject(forKey: "active") }
        defaults.set(cycles, forKey: "cycles")
        defaults.set(Date(), forKey: "lastCheckpoint")
    }
    func refresh() {
        do {
            sessions = try context.fetch(FetchDescriptor<StudySession>(sortBy: [SortDescriptor(\.startDate, order: .reverse)]))
            exams = try context.fetch(FetchDescriptor<StudyExam>(sortBy: [SortDescriptor(\.date)]))
            subjects = try context.fetch(FetchDescriptor<Subject>(sortBy: [SortDescriptor(\.name)]))
        } catch { self.error = error.localizedDescription }
    }
    @discardableResult func save() -> Bool {
        do { try context.save(); refresh(); return true } catch { self.error = error.localizedDescription; return false }
    }
    var preparedSubject: Subject? {
        subjects.first { $0.id == (nextSubject ?? settings.lastSubject) } ?? subjects.first
    }
    var preparedMode: TimerMode { nextMode ?? settings.preferredMode }
    var preparedTarget: Double? {
        preparedMode == .stopwatch ? nil : min(86400, max(60, (preparedMode == .pomodoro ? settings.pomodoroDuration : settings.customMinutes) * 60))
    }
    var preparedSummary: String {
        preparedMode.rawValue + (preparedTarget.map { " · " + durationText($0) } ?? " · senza limite")
    }
    func chooseSubject(_ id: UUID?) { settings.lastSubject = id; nextSubject = nil }
    func chooseMode(_ mode: TimerMode) { settings.preferredMode = mode; nextMode = nil }
    func start() {
        guard active == nil else { return }
        let subject = preparedSubject
        guard let subject else { error = "Aggiungi una materia prima di iniziare."; return }
        settings.lastSubject = subject.id
        let mode = preparedMode
        let target = preparedTarget
        nextMode = nil; nextSubject = nil; statusMessage = nil
        active = ActiveTimer(start: Date(), target: target, subjectID: subject.id, subjectName: subject.name, mode: mode)
        now = Date(); persistActive(); scheduleNotification()
    }
    func toggle() {
        guard active != nil else { start(); return }
        if active?.pausedAt == nil { active?.pause(at: Date()) } else { active?.resume(at: Date()) }
        now = Date(); persistActive(); scheduleNotification()
    }
    func tick() {
        now = Date()
        if active != nil { defaults.set(now, forKey: "lastCheckpoint") }
        if let active, active.pausedAt == nil, let target = active.target, active.elapsed(at: now) >= target { finish(natural: true) }
        if systemIntegration { NSApp?.dockTile.badgeLabel = active.map { $0.isBreak ? "Pausa" : clockText($0.displayed(at: now)) } }
    }
    func finish(natural: Bool = false, at suppliedEnd: Date? = nil, fromMenu: Bool = false) {
        guard let a = active else { return }
        menuCompletion = fromMenu
        let finishTime = suppliedEnd ?? Date()
        guard finishTime >= a.start, finishTime <= Date() else { error = "La fine deve essere compresa tra inizio e adesso."; return }
        let spans = a.activity(until: finishTime)
        let elapsed = spans?.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) } ?? a.elapsed(at: finishTime)
        let duration = natural ? (a.target ?? elapsed) : min(elapsed, a.target ?? elapsed)
        let end = natural ? a.start.addingTimeInterval(duration + a.pauseDuration) : finishTime
        if !a.isBreak && duration > 0 {
            if let existing = sessions.first(where: { $0.id == a.id }) { completed = existing }
            else {
                let pause = max(0, end.timeIntervalSince(a.start) - duration)
                let session = StudySession(id: a.id, start: a.start, end: end, duration: duration, subjectID: a.subjectID, subjectName: a.subjectName, mode: a.mode.rawValue, pause: pause)
                if let activity = a.activity(until: end) {
                    var remaining = duration
                    let recorded = activity.compactMap { span -> StudyInterval? in
                        let seconds = min(remaining, span.end.timeIntervalSince(span.start))
                        guard seconds > 0 else { return nil }
                        remaining -= seconds
                        return StudyInterval(start: span.start, end: span.start.addingTimeInterval(seconds))
                    }
                    session.activityData = try? JSONEncoder().encode(recorded)
                }
                context.insert(session)
                guard save() else { context.delete(session); active?.pause(at: Date()); persistActive(); return }
                completed = session
            }
        }
        completionPulse = UUID()
        // A local, quiet cue also works when notifications are disabled.
        if natural && settings.sounds && systemIntegration && !settings.notifications {
            let cue = NSSound(named: "Glass"); cue?.volume = 0.25; cue?.play()
        }
        active = nil
        if a.isBreak { prepareNext(a) }
        if systemIntegration { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer"]) }
        if natural && !a.isBreak {
            if a.mode == .pomodoro { cycles += 1 }
            let minutes = a.mode == .pomodoro ? (cycles % max(1, settings.longBreakEvery) == 0 ? settings.longBreakDuration : settings.shortBreakDuration) : settings.customBreak
            if minutes > 0 {
                // Start breaks paused: no unobserved automatic study cycles after sleep.
                active = ActiveTimer(start: Date(), pausedAt: Date(), target: min(10800, minutes * 60), subjectID: a.subjectID, subjectName: a.subjectName, mode: a.mode, isBreak: true)
            }
        }
        persistActive(); scheduleNotification(); if systemIntegration { NSApp?.dockTile.badgeLabel = nil }
    }
    func scheduleNotification() {
        guard systemIntegration else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["timer"])
        guard settings.notifications, let a = active, a.pausedAt == nil, a.target != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = a.isBreak ? "Si ricomincia" : "Sessione completata"
        content.body = a.isBreak ? "La prossima sessione è pronta." : "È ora di fare una pausa."
        if settings.sounds { content.sound = .default }
        center.add(UNNotificationRequest(identifier: "timer", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, a.displayed(at: Date())), repeats: false)))
    }
    func requestNotifications() {
        Task {
            do {
                settings.notifications = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                if !settings.notifications { error = "Notifiche non autorizzate. Puoi abilitarle nelle Impostazioni di Sistema." }
                scheduleNotification()
            } catch { self.error = error.localizedDescription }
        }
    }
    func total(in interval: DateInterval, subject: UUID? = nil) -> Double {
        sessions.filter { subject == nil || $0.subjectID == subject }.reduce(0) { $0 + contribution($1, in: interval) }
    }
    func contribution(_ s: StudySession, in i: DateInterval) -> Double {
        if let data = s.activityData, let intervals = try? JSONDecoder().decode([StudyInterval].self, from: data) {
            return intervals.reduce(0) { $0 + max(0, min($1.end, i.end).timeIntervalSince(max($1.start, i.start))) }
        }
        // Proportional allocation for sessions crossing midnight, including manually corrected sessions.
        let span = s.endDate.timeIntervalSince(s.startDate)
        guard span > 0 else { return i.contains(s.startDate) ? s.duration : 0 }
        let overlap = max(0, min(s.endDate, i.end).timeIntervalSince(max(s.startDate, i.start)))
        return s.duration * min(1, overlap / span)
    }
    var day: DateInterval { Calendar.current.dateInterval(of: .day, for: now) ?? DateInterval(start: now, end: now) }
    var week: DateInterval { Calendar.current.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, end: now) }
    var today: Double { total(in: day) }
    var weekly: Double { total(in: week) }
    var streak: Int {
        let c = Calendar.current
        let threshold = (settings.streakUsesGoal ? settings.dailyGoal * 60 : settings.streakMinutes) * 60
        var date = now; var count = 0
        let todayInterval = c.dateInterval(of: .day, for: date) ?? DateInterval(start: date, end: date)
        if total(in: todayInterval) < threshold { date = c.date(byAdding: .day, value: -1, to: date) ?? date }
        for _ in 0..<36500 {
            guard let interval = c.dateInterval(of: .day, for: date), total(in: interval) >= max(1, threshold) else { break }
            count += 1
            guard let prev = c.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }
}
