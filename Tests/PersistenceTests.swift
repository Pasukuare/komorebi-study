import XCTest
@testable import KomorebiStudy
@MainActor final class PersistenceTests: XCTestCase {
    func store() throws -> StudyStore {
        let defaults = UserDefaults(suiteName: "KomorebiTests.\(UUID().uuidString)")!
        return try StudyStore(inMemory: true, defaults: defaults)
    }
    func testCompletionSavesOnceAndCapsOverdueTimer() throws {
        let s = try store()
        s.active = ActiveTimer(start: Date().addingTimeInterval(-6000), target: 1500, subjectName: "Test", mode: .pomodoro)
        let id = s.active!.id
        s.finish(natural: true)
        XCTAssertEqual(s.sessions.count, 1)
        XCTAssertEqual(s.sessions.first?.id, id)
        XCTAssertEqual(s.sessions.first?.duration, 1500)
        XCTAssertTrue(s.active?.isBreak == true)
        XCTAssertNotNil(s.active?.pausedAt)
        s.finish()
        XCTAssertEqual(s.sessions.count, 1, "Break time must never count as study")
    }
    func testStoppingPausedSessionExcludesPause() throws {
        let s = try store(); let now = Date()
        s.active = ActiveTimer(start: now.addingTimeInterval(-600), pausedAt: now.addingTimeInterval(-500), target: nil, subjectName: "Test", mode: .stopwatch)
        s.finish()
        XCTAssertEqual(s.sessions.first!.duration, 100, accuracy: 0.01)
        XCTAssertEqual(s.sessions.first!.pauseDuration, 500, accuracy: 0.2)
    }
    func testCrossMidnightAllocationConservesTotal() throws {
        let s = try store(); let midnight = Calendar.current.startOfDay(for: Date())
        let session = StudySession(start: midnight.addingTimeInterval(-1800), end: midnight.addingTimeInterval(1800), duration: 3000, subjectID: nil, subjectName: "Test", mode: "Cronometro", pause: 600)
        s.context.insert(session); XCTAssertTrue(s.save())
        let previous = DateInterval(start: midnight.addingTimeInterval(-86400), end: midnight)
        let next = DateInterval(start: midnight, end: midnight.addingTimeInterval(86400))
        XCTAssertEqual(s.total(in: previous), 1500)
        XCTAssertEqual(s.total(in: next), 1500)
    }
    func testBackupPreservesNotesAndIdentifiers() throws {
        let s = try store()
        let session = StudySession(start: Date(timeIntervalSince1970: 1000), end: Date(timeIntervalSince1970: 2000), duration: 900, subjectID: s.subjects.first!.id, subjectName: "Analisi", mode: "Pomodoro", pause: 100, note: "Integrali, \"capitolo 4\"\nRipassare")
        let backup = Backup(settings: s.settings, subjects: s.subjects.map(SubjectRecord.init), sessions: [SessionRecord(session)])
        let decoded = try JSONDecoder().decode(Backup.self, from: JSONEncoder().encode(backup))
        XCTAssertEqual(decoded.sessions.first?.id, session.id)
        XCTAssertEqual(decoded.sessions.first?.note, session.note)
        XCTAssertEqual(decoded.sessions.first?.subjectID, session.subjectID)
    }
}

extension PersistenceTests {
    func testExamCRUDAndBackup() throws {
        let s = try store()
        let exam = StudyExam(title: "Analisi", date: Date(), hasTime: true, subjectID: s.subjects.first?.id, note: "Aula 4")
        s.context.insert(exam); XCTAssertTrue(s.save())
        XCTAssertEqual(s.exams.count, 1)
        exam.title = "Analisi II"; XCTAssertTrue(s.save())
        XCTAssertEqual(s.exams.first?.title, "Analisi II")
        let backup = Backup(settings: s.settings, subjects: [], sessions: [], exams: s.exams.map(ExamRecord.init))
        let decoded = try JSONDecoder().decode(Backup.self, from: JSONEncoder().encode(backup))
        XCTAssertEqual(decoded.exams?.first?.id, exam.id)
        XCTAssertEqual(decoded.exams?.first?.note, "Aula 4")
        s.context.delete(exam); XCTAssertTrue(s.save()); XCTAssertTrue(s.exams.isEmpty)
    }
    func testOldBackupWithoutExamsStillDecodes() throws {
        let s = try store()
        let backup = Backup(settings: s.settings, subjects: [], sessions: [])
        let decoded = try JSONDecoder().decode(Backup.self, from: JSONEncoder().encode(backup))
        XCTAssertNil(decoded.exams)
    }
    func testUserSettingsSanitization() {
        var settings = UserSettings()
        settings.dailyGoal = -10
        settings.weeklyGoal = Double.nan
        settings.pomodoroDuration = 9999
        settings.customBreak = -5
        settings.sanitize()
        XCTAssertEqual(settings.dailyGoal, 3.0)
        XCTAssertEqual(settings.weeklyGoal, 15.0)
        XCTAssertEqual(settings.pomodoroDuration, 600.0)
        XCTAssertEqual(settings.customBreak, 0.0)
    }
    func testStreakSafeCalculations() throws {
        let s = try store()
        XCTAssertEqual(s.streak, 0)
        XCTAssertNotNil(s.day)
        XCTAssertNotNil(s.week)
    }
}
