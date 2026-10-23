import XCTest
import SwiftData
@testable import KomorebiStudy

@MainActor final class SessionLifecycleTests: XCTestCase {
    func store() throws -> StudyStore {
        try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "Lifecycle.\(UUID())")!)
    }
    func testSleepPausesWithoutCountingSuspension() throws {
        let s = try store(); let start = Date().addingTimeInterval(-600)
        s.active = ActiveTimer(start: start, target: nil, subjectName: "Test", mode: .stopwatch)
        s.pauseForSleep(at: start.addingTimeInterval(100))
        XCTAssertEqual(s.active!.elapsed(at: start.addingTimeInterval(600)), 100)
        XCTAssertNotNil(s.statusMessage)
        s.finish()
        XCTAssertEqual(s.sessions.first!.duration, 100, accuracy: 0.01)
    }
    func testSleepCanKeepRunningWhenOptedOut() throws {
        let s = try store(); s.pauseOnSleep = false; s.start(); s.pauseForSleep()
        XCTAssertNil(s.active?.pausedAt)
    }
    func testSkipBreakPreservesSubjectAndMode() throws {
        let s = try store(); let id = s.subjects.first!.id
        s.active = ActiveTimer(start: Date(), target: 300, subjectID: id, subjectName: "Test", mode: .custom, isBreak: true)
        s.skipBreak(); XCTAssertNil(s.active); XCTAssertTrue(s.sessions.isEmpty)
        s.settings.preferredMode = .stopwatch
        s.start(); XCTAssertEqual(s.active?.subjectID, id); XCTAssertEqual(s.active?.mode, .custom)
    }
    func testNaturalCompletionCapsActivityData() throws {
        let s = try store()
        s.active = ActiveTimer(start: Date().addingTimeInterval(-6000), target: 1500, subjectName: "Test", mode: .pomodoro)
        s.finish(natural: true)
        let session = s.sessions.first!
        let spans = try JSONDecoder().decode([StudyInterval].self, from: session.activityData!)
        XCTAssertEqual(spans.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }, 1500, accuracy: 0.01)
    }
    func testMidnightPauseDoesNotShiftStudyIntoNextDay() throws {
        let s = try store(); let midnight = Calendar.current.startOfDay(for: Date())
        var a = ActiveTimer(start: midnight.addingTimeInterval(-1800), target: nil, subjectName: "Test", mode: .stopwatch)
        a.pause(at: midnight); s.active = a; s.finish()
        XCTAssertEqual(s.contribution(s.sessions.first!, in: DateInterval(start: midnight, end: midnight.addingTimeInterval(86400))), 0)
        XCTAssertEqual(s.sessions.first!.duration, 1800, accuracy: 0.01)
    }
    func testCorrectionTrimsClosedSegments() throws {
        let s = try store(); let start = Date().addingTimeInterval(-1000)
        var a = ActiveTimer(start: start, target: nil, subjectName: "Test", mode: .stopwatch)
        a.pause(at: start.addingTimeInterval(300)); a.resume(at: start.addingTimeInterval(600))
        s.active = a; s.finish(at: start.addingTimeInterval(200))
        XCTAssertEqual(s.sessions.first!.duration, 200, accuracy: 0.01)
        XCTAssertEqual(s.sessions.first!.pauseDuration, 0, accuracy: 0.01)
    }
    func testLegacyActiveTimerDecodesWithoutIntervals() throws {
        let data = Data(#"{"id":"00000000-0000-0000-0000-000000000001","start":1000,"pauseDuration":0,"subjectName":"Test","mode":"Pomodoro","isBreak":false}"#.utf8)
        let a = try JSONDecoder().decode(ActiveTimer.self, from: data)
        XCTAssertNil(a.intervals)
        XCTAssertNil(a.activity(until: Date()))
    }
    func testIntervalsSurviveBackup() throws {
        let s = try store(); s.start(); s.finish()
        let record = SessionRecord(s.sessions.first!)
        let recovered = try JSONDecoder().decode(SessionRecord.self, from: JSONEncoder().encode(record))
        XCTAssertEqual(record.activityData, recovered.model.activityData)
    }
}

extension SessionLifecycleTests {
    func testExistingArchiveMigrationWhenFixtureProvided() throws {
        guard let path = ProcessInfo.processInfo.environment["KOMOREBI_MIGRATION_FIXTURE"] else { throw XCTSkip("Optional real archive fixture") }
        let url = URL(fileURLWithPath: path)
        let schema = Schema([StudySession.self, Subject.self, StudyExam.self])
        let original = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let originalContext = ModelContext(original)
        let originalSubjects = try originalContext.fetch(FetchDescriptor<Subject>())
        let expectedIDs = Dictionary(uniqueKeysWithValues: originalSubjects.map { ($0.id, SubjectColorID.canonical($0.color)) })
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let subjectMetadata = try encoder.encode(originalSubjects.sorted { $0.id.uuidString < $1.id.uuidString }.map(SubjectRecord.init))
        let sessionMetadata = try encoder.encode(originalContext.fetch(FetchDescriptor<StudySession>()).sorted { $0.id.uuidString < $1.id.uuidString }.map(SessionRecord.init))
        let exams = try encoder.encode(originalContext.fetch(FetchDescriptor<StudyExam>()).sorted { $0.id.uuidString < $1.id.uuidString }.map(ExamRecord.init))
        let s = try StudyStore(defaults: UserDefaults(suiteName: "Migration.\(UUID())")!, archiveURL: url)
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: s.subjects.map { ($0.id, $0.color) }), expectedIDs)
        XCTAssertEqual(try encoder.encode(s.subjects.sorted { $0.id.uuidString < $1.id.uuidString }.map(SubjectRecord.init)), subjectMetadata)
        XCTAssertEqual(try encoder.encode(s.sessions.sorted { $0.id.uuidString < $1.id.uuidString }.map(SessionRecord.init)), sessionMetadata)
        XCTAssertEqual(try encoder.encode(s.exams.sorted { $0.id.uuidString < $1.id.uuidString }.map(ExamRecord.init)), exams)
        let firstPass = try encoder.encode(s.subjects.sorted { $0.id.uuidString < $1.id.uuidString }.map(SubjectRecord.init))
        XCTAssertEqual(try s.migrateSubjectColorIDs(archiveURL: url), 0)
        XCTAssertEqual(try encoder.encode(s.subjects.sorted { $0.id.uuidString < $1.id.uuidString }.map(SubjectRecord.init)), firstPass)
        XCTAssertNil(s.error)
        XCTAssertFalse(s.sessions.isEmpty)
        let ids = s.sessions.map(\.id); let total = s.sessions.reduce(0) { $0 + $1.duration }
        s.active = ActiveTimer(start: Date().addingTimeInterval(-60), target: nil, subjectName: "Migration test", mode: .stopwatch)
        s.finish()
        XCTAssertEqual(s.sessions.count, ids.count + 1)
        XCTAssertTrue(Set(ids).isSubset(of: Set(s.sessions.map(\.id))))
        XCTAssertGreaterThan(s.sessions.reduce(0) { $0 + $1.duration }, total)
    }
}

extension SessionLifecycleTests {
    func testLiveProgressCapsChronologicalActivityBeforeMidnight() throws {
        let s = try store()
        let midnight = Calendar.current.startOfDay(for: Date())
        s.active = ActiveTimer(start: midnight.addingTimeInterval(-120), target: 60, subjectName: "Test", mode: .pomodoro)
        s.now = midnight.addingTimeInterval(120)
        XCTAssertEqual(s.activeContribution(in: DateInterval(start: midnight.addingTimeInterval(-86400), end: midnight)), 60)
        XCTAssertEqual(s.activeContribution(in: DateInterval(start: midnight, end: midnight.addingTimeInterval(86400))), 0)
    }
    func testMetadataEditPreservesActivityButTimingEditInvalidatesIt() throws {
        let s = try store()
        s.active = ActiveTimer(start: Date().addingTimeInterval(-120), target: nil, subjectName: "Test", mode: .stopwatch)
        s.finish()
        let session = try XCTUnwrap(s.sessions.first)
        let original = try XCTUnwrap(session.activityData)
        session.updateTiming(start: session.startDate, end: session.endDate, duration: session.duration / 60 * 60, pause: session.pauseDuration)
        session.note = "Nota aggiornata"
        XCTAssertEqual(session.activityData, original)
        session.updateTiming(start: session.startDate, end: session.endDate, duration: 60, pause: session.pauseDuration)
        XCTAssertNil(session.activityData)
    }
    func testNextSessionSurvivesRelaunchAndClearsWhenStarted() throws {
        let defaults = UserDefaults(suiteName: "NextSession.\(UUID())")!
        let first = try StudyStore(inMemory: true, defaults: defaults)
        let subject = try XCTUnwrap(first.subjects.first)
        first.active = ActiveTimer(start: Date(), target: 60, subjectID: subject.id, subjectName: subject.name, mode: .custom, isBreak: true)
        first.skipBreak()
        let recovered = try StudyStore(inMemory: true, defaults: defaults)
        XCTAssertEqual(recovered.nextSubject, subject.id)
        XCTAssertEqual(recovered.nextMode, .custom)
        // In-memory stores have independent archives: provide the recovered subject.
        recovered.context.insert(Subject(name: "Test")); recovered.save()
        recovered.start()
        XCTAssertEqual(recovered.active?.mode, .custom)
        XCTAssertNil(defaults.string(forKey: "nextSubject"))
        XCTAssertNil(defaults.string(forKey: "nextMode"))
    }
}

extension SessionLifecycleTests {
    func testPreparedSessionMatchesWhatStartsAfterBreak() throws {
        let s = try store()
        let subject = try XCTUnwrap(s.subjects.first)
        s.settings.preferredMode = .stopwatch
        s.settings.customMinutes = 45
        s.active = ActiveTimer(start: Date(), target: 300, subjectID: subject.id, subjectName: subject.name, mode: .custom, isBreak: true)
        s.skipBreak()
        XCTAssertEqual(s.preparedMode, .custom)
        XCTAssertEqual(s.preparedTarget, 2700)
        XCTAssertEqual(s.preparedSubject?.id, subject.id)
        s.start()
        XCTAssertEqual(s.active?.mode, .custom)
        XCTAssertEqual(s.active?.target, 2700)
    }
    func testChangingPreparedSelectionOverridesPendingSession() throws {
        let s = try store()
        s.nextMode = .custom
        s.nextSubject = s.subjects.first!.id
        let subject = Subject(name: "Altra materia")
        s.context.insert(subject); s.save()
        s.chooseSubject(subject.id)
        s.chooseMode(.stopwatch)
        XCTAssertNil(s.nextSubject)
        XCTAssertNil(s.nextMode)
        XCTAssertNil(s.preparedTarget)
        XCTAssertEqual(s.preparedSubject?.id, subject.id)
        s.start()
        XCTAssertEqual(s.active?.subjectID, subject.id)
        XCTAssertEqual(s.active?.mode, .stopwatch)
        XCTAssertNil(s.active?.target)
    }
}
