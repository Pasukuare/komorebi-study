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
        }
    }
    @Published var active: ActiveTimer?
    @Published var now = Date()
    @Published var sessions: [StudySession] = []
    @Published var exams: [StudyExam] = []
    @Published var subjects: [Subject] = []
    @Published var completed: StudySession?
    @Published var error: String?
    @Published var focus = false
    @Published var cycles = 0
    private var ticker: Timer?
    private let defaults: UserDefaults
    private let systemIntegration: Bool
    init(inMemory: Bool = false, defaults: UserDefaults = .standard) throws {
        self.defaults = defaults
        systemIntegration = !inMemory
        let schema = Schema([StudySession.self, Subject.self, StudyExam.self])
        let configuration: ModelConfiguration
        if inMemory { configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) }
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
        refresh()
        if subjects.isEmpty && !defaults.bool(forKey: "seeded") {
            context.insert(Subject(name: "Studio", icon: "book.closed")); save(); defaults.set(true, forKey: "seeded")
        }
        if !inMemory { ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in Task { @MainActor in self?.tick() } }
        if let ticker { RunLoop.main.add(ticker, forMode: .common) } }
        tick()
    }
    func persistSettings() { if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: "settings") } }
    func persistActive() {
        if let active, let data = try? JSONEncoder().encode(active) { defaults.set(data, forKey: "active") }
        else { defaults.removeObject(forKey: "active") }
        defaults.set(cycles, forKey: "cycles")
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
    func start() {
        guard active == nil else { return }
        let subject = subjects.first { $0.id == settings.lastSubject } ?? subjects.first
        guard let subject else { error = "Aggiungi una materia prima di iniziare."; return }
        settings.lastSubject = subject.id
        let mode = settings.preferredMode
        active = ActiveTimer(start: Date(), target: mode == .stopwatch ? nil : min(86400, max(60, (mode == .pomodoro ? settings.pomodoroDuration : settings.customMinutes) * 60)), subjectID: subject.id, subjectName: subject.name, mode: mode)
        now = Date(); persistActive(); scheduleNotification()
    }
    func toggle() {
        guard active != nil else { start(); return }
        if active?.pausedAt == nil { active?.pause(at: Date()) } else { active?.resume(at: Date()) }
        now = Date(); persistActive(); scheduleNotification()
    }
    func tick() {
        now = Date()
        if let active, active.pausedAt == nil, let target = active.target, active.elapsed(at: now) >= target { finish(natural: true) }
        if systemIntegration { NSApp?.dockTile.badgeLabel = active.map { $0.isBreak ? "Pausa" : clockText($0.displayed(at: now)) } }
    }
    func finish(natural: Bool = false) {
        guard let a = active else { return }
        let elapsed = a.elapsed(at: Date())
        let duration = natural ? (a.target ?? elapsed) : min(elapsed, a.target ?? elapsed)
        let end = natural ? a.start.addingTimeInterval(duration + a.pauseDuration) : Date()
        if !a.isBreak && duration > 0 {
            if let existing = sessions.first(where: { $0.id == a.id }) { completed = existing }
            else {
                let pause = a.pauseDuration + (a.pausedAt.map { max(0, end.timeIntervalSince($0)) } ?? 0)
                let session = StudySession(id: a.id, start: a.start, end: end, duration: duration, subjectID: a.subjectID, subjectName: a.subjectName, mode: a.mode.rawValue, pause: pause)
                context.insert(session)
                guard save() else { context.delete(session); active?.pause(at: Date()); persistActive(); return }
                completed = session
            }
        }
        active = nil
        if systemIntegration { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer"]) }
        if natural && !a.isBreak {
            if a.mode == .pomodoro { cycles += 1 }
            let minutes = a.mode == .pomodoro ? (cycles % max(1, settings.longBreakEvery) == 0 ? settings.longBreakDuration : settings.shortBreakDuration) : settings.customBreak
            if minutes > 0 {
                // Start breaks paused: no unobserved automatic study cycles after sleep.
                active = ActiveTimer(start: Date(), pausedAt: Date(), target: min(10800, minutes * 60), subjectID: a.subjectID, subjectName: a.subjectName, mode: a.mode, isBreak: true)
            }
        }
        persistActive(); if systemIntegration { NSApp?.dockTile.badgeLabel = nil }
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
