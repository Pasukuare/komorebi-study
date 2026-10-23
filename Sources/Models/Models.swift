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
    case pomodoro = "Pomodoro", stopwatch = "Cronometro", custom = "Personalizzato"
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
    var grade: String? = nil
    var isCompleted: Bool {
        get { completed ?? false }
        set { completed = newValue }
    }
    init(name: String, icon: String = "leaf", color: String = SubjectColorID.defaultID, weeklyGoal: Double = 5) {
        id = UUID(); self.name = name; self.icon = icon; self.color = SubjectColorID.canonical(color); self.weeklyGoal = weeklyGoal
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
struct UserSettings: Codable, Equatable {
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

@Model final class StudyExam {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var hasTime: Bool
    var subjectID: UUID?
    var note: String
    init(title: String, date: Date, hasTime: Bool = false, subjectID: UUID? = nil, note: String = "") {
        id = UUID(); self.title = title; self.date = date; self.hasTime = hasTime; self.subjectID = subjectID; self.note = note
    }
}
struct ExamRecord: Codable {
    var id: UUID; var title: String; var date: Date; var hasTime: Bool; var subjectID: UUID?; var note: String
    init(_ exam: StudyExam) { id = exam.id; title = exam.title; date = exam.date; hasTime = exam.hasTime; subjectID = exam.subjectID; note = exam.note }
    var model: StudyExam {
        let exam = StudyExam(title: title, date: date, hasTime: hasTime, subjectID: subjectID, note: note); exam.id = id; return exam
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
