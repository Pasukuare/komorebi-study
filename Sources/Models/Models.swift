import Foundation
import SwiftData

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
    init(name: String, icon: String = "leaf", color: String = "Salvia", weeklyGoal: Double = 5) {
        id = UUID(); self.name = name; self.icon = icon; self.color = color; self.weeklyGoal = weeklyGoal
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
    init(id: UUID = UUID(), start: Date, end: Date, duration: Double, subjectID: UUID?, subjectName: String, mode: String, pause: Double, note: String = "") {
        self.id = id; startDate = start; endDate = end; self.duration = duration; self.subjectID = subjectID; self.subjectName = subjectName; timerMode = mode; pauseDuration = pause; self.note = note
    }
}
struct UserSettings: Codable {
    var dailyGoal = 3.0
    var weeklyGoal = 15.0
    var pomodoroDuration = 25.0
    var shortBreakDuration = 5.0
    var longBreakDuration = 15.0
    var longBreakEvery = 4
    var customMinutes = 60.0
    var customBreak = 0.0
    var theme = "Morning"
    var appearance = "System"
    var notifications = false
    var sounds = false
    var animations = "Reduced"
    var streakMinutes = 30.0
    var streakUsesGoal = false
    var lastSubject: UUID?
    var preferredMode = TimerMode.pomodoro
    var onboarded = false

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
    func elapsed(at now: Date) -> Double {
        max(0, (pausedAt ?? now).timeIntervalSince(start) - pauseDuration)
    }
    func displayed(at now: Date) -> Double {
        if let target { return max(0, target - elapsed(at: now)) }
        return elapsed(at: now)
    }
    mutating func pause(at now: Date) { if pausedAt == nil { pausedAt = now } }
    mutating func resume(at now: Date) {
        if let pausedAt { pauseDuration += max(0, now.timeIntervalSince(pausedAt)); self.pausedAt = nil }
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
