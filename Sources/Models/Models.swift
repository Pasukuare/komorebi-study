import Foundation
import Combine
import SwiftData

enum ProductText {
    static let name = "Komorebi Study"
    static let wordmark = "komorebi"
    static var welcome: String { L10n.tr("Benvenuto in Komorebi") }
    static var open: String { L10n.tr("Apri Komorebi") }
    static var openAccessible: String { L10n.tr("Apri Komorebi Study") }
    static var quit: String { L10n.tr("Esci da Komorebi") }
}

/// Only known legacy values are rewritten. Future/unknown IDs are preserved verbatim.
enum SubjectColorID {
    static let defaultID = "classici.salvia"
    static let neutralID = "classici.grigio-caldo"
    static let legacyAliases = [
        "Salvia": "classici.salvia",
        "Cielo": "classici.azzurro-polvere", "Azzurro polvere": "classici.azzurro-polvere",
        "Lavanda": "classici.lavanda",
        "Rosa": "classici.rosa-antico", "Rosa antico": "classici.rosa-antico",
        "Terra": "classici.terracotta", "Terracotta": "classici.terracotta",
        "Tramonto": "classici.ocra", "Ocra": "classici.ocra",
        "Muschio": "classici.verde-muschio", "Verde muschio": "classici.verde-muschio",
        "Neutro": "classici.grigio-caldo", "Grigio caldo": "classici.grigio-caldo"
    ]
    static func canonical(_ value: String) -> String { legacyAliases[value] ?? value }
}

enum TimerMode: String, Codable, CaseIterable, Identifiable {
    case pomodoro = "Pomodoro", stopwatch = "Cronometro", custom = "Personalizzato", unit = "Per unità"
    var id: String { rawValue }
}
@Model final class Subject {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    var weeklyGoal: Double
    // Optional storage supports lightweight migration: existing subjects remain unfinished.
    var completed: Bool? = nil
    var grade: String? = nil // Immutable legacy text retained for lossless migration/backup.
    var gradeValue: Int? = nil
    var gradeHonors: Bool? = nil
    var gradeNote: String? = nil
    var completedAt: Date? = nil
    var completionVersion: Int? = nil
    var isCompleted: Bool {
        get { completed ?? false }
        set { completed = newValue }
    }
    init(name: String, icon: String = "leaf", color: String = SubjectColorID.defaultID, weeklyGoal: Double = 5) {
        id = UUID(); self.name = name; self.icon = icon; self.color = SubjectColorID.canonical(color); self.weeklyGoal = weeklyGoal; self.completionVersion = 1
    }
}
@Model final class StudySession {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date
    var duration: Double
    var subjectID: UUID?
    var subjectName: String
    var timerMode: String
    var pauseDuration: Double
    var note: String
    var unitID: UUID? = nil
    var unitTitle: String? = nil
    var unitFinished: Bool? = nil
    var activityData: Data? = nil
    init(id: UUID = UUID(), start: Date, end: Date, duration: Double, subjectID: UUID?, subjectName: String, mode: String, pause: Double, note: String = "") {
        self.id = id; startDate = start; endDate = end; self.duration = duration; self.subjectID = subjectID; self.subjectName = subjectName; timerMode = mode; pauseDuration = pause; self.note = note
    }
}
extension StudySession {
    func updateTiming(start: Date, end: Date, duration: Double, pause: Double) {
        // Editing metadata must preserve the measured activity intervals.
        if startDate != start || endDate != end || abs(self.duration - duration) > 0.001 || abs(pauseDuration - pause) > 0.001 {
            activityData = nil
        }
        startDate = start; endDate = end; self.duration = duration; pauseDuration = pause
    }
}
/// Stable locations, independent of theme and interface language. User text is never translated.
enum PersonalPhraseSlot: String, CaseIterable, Identifiable {
    case home, timer, dailyGoal, menu
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return L10n.tr("Home")
        case .timer: return L10n.tr("Timer")
        case .dailyGoal: return L10n.tr("Obiettivo di oggi")
        case .menu: return L10n.tr("Barra dei menu")
        }
    }
}
enum HistorySubjectSelection: Hashable {
    case all, subject(UUID), legacyName(String)
    func matches(_ session: StudySession) -> Bool {
        switch self {
        case .all: return true
        case .subject(let id): return session.subjectID == id
        case .legacyName(let name): return session.subjectName == name
        }
    }
}
struct UserSettings: Codable, Equatable {
    var unitBreakFraction: Double?
    var unitBreakMinimum: Double?
    var unitBreakMaximum: Double?
    var completedSubjectsExpanded: Bool?
    var personalPhrases: [String: String]?
    func personalPhrase(for slot: PersonalPhraseSlot) -> String? {
        let text = personalPhrases?[slot.rawValue]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }
    var dailyGoal = 3.0
    var weeklyGoal = 15.0
    var pomodoroDuration = 25.0
    var shortBreakDuration = 5.0
    var longBreakDuration = 15.0
    var longBreakEvery = 4
    var customMinutes = 60.0
    var customBreak = 0.0
    // Keep the legacy JSON key: this preference is the landscape, not the theme package.
    var theme = "Morning"
    var dismissedThemeCampaigns: [String]?
    var themeID: String?
    var themeOptions: [String: [String: Bool]]?
    var landscape: String {
        get { theme }
        set { theme = newValue }
    }
    var appearance = "System"
    var notifications = false
    var sounds = false
    var animations = "Reduced"
    var streakMinutes = 30.0
    var streakUsesGoal = false
    var lastSubject: UUID?
    var preferredMode = TimerMode.pomodoro
    var onboarded = false
    var language: String?
    var appLanguage: AppLanguage { AppLanguage(rawValue: language ?? "it") ?? .italian }
    var sidebarIsVisible: Bool?
    var showsSidebar: Bool { sidebarIsVisible ?? true }

    mutating func sanitize() {
        if let x = unitBreakFraction { unitBreakFraction = x.isFinite && x > 0 ? min(1, max(0.01, x)) : 0.2 }
        if let x = unitBreakMinimum { unitBreakMinimum = x.isFinite ? min(180, max(1, x)) : 5 }
        if let x = unitBreakMaximum { unitBreakMaximum = x.isFinite ? min(180, max(unitBreakMinimum ?? 5, x)) : 20 }
        dailyGoal = dailyGoal.isFinite && dailyGoal > 0 ? min(24, max(0.25, dailyGoal)) : 3.0
        weeklyGoal = weeklyGoal.isFinite && weeklyGoal > 0 ? min(168, max(0.25, weeklyGoal)) : 15.0
        pomodoroDuration = pomodoroDuration.isFinite && pomodoroDuration > 0 ? min(600, max(1, pomodoroDuration)) : 25.0
        shortBreakDuration = shortBreakDuration.isFinite && shortBreakDuration > 0 ? min(120, max(1, shortBreakDuration)) : 5.0
        longBreakDuration = longBreakDuration.isFinite && longBreakDuration > 0 ? min(180, max(1, longBreakDuration)) : 15.0
        longBreakEvery = min(12, max(1, longBreakEvery))
        customMinutes = customMinutes.isFinite && customMinutes > 0 ? min(1440, max(1, customMinutes)) : 60.0
        customBreak = customBreak.isFinite && customBreak >= 0 ? min(360, max(0, customBreak)) : 0.0
        streakMinutes = streakMinutes.isFinite && streakMinutes > 0 ? min(1440, max(1, streakMinutes)) : 30.0
    }

    func sanitized() -> UserSettings {
        var copy = self
        copy.sanitize()
        return copy
    }
}
struct StudyInterval: Codable {
    var start: Date
    var end: Date
}
struct ActiveTimer: Codable {
    var id = UUID()
    var start: Date
    var pausedAt: Date?
    var pauseDuration: Double = 0
    var target: Double?
    var subjectID: UUID?
    var subjectName: String
    var mode: TimerMode
    var unitID: UUID? = nil
    var unitTitle: String? = nil
    var unitEstimate: Double? = nil
    var isBreak = false
    var intervals: [StudyInterval]? = []
    var segmentStart: Date?
    func activity(until end: Date) -> [StudyInterval]? {
        guard var result = intervals else { return nil }
        if pausedAt == nil {
            let beginning = segmentStart ?? start
            if end > beginning { result.append(StudyInterval(start: beginning, end: end)) }
        } else if result.isEmpty && segmentStart == nil, let pausedAt, pausedAt > start {
            result.append(StudyInterval(start: start, end: pausedAt))
        }
        return result.compactMap {
            let finish = min($0.end, end)
            return finish > $0.start ? StudyInterval(start: $0.start, end: finish) : nil
        }
    }
    func elapsed(at now: Date) -> Double {
        max(0, min(pausedAt ?? now, now).timeIntervalSince(start) - pauseDuration)
    }
    func displayed(at now: Date) -> Double {
        if let target { return max(0, target - elapsed(at: now)) }
        return elapsed(at: now)
    }
    mutating func pause(at now: Date) {
        guard pausedAt == nil else { return }
        if let beginning = segmentStart ?? Optional(start), now > beginning { intervals?.append(StudyInterval(start: beginning, end: now)) }
        pausedAt = now; segmentStart = now
    }
    mutating func resume(at now: Date) {
        if let pausedAt { pauseDuration += max(0, now.timeIntervalSince(pausedAt)); self.pausedAt = nil; segmentStart = now }
    }
}
func durationText(_ seconds: Double) -> String {
    let bounded = seconds.isFinite ? min(3_153_600_000, max(0, seconds)) : 0
    if bounded > 0 && bounded < 60 { return "<1m" }
    let m = Int(bounded) / 60
    return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m"
}
func clockText(_ seconds: Double) -> String {
    let s = Int((seconds.isFinite ? min(3_153_600_000, max(0, seconds)) : 0).rounded(.up))
    return s >= 3600 ? String(format: "%02d:%02d:%02d", s/3600, s/60%60, s%60) : String(format: "%02d:%02d", s/60, s%60)
}

enum ExamKind: String, CaseIterable, Identifiable {
    case unspecified, written, oral, project, writtenAndOral, practical, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .unspecified: return L10n.tr("Non specificato")
        case .written: return L10n.tr("Scritto")
        case .oral: return L10n.tr("Orale")
        case .project: return L10n.tr("Progetto")
        case .writtenAndOral: return L10n.tr("Scritto e orale")
        case .practical: return L10n.tr("Prova pratica")
        case .other: return L10n.tr("Altro")
        }
    }
}
@Model final class StudyExam {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var hasTime: Bool
    var subjectID: UUID?
    var note: String
    var requiredStudyHours: Double? = nil
    var preparationStart: Date? = nil
    var examKind: String? = nil
    var examKindDetail: String? = nil
    init(title: String, date: Date, hasTime: Bool = false, subjectID: UUID? = nil, note: String = "") {
        id = UUID(); self.title = title; self.date = date; self.hasTime = hasTime; self.subjectID = subjectID; self.note = note
    }
}
extension StudyExam {
    /// A subject-name alias follows the linked subject's spelling; custom exam titles stay literal.
    /// This is a display rule only: the original title and historical records are never rewritten.
    func displayTitle(linkedSubjectName: String?) -> String {
        if examKind != nil { return linkedSubjectName ?? title }
        guard let name = linkedSubjectName, title.caseInsensitiveCompare(name) == .orderedSame else { return title }
        return name
    }
}
extension StudyExam {
    var kindDescription: String? {
        guard let raw = examKind else { return nil }
        guard let kind = ExamKind(rawValue: raw) else { return raw }
        if kind == .unspecified { return nil }
        if kind == .other, let detail = examKindDetail, !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return detail }
        return kind.title
    }
}
struct ExamRecord: Codable {
    var id: UUID; var title: String; var date: Date; var hasTime: Bool; var subjectID: UUID?; var note: String
    var requiredStudyHours: Double? = nil; var preparationStart: Date? = nil
    var examKind: String? = nil; var examKindDetail: String? = nil
    init(_ exam: StudyExam) { requiredStudyHours = exam.requiredStudyHours; preparationStart = exam.preparationStart; examKind = exam.examKind; examKindDetail = exam.examKindDetail; id = exam.id; title = exam.title; date = exam.date; hasTime = exam.hasTime; subjectID = exam.subjectID; note = exam.note }
    var model: StudyExam {
        let exam = StudyExam(title: title, date: date, hasTime: hasTime, subjectID: subjectID, note: note); exam.id = id; exam.requiredStudyHours = requiredStudyHours; exam.preparationStart = preparationStart; exam.examKind = examKind; exam.examKindDetail = examKindDetail; return exam
    }
}

/// Only the separately packaged review app uses this archive. Production location is unchanged.
enum StudyReviewArchive {
    static func url(bundleIdentifier: String?, applicationSupport: URL) -> URL? {
        guard bundleIdentifier?.hasPrefix("com.komorebi.study.review") == true else { return nil }
        return applicationSupport.appendingPathComponent("Komorebi Study Review", isDirectory: true).appendingPathComponent("Study.store")
    }
}


/// App-owned language preference; storage IDs and user-authored content are never translated.
enum AppLanguage: String, CaseIterable, Identifiable {
    case italian = "it", english = "en"
    var id: String { rawValue }
    var name: String { self == .italian ? "Italiano" : "English" }
    var locale: Locale { Locale(identifier: self == .italian ? "it_IT" : "en_GB") }
}
/// Publishes only explicit language changes, never timer ticks or cursor positions.
final class AppLocalization: ObservableObject {
    static let shared = AppLocalization()
    @Published fileprivate(set) var language: AppLanguage = .italian
}
enum L10n {
    static var language: AppLanguage {
        get { AppLocalization.shared.language }
        set { if AppLocalization.shared.language != newValue { AppLocalization.shared.language = newValue } }
    }
    static var locale: Locale { language.locale }
    private static let english: [String: String] = {
        let main = Bundle.main.url(forResource: "Translations", withExtension: "json")
        #if SWIFT_PACKAGE
        let url = main ?? Bundle.module.url(forResource: "Translations", withExtension: "json")
        #else
        let url = main
        #endif
        guard let url, let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([String: String].self, from: data) else {
            assertionFailure("Missing app translation catalog")
            return [:]
        }
        return values
    }()
    static var englishKeys: Set<String> { Set(english.keys) }
    static func translation(_ key: String, language: AppLanguage) -> String {
        language == .english ? english[key] ?? key : key
    }
    static func tr(_ key: String, _ arguments: String...) -> String {
        let value = translation(key, language: language)
        guard !arguments.isEmpty else { return value }
        return String(format: value, locale: locale, arguments: arguments)
    }
    static func count(_ count: Int, singular: String, plural: String) -> String {
        tr(count == 1 ? singular : plural, String(count))
    }
    /// Only for app-owned transient messages, never subject names or notes.
    static func message(_ value: String) -> String {
        if language == .english { return english[value] ?? value }
        return english.first(where: { $0.value == value })?.key ?? value
    }
    static func errorMessage(_ error: Error) -> String {
        if let error = error as? ThemeFonts.FontError { return error.errorDescription ?? tr("Operazione non riuscita.") }
        guard language == .english else { return error.localizedDescription }
        let error = error as NSError
        let cocoa: [Int: String] = [NSFileNoSuchFileError: "File non trovato.", NSFileReadNoSuchFileError: "File non trovato.", NSFileReadCorruptFileError: "Il file non è valido o è danneggiato.", NSFileReadNoPermissionError: "Autorizzazione negata per la lettura del file.", NSFileWriteNoPermissionError: "Autorizzazione negata per il salvataggio del file.", NSFileWriteOutOfSpaceError: "Spazio su disco insufficiente."]
        let key = error.domain == NSCocoaErrorDomain ? cocoa[error.code] : nil
        return tr(key ?? "Operazione non riuscita.") + " [\(error.domain): \(error.code)]"
    }
    static func date(_ date: Date, complete: Bool = false) -> String {
        date.formatted(complete ? .dateTime.weekday(.wide).day().month(.wide).year().locale(locale) : .dateTime.day().month(.abbreviated).year().locale(locale))
    }
    static var displayCalendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = locale
        return calendar
    }
}
extension TimerMode {
    var displayName: String { L10n.tr(rawValue) }
    static func displayName(for rawValue: String) -> String { TimerMode(rawValue: rawValue)?.displayName ?? rawValue }
}


/// Shared calendar-day rule for countdown and projection; daylight-saving changes are irrelevant.
enum ExamCalendarDays {
    static func remaining(until exam: Date, from today: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: exam)).day ?? 0
    }
}
struct ProjectionDailyHours: Equatable { let date: Date; let hours: Double }
struct ProjectionPoint: Equatable, Identifiable {
    let date: Date; let hours: Double
    var id: Date { date }
}
enum ProjectionStatus: String { case reached, onTrack, behind, unsustainable, examToday, past }
struct StudyProjection: Equatable {
    let requiredHours: Double; let doneHours: Double; let currentPace: Double
    let finalHours: Double; let necessaryPace: Double?; let shortfall: Double
    let daysRemaining: Int; let status: ProjectionStatus; let preparationStart: Date; let asOf: Date; let examDate: Date
    let studiedDays: Int; let actualPoints: [ProjectionPoint]
    var isScheduled: Bool { preparationStart > asOf }
    var forecastStart: Date { max(preparationStart, asOf) }
}
/// Pure calculation, independent of SwiftData, UI, preferences and the running timer.
enum ProjectionCalculator {
    static func calculate(requiredHours: Double?, preparationStart: Date?, examDate: Date,
                          now: Date, dailyGoal: Double, dailyHours: [ProjectionDailyHours], calendar: Calendar = .current) -> StudyProjection? {
        guard let target = requiredHours, target.isFinite, target > 0, let preparationStart else { return nil }
        let start = calendar.startOfDay(for: preparationStart), today = calendar.startOfDay(for: now)
        let examDay = calendar.startOfDay(for: examDate)
        // A planned start is valid; the exam day itself supplies no preparation days.
        guard start <= max(today, examDay) else { return nil }
        let rawDays = ExamCalendarDays.remaining(until: examDate, from: now, calendar: calendar)
        let days = max(0, rawDays)
        let elapsed = max(0, calendar.dateComponents([.day], from: start, to: today).day ?? 0)
        let divisor = min(7, max(1, elapsed))
        let windowStart = elapsed == 0 ? today : calendar.date(byAdding: .day, value: -divisor, to: today)!
        var buckets: [Date: Double] = [:]
        for entry in dailyHours where entry.hours.isFinite && entry.hours >= 0 {
            let day = calendar.startOfDay(for: entry.date)
            if day >= start && day <= today { buckets[day, default: 0] += entry.hours }
        }
        let done = buckets.values.reduce(0,+)
        let recent = buckets.filter { $0.key >= windowStart && (elapsed == 0 || $0.key < today) }.values.reduce(0,+)
        let pace = recent / Double(divisor)
        let final = done + pace * Double(days)
        let remaining = max(0, target - done)
        let availableDays = max(0, ExamCalendarDays.remaining(until: examDate, from: max(start, today), calendar: calendar))
        let necessary: Double? = availableDays > 0 ? remaining / Double(availableDays) : remaining == 0 ? 0 : nil
        let state: ProjectionStatus
        if rawDays < 0 { state = .past }
        else if done >= target { state = .reached }
        else if days == 0 { state = .examToday }
        else if let necessary, necessary > dailyGoal || necessary > 12 { state = .unsustainable }
        else if final >= target { state = .onTrack }
        else { state = .behind }
        var points = [ProjectionPoint(date: start, hours: 0)], total = 0.0
        // Sparse zero-day plateau points keep the chart exact without enumerating years of empty days.
        for day in buckets.keys.sorted() {
            if let previous = calendar.date(byAdding: .day, value: -1, to: day), previous > points.last!.date {
                points.append(ProjectionPoint(date: previous, hours: total))
            }
            total += buckets[day]!
            if day == points.last!.date { points[points.count-1] = ProjectionPoint(date: day, hours: total) }
            else { points.append(ProjectionPoint(date: day, hours: total)) }
        }
        if points.last!.date < today { points.append(ProjectionPoint(date: today, hours: done)) }
        return StudyProjection(requiredHours: target, doneHours: done, currentPace: pace, finalHours: final,
            necessaryPace: necessary, shortfall: max(0, target-final), daysRemaining: days, status: state,
            preparationStart: start, asOf: today, examDate: calendar.startOfDay(for: examDate),
            studiedDays: buckets.values.filter { $0 > 0 }.count, actualPoints: points)
    }
}


/// Accepts Italian/English decimal separators without inventing a default target.
enum ProjectionTargetInput {
    static func hours(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value.isFinite, value > 0 else { return nil }
        return value
    }
}


/// Unit identities are independent of sessions: deleting a unit never cascades to history.
enum StudyUnitKind: String, CaseIterable, Codable, Identifiable {
    case lesson, chapter, pages, exercises, video, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .lesson: return L10n.tr("Lezione")
        case .chapter: return L10n.tr("Capitolo")
        case .pages: return L10n.tr("Pagine")
        case .exercises: return L10n.tr("Esercizi")
        case .video: return L10n.tr("Video")
        case .other: return L10n.tr("Altro")
        }
    }
}
enum StudyUnitState: String, CaseIterable, Codable, Identifiable {
    case todo, inProgress, finished
    var id: String { rawValue }
    var title: String {
        switch self {
        case .todo: return L10n.tr("Da fare")
        case .inProgress: return L10n.tr("In corso")
        case .finished: return L10n.tr("Finita")
        }
    }
}
@Model final class StudyUnit {
    @Attribute(.unique) var id: UUID
    var subjectID: UUID
    var title: String
    var kind: String
    var order: Int
    var state: String
    var estimatedMinutes: Double?
    var firstPage: Int?
    var lastPage: Int?
    init(subjectID: UUID, title: String, kind: StudyUnitKind = .lesson, order: Int = 0, estimatedMinutes: Double? = nil, firstPage: Int? = nil, lastPage: Int? = nil) {
        id = UUID(); self.subjectID = subjectID; self.title = title; self.kind = kind.rawValue; self.order = order
        state = StudyUnitState.todo.rawValue; self.estimatedMinutes = estimatedMinutes; self.firstPage = firstPage; self.lastPage = lastPage
    }
    var unitKind: StudyUnitKind { StudyUnitKind(rawValue: kind) ?? .other }
    var unitState: StudyUnitState { StudyUnitState(rawValue: state) ?? .todo }
    var pageCount: Int? { guard let firstPage, let lastPage, firstPage > 0, lastPage >= firstPage else { return nil }; return lastPage - firstPage + 1 }
}
struct UnitSeed: Equatable {
    var title: String; var firstPage: Int? = nil; var lastPage: Int? = nil
}
enum UnitRules {
    /// Union makes re-saving a recovered segment idempotent without dropping later resumed work.
    static func mergedIntervals(_ input: [StudyInterval]) -> [StudyInterval] {
        var result: [StudyInterval] = []
        for span in input.filter({ $0.end > $0.start }).sorted(by:{ $0.start < $1.start }) {
            if let previous = result.last, span.start <= previous.end {
                result[result.count-1].end = max(previous.end,span.end)
            } else { result.append(span) }
        }
        return result
    }
    // Bounds prevent accidental multi-million-item allocations in a quick-create form.
    static func numbered(from: Int, through: Int, prefix: String) -> [UnitSeed] {
        guard from >= 0, through >= from, through - from < 10_000 else { return [] }
        return (from...through).map { UnitSeed(title: prefix + String($0)) }
    }
    static func pages(from: Int, through: Int, block: Int, prefix: String) -> [UnitSeed] {
        guard from > 0, through >= from, through < Int.max, block > 0, (through-from)/block < 10_000 else { return [] }
        var result: [UnitSeed] = [], start = from
        while start <= through {
            let end = start + min(block-1, through-start)
            result.append(UnitSeed(title: prefix + "\(start)–\(end)", firstPage: start, lastPage: end))
            start = end + 1
        }
        return result
    }
    static func breakMinutes(studiedMinutes: Double, fraction: Double = 0.2, minimum: Double = 5, maximum: Double = 20) -> Double {
        let lower = minimum.isFinite ? max(1, minimum) : 5
        let upper = maximum.isFinite ? max(lower, maximum) : max(lower,20)
        let ratio = fraction.isFinite && fraction > 0 ? fraction : 0.2
        return min(upper, max(lower, (studiedMinutes.isFinite ? max(0,studiedMinutes) : 0) * ratio))
    }
    struct Sample { let minutes: Double; let pages: Int? }
    static func estimate(samples: [Sample], pageCount: Int? = nil) -> Double? {
        let valid = samples.compactMap { sample -> Double? in
            guard sample.minutes.isFinite, sample.minutes > 0 else { return nil }
            if pageCount != nil { guard let pages = sample.pages, pages > 0 else { return nil }; return sample.minutes/Double(pages) }
            return sample.minutes
        }.sorted()
        guard valid.count >= 3 else { return nil }
        let middle = valid.count/2
        let median = valid.count.isMultiple(of:2) ? (valid[middle-1]+valid[middle])/2 : valid[middle]
        return median * Double(pageCount ?? 1)
    }
}
