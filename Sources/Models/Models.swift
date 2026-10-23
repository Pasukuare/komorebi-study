import Foundation
import SwiftData

enum ProductText {
    static let name = "Komorebi Study"
    static let wordmark = "komorebi"
    static let welcome = "Benvenuto in Komorebi"
    static let open = "Apri Komorebi"
    static let openAccessible = "Apri Komorebi Study"
    static let quit = "Esci da Komorebi"
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
struct UserSettings: Codable, Equatable {
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
