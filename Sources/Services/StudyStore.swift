import SwiftUI
import SwiftData
import UserNotifications
import AppKit

/// A separate publisher prevents a one-second tick from invalidating every section.
/// The store still publishes calendar-boundary changes for daily summaries and themes.
@MainActor final class StudyClock: ObservableObject {
    @Published private(set) var now: Date
    private var day: Date
    private var zone: TimeZone
    init(now: Date = Date(), calendar: Calendar = .current) {
        self.now = now; day = calendar.startOfDay(for: now); zone = calendar.timeZone
    }
    func crossesCalendarBoundary(_ date: Date, calendar: Calendar = .current) -> Bool {
        day != calendar.startOfDay(for: date) || zone != calendar.timeZone
    }
    func update(_ date: Date, calendar: Calendar = .current) {
        day = calendar.startOfDay(for: date); zone = calendar.timeZone
        if now != date { now = date }
    }
}

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
            L10n.language = settings.appLanguage
            if oldValue.appLanguage != settings.appLanguage {
                defaults.set([settings.appLanguage.rawValue], forKey: "AppleLanguages")
                NativeAppLanguageMenus.refresh()
            }
            persistSettings()
            scheduleNotification()
        }
    }
    @Published var active: ActiveTimer?
    let clock = StudyClock()
    var now: Date {
        get { clock.now }
        set {
            let boundary = clock.crossesCalendarBoundary(newValue)
            if boundary { objectWillChange.send() }
            clock.update(newValue)
            if boundary { rebuildSubjectSummaries() }
        }
    }
    struct SubjectSummary { var count = 0; var total = 0.0; var week = 0.0; var month = 0.0 }
    private(set) var subjectSummaries: [UUID: SubjectSummary] = [:]
    private func rebuildSubjectSummaries() {
        let weekInterval = week
        let month = Calendar.current.dateInterval(of: .month, for: now) ?? weekInterval
        var result: [UUID: SubjectSummary] = [:]
        for session in sessions {
            guard let id = session.subjectID else { continue }
            var value = result[id] ?? SubjectSummary()
            value.count += 1; value.total += session.duration
            let timing = savedTiming(for: session)
            value.week += timing.contribution(in: weekInterval); value.month += timing.contribution(in: month)
            result[id] = value
        }
        subjectSummaries = result
    }
    @Published var sessions: [StudySession] = [] { didSet { rebuildSubjectSummaries() } }
    @Published var exams: [StudyExam] = []
    @Published var subjects: [Subject] = [] { didSet { rebuildSubjectCatalog() } }
    @Published private(set) var activeSubjects: [Subject] = []
    @Published private(set) var completedSubjects: [Subject] = []
    private(set) var completedSubjectIDs: Set<UUID> = []
    private var subjectSignature: [String] = []
    private(set) var subjectCatalogRevision = 0
    private func rebuildSubjectCatalog() {
        let signature = subjects.map { "\($0.id)|\($0.name)|\($0.icon)|\($0.color)|\($0.isCompleted)|\($0.completedAt?.timeIntervalSince1970 ?? 0)|\($0.weeklyGoal)" }
        guard signature != subjectSignature else { return }
        subjectSignature = signature; subjectCatalogRevision += 1
        activeSubjects = subjects.filter { !$0.isCompleted }
        completedSubjects = subjects.filter(\.isCompleted).sorted {
            if $0.completedAt != $1.completedAt { return ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            return $0.id.uuidString < $1.id.uuidString
        }
        completedSubjectIDs = Set(completedSubjects.map(\.id))
        if let id = nextSubject, !activeSubjects.contains(where: { $0.id == id }) { nextSubject = nil }
        if let id = settings.lastSubject, !activeSubjects.contains(where: { $0.id == id }) { settings.lastSubject = activeSubjects.first?.id }
    }
    private static let unassignedSubjectID = UUID()
    var weeklyGoalProgress: Double {
        let saved = sessions.reduce(0.0) { sum, session in
            sum + (completedSubjectIDs.contains(session.subjectID ?? Self.unassignedSubjectID) ? 0 : contribution(session, in: week))
        }
        return saved + (completedSubjectIDs.contains(active?.subjectID ?? Self.unassignedSubjectID) ? 0 : activeContribution(in: week))
    }
    @Published var menuCompletion = false
    @Published var completionPulse: UUID?
    @Published var completed: StudySession?
    @Published var error: String?
    @Published var focus = false
    @Published var openTimer = false
    @Published var cycles = 0
    private var ticker: Timer?
    private let activityCache = StudyActivityCache()
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
        guard let a = active else { return nextSubject == nil ? L10n.tr("Nessuna sessione attiva") : L10n.tr("Sessione configurata") }
        if a.isBreak { return a.pausedAt == nil ? L10n.tr("Intervallo in corso") : L10n.tr("Intervallo in attesa") }
        return a.pausedAt == nil ? L10n.tr("Studio in corso") : L10n.tr("Sessione sospesa")
    }
    var actionTitle: String {
        guard let a = active else { return L10n.tr("Inizia a studiare") }
        return a.pausedAt == nil ? L10n.tr("Sospendi") : a.isBreak ? L10n.tr("Avvia pausa") : L10n.tr("Riprendi")
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
        active?.pause(at: date); now = date; statusMessage = L10n.tr("Timer sospeso durante lo stop.")
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
        if !inMemory, ColorIDMigrationBackup.needsCompletionBackup(configuration.url) {
            try ColorIDMigrationBackup.create(archiveURL: configuration.url, preferences: defaults.dictionaryRepresentation(), label: "SubjectCompletion")
        }
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        var loadedSettings = defaults.data(forKey: "settings").flatMap { try? JSONDecoder().decode(UserSettings.self, from: $0) } ?? UserSettings()
        loadedSettings.sanitize()
        settings = loadedSettings
        L10n.language = loadedSettings.appLanguage
        active = defaults.data(forKey: "active").flatMap { try? JSONDecoder().decode(ActiveTimer.self, from: $0) }
        cycles = defaults.integer(forKey: "cycles")
        nextSubject = defaults.string(forKey: "nextSubject").flatMap(UUID.init(uuidString:))
        nextMode = defaults.string(forKey: "nextMode").flatMap(TimerMode.init(rawValue:))
        let completionSubjects = try context.fetch(FetchDescriptor<Subject>())
        if SubjectCompletionMigration.apply(subjects: completionSubjects, sessions: try context.fetch(FetchDescriptor<StudySession>())) > 0 {
            do { try context.save() } catch { context.rollback(); throw error }
        }
        try migrateSubjectColorIDs(archiveURL: inMemory ? nil : configuration.url)
        refresh()
        if subjects.isEmpty && !defaults.bool(forKey: "seeded") {
            context.insert(Subject(name: "Studio", icon: "book.closed")); save(); defaults.set(true, forKey: "seeded")
        }
        if systemIntegration { ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in Task { @MainActor in self?.tick() } }
        if let ticker {
            // Let macOS coalesce wake-ups; elapsed time still comes from dates, not ticks.
            ticker.tolerance = 0.1
            RunLoop.main.add(ticker, forMode: .common)
        } }
        if systemIntegration {
            sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                let sleepDate = Date()
                Task { @MainActor in self?.pauseForSleep(at: sleepDate) }
            }
            if active?.pausedAt == nil, active != nil {
                let checkpoint = defaults.object(forKey: "lastCheckpoint") as? Date
                active?.pause(at: max(active!.start, checkpoint ?? active!.start))
                statusMessage = L10n.tr("Sessione recuperata e sospesa. Controlla il tempo prima di riprendere.")
                persistActive()
            }
        }
        tick(); scheduleNotification()
    }
    deinit {
        ticker?.invalidate()
        if let sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver) }
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
        } catch { self.error = L10n.errorMessage(error) }
    }
    @discardableResult func save() -> Bool {
        do { try context.save(); refresh(); return true } catch { self.error = L10n.errorMessage(error); return false }
    }
    var preparedSubject: Subject? {
        activeSubjects.first { $0.id == (nextSubject ?? settings.lastSubject) } ?? activeSubjects.first
    }
    var preparedMode: TimerMode { nextMode ?? settings.preferredMode }
    var preparedTarget: Double? {
        preparedMode == .stopwatch ? nil : min(86400, max(60, (preparedMode == .pomodoro ? settings.pomodoroDuration : settings.customMinutes) * 60))
    }
    var preparedSummary: String {
        preparedMode.displayName + (preparedTarget.map { " · " + durationText($0) } ?? L10n.tr(" · senza limite"))
    }
    func chooseSubject(_ id: UUID?) { settings.lastSubject = id; nextSubject = nil }
    func chooseMode(_ mode: TimerMode) { settings.preferredMode = mode; nextMode = nil }
    func start() {
        guard active == nil else { return }
        let subject = preparedSubject
        guard let subject else { error = L10n.tr("Aggiungi una materia prima di iniziare."); return }
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
        if systemIntegration, let dock = NSApp?.dockTile {
            let label = active.map { $0.isBreak ? L10n.tr("Pausa") : clockText($0.displayed(at: now)) }
            // Setting even an unchanged badge can ask the Dock to redraw its tile.
            if dock.badgeLabel != label { dock.badgeLabel = label }
        }
    }
    func finish(natural: Bool = false, at suppliedEnd: Date? = nil, fromMenu: Bool = false) {
        guard let a = active else { return }
        menuCompletion = fromMenu
        let finishTime = suppliedEnd ?? Date()
        guard finishTime >= a.start, finishTime <= Date() else { error = L10n.tr("La fine deve essere compresa tra inizio e adesso."); return }
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
        content.title = a.isBreak ? L10n.tr("Sessione configurata") : L10n.tr("Sessione completata")
        content.body = a.isBreak ? L10n.tr("Pausa completata.") : L10n.tr("Sessione completata.")
        if settings.sounds { content.sound = .default }
        center.add(UNNotificationRequest(identifier: "timer", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, a.displayed(at: Date())), repeats: false)))
    }
    func requestNotifications() {
        Task {
            do {
                settings.notifications = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                if !settings.notifications { error = L10n.tr("Notifiche non autorizzate. Puoi abilitarle nelle Impostazioni di Sistema.") }
                scheduleNotification()
            } catch { self.error = L10n.errorMessage(error) }
        }
    }
    func total(in interval: DateInterval, subject: UUID? = nil) -> Double {
        // Avoid a temporary filtered array for every chart bucket / live summary.
        var result = 0.0
        for session in sessions where subject == nil || session.subjectID == subject {
            result += contribution(session, in: interval)
        }
        return result
    }
    /// Read SwiftData once for a batch, then do interval arithmetic on plain values.
    /// The result preserves session order, allocation rules and subject filtering.
    func totals(in intervals: [DateInterval], subject: UUID? = nil) -> [Double] {
        guard !intervals.isEmpty else { return [] }
        var result = Array(repeating: 0.0, count: intervals.count)
        for session in sessions where subject == nil || session.subjectID == subject {
            let timing = savedTiming(for: session)
            for index in intervals.indices { result[index] += timing.contribution(in: intervals[index]) }
        }
        return result
    }
    func savedTiming(for session: StudySession) -> SavedStudyTiming {
        if let data = session.activityData, let intervals = activityCache.intervals(id: session.id, data: data) {
            return .recorded(intervals)
        }
        return .proportional(start: session.startDate, end: session.endDate, duration: session.duration)
    }
    func contribution(_ session: StudySession, in interval: DateInterval) -> Double {
        savedTiming(for: session).contribution(in: interval)
    }
    var day: DateInterval { Calendar.current.dateInterval(of: .day, for: now) ?? DateInterval(start: now, end: now) }
    var week: DateInterval { Calendar.current.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, end: now) }
    var today: Double { total(in: day) }
    var weekly: Double { total(in: week) }
    var streak: Int {
        let c = Calendar.current
        let threshold = (settings.streakUsesGoal ? settings.dailyGoal * 60 : settings.streakMinutes) * 60
        let timings = sessions.map { savedTiming(for: $0) }
        func savedTotal(in interval: DateInterval) -> Double {
            timings.reduce(0) { $0 + $1.contribution(in: interval) }
        }
        var date = now; var count = 0
        let todayInterval = c.dateInterval(of: .day, for: date) ?? DateInterval(start: date, end: date)
        if savedTotal(in: todayInterval) < threshold { date = c.date(byAdding: .day, value: -1, to: date) ?? date }
        for _ in 0..<36500 {
            guard let interval = c.dateInterval(of: .day, for: date), savedTotal(in: interval) >= max(1, threshold) else { break }
            count += 1
            guard let prev = c.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }
}


/// Cache only the decoded payload, never a computed total or a managed SwiftData model.
/// Matching the exact Data prevents stale results after edits/imports with the same ID.
/// NSCache bounds retained memory and may discard entries without affecting correctness.
@MainActor final class StudyActivityCache {
    private final class Entry {
        let source: Data
        let intervals: [StudyInterval]?
        init(source: Data, intervals: [StudyInterval]?) { self.source = source; self.intervals = intervals }
    }
    private let entries = NSCache<NSUUID, Entry>()
    private let decoder = JSONDecoder()
    private(set) var decodeCount = 0
    init() {
        entries.countLimit = 4096
        entries.totalCostLimit = 4 * 1024 * 1024
    }
    func intervals(id: UUID, data: Data) -> [StudyInterval]? {
        let key = id as NSUUID
        if let cached = entries.object(forKey: key), cached.source == data { return cached.intervals }
        let intervals = try? decoder.decode([StudyInterval].self, from: data)
        decodeCount += 1
        // Failed decodes are cached too; contribution() retains its legacy fallback.
        let cost = data.count + (intervals?.count ?? 0) * MemoryLayout<StudyInterval>.stride
        entries.setObject(Entry(source: data, intervals: intervals), forKey: key, cost: cost)
        return intervals
    }
}


/// Value snapshot of the existing counting rules. It never owns a managed model.
/// Recorded spans exclude actual pauses. Older/manually edited sessions keep the
/// same proportional allocation, including the historical zero-span fallback.
enum SavedStudyTiming {
    case recorded([StudyInterval])
    case proportional(start: Date, end: Date, duration: Double)
    func contribution(in interval: DateInterval) -> Double {
        switch self {
        case .recorded(let spans):
            return spans.reduce(0) { $0 + max(0, min($1.end, interval.end).timeIntervalSince(max($1.start, interval.start))) }
        case .proportional(let start, let end, let duration):
            let span = end.timeIntervalSince(start)
            guard span > 0 else { return interval.contains(start) ? duration : 0 }
            let overlap = max(0, min(end, interval.end).timeIntervalSince(max(start, interval.start)))
            return duration * min(1, overlap / span)
        }
    }
}
