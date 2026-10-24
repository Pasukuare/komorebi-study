import XCTest
import SwiftData
@testable import KomorebiStudy

@MainActor final class CompletedSubjectsTests: XCTestCase {
    func store() throws -> StudyStore { try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "CompletedTests.\(UUID())")!) }
    func testMigrationIsIdempotentAndPreservesOriginalTextAndSession() throws {
        let s = try store()
        let subject = Subject(name: "Misure Elettroniche"); subject.isCompleted = true; subject.grade = "18"; subject.completionVersion = nil
        let session = StudySession(start: Date(timeIntervalSince1970: 1000), end: Date(timeIntervalSince1970: 2000), duration: 900, subjectID: subject.id, subjectName: subject.name, mode: "Pomodoro", pause: 100)
        let unusual = Subject(name: "Idoneità"); unusual.grade = " 30 e lode "; unusual.isCompleted = true; unusual.completionVersion = nil
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(SessionRecord(session))
        XCTAssertEqual(SubjectCompletionMigration.apply(subjects: [subject,unusual], sessions: [session]), 2)
        XCTAssertEqual(subject.grade, "18"); XCTAssertEqual(subject.gradeValue, 18)
        XCTAssertEqual(subject.completedAt, session.endDate)
        XCTAssertEqual(unusual.gradeNote, " 30 e lode "); XCTAssertNil(unusual.completedAt)
        XCTAssertEqual(SubjectCompletionMigration.apply(subjects: [subject,unusual], sessions: [session]), 0)
        XCTAssertEqual(try encoder.encode(SessionRecord(session)), before)
    }
    func testCompletingCurrentSubjectNeverChangesOrStopsActiveSession() throws {
        let s = try store(); let a = s.subjects.first!
        let b = Subject(name: "Seconda"); s.context.insert(b); XCTAssertTrue(s.save())
        s.chooseSubject(a.id); s.start(); let active = s.active
        a.isCompleted = true; XCTAssertTrue(s.save())
        XCTAssertEqual(s.active?.id, active?.id); XCTAssertEqual(s.active?.subjectID, a.id)
        XCTAssertEqual(s.preparedSubject?.id, b.id)
        b.isCompleted = true; XCTAssertTrue(s.save()); XCTAssertNil(s.preparedSubject)
        s.finish(); XCTAssertEqual(s.sessions.first?.subjectID, a.id)
        b.isCompleted = false; XCTAssertTrue(s.save()); XCTAssertEqual(s.preparedSubject?.id, b.id)
    }
    func testCatalogIsNotRebuiltForClockOrSessionRefresh() throws {
        let s = try store(); let revision = s.subjectCatalogRevision
        s.now = Date().addingTimeInterval(3); s.refresh()
        XCTAssertEqual(s.subjectCatalogRevision, revision)
        s.subjects.first!.isCompleted = true; XCTAssertTrue(s.save())
        XCTAssertGreaterThan(s.subjectCatalogRevision, revision)
    }
}

extension CompletedSubjectsTests {
    func testWeeklyGoalExcludesCompletedButHistoricalTotalsDoNot() throws {
        let s = try store(); let a = s.subjects.first!
        let b = Subject(name: "Conclusa"); b.isCompleted = true; s.context.insert(b)
        let start = s.week.start.addingTimeInterval(3600)
        for subject in [a,b] { s.context.insert(StudySession(start: start, end: start.addingTimeInterval(1800), duration: 1800, subjectID: subject.id, subjectName: subject.name, mode: "Pomodoro", pause: 0)) }
        XCTAssertTrue(s.save())
        XCTAssertEqual(s.total(in: s.week), 3600)
        XCTAssertEqual(s.weeklyGoalProgress, 1800)
        b.isCompleted = false; XCTAssertTrue(s.save()); XCTAssertEqual(s.weeklyGoalProgress, 3600)
    }
    func testTypedGradeValidationHonorsAndDateRetention() {
        let subject = Subject(name: "Test")
        var draft = SubjectEditDraft(subject: subject); draft.completed = true
        for invalid in ["17","31","18.5","30 e lode","abc"] { draft.grade = invalid; XCTAssertFalse(draft.isValid) }
        for valid in ["","18","30"] { draft.grade = valid; XCTAssertTrue(draft.isValid) }
        draft.grade = "30"; draft.honors = true; draft.apply(to: subject)
        let date = subject.completedAt; XCTAssertNotNil(date); XCTAssertEqual(subject.gradeValue,30); XCTAssertEqual(subject.gradeHonors,true)
        draft = SubjectEditDraft(subject: subject); draft.completed = false; draft.apply(to: subject)
        XCTAssertEqual(subject.completedAt,date); XCTAssertEqual(subject.gradeValue,30)
        draft.completed = true; draft.grade = "28"; draft.apply(to: subject)
        XCTAssertEqual(subject.gradeHonors,false); XCTAssertEqual(subject.completedAt,date)
    }
}

private enum CompletionV20 {
    @Model final class Subject {
        @Attribute(.unique) var id: UUID
        var name: String; var icon: String; var color: String; var weeklyGoal: Double
        var completed: Bool? = nil; var grade: String? = nil
        init(id: UUID) { self.id = id; name = "Misure Elettroniche"; icon = "book"; color = "classici.salvia"; weeklyGoal = 5; completed = true; grade = "18" }
    }
}
extension CompletedSubjectsTests {
    func testRealOldSchemaGetsBackupBeforeAdditiveMigration() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Study.store"), id = UUID()
        do {
            let schema = Schema([CompletionV20.Subject.self, StudySession.self, StudyExam.self])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let context = ModelContext(container)
            context.insert(CompletionV20.Subject(id: id))
            context.insert(StudySession(start: Date(timeIntervalSince1970: 1000), end: Date(timeIntervalSince1970: 2000), duration: 900, subjectID: id, subjectName: "Misure Elettroniche", mode: "Pomodoro", pause: 100))
            try context.save()
        }
        XCTAssertTrue(ColorIDMigrationBackup.needsCompletionBackup(url))
        let store = try StudyStore(defaults: UserDefaults(suiteName: "Migration.\(UUID())")!, archiveURL: url)
        let subject = try XCTUnwrap(store.subjects.first { $0.id == id })
        XCTAssertEqual(subject.gradeValue,18); XCTAssertEqual(subject.grade,"18")
        XCTAssertEqual(subject.completedAt, Date(timeIntervalSince1970: 2000)); XCTAssertEqual(store.sessions.count,1)
        XCTAssertFalse(ColorIDMigrationBackup.needsCompletionBackup(url))
        let backups = try FileManager.default.contentsOfDirectory(at: folder.appendingPathComponent("Backups"), includingPropertiesForKeys: nil)
        XCTAssertEqual(backups.count,1)
        XCTAssertTrue(ColorIDMigrationBackup.needsCompletionBackup(backups[0].appendingPathComponent("Study.store")))
    }
}

extension CompletedSubjectsTests {
    func testThirtyFiveSubjectsUseCachedSummariesAndCompletionOrderPersists() throws {
        let s = try store()
        for index in 0..<35 {
            let subject = Subject(name: "Materia \(index)")
            subject.isCompleted = index % 2 == 0
            subject.completedAt = Date(timeIntervalSince1970: Double(index)*1000)
            s.context.insert(subject)
            s.context.insert(StudySession(start: s.day.start, end: s.day.start.addingTimeInterval(1200), duration: 1200, subjectID: subject.id, subjectName: subject.name, mode: "Pomodoro", pause: 0))
        }
        XCTAssertTrue(s.save())
        let revision = s.subjectCatalogRevision
        for _ in 0..<1000 {
            XCTAssertEqual(s.completedSubjects.first?.name, "Materia 34")
            XCTAssertEqual(s.subjectSummaries[s.completedSubjects.first!.id]?.count, 1)
        }
        XCTAssertEqual(s.subjectCatalogRevision, revision)
        s.settings.completedSubjectsExpanded = false
        XCTAssertEqual(try JSONDecoder().decode(UserSettings.self, from: JSONEncoder().encode(s.settings)).completedSubjectsExpanded, false)
        XCTAssertEqual(s.subjectSummaries.values.reduce(0) { $0+$1.count }, 35)
    }
}

extension CompletedSubjectsTests {
    func testSharedChoicesConsultationHistoryAndExamsOnCompleteAndReopen() throws {
        let s = try store(); let original = s.subjects.first!
        let active = Subject(name: "Teoria dei Sistemi")
        let completed = Subject(name: "Misure Elettroniche"); completed.isCompleted = true
        s.context.insert(active); s.context.insert(completed)
        let exam = StudyExam(title: "Misure Elettroniche", date: s.now.addingTimeInterval(86400), subjectID: completed.id)
        let openExam = StudyExam(title: "Teoria dei Sistemi", date: s.now.addingTimeInterval(172800), subjectID: active.id)
        s.context.insert(exam); s.context.insert(openExam)
        let session = StudySession(start: s.now.addingTimeInterval(-3600), end: s.now, duration: 3600, subjectID: completed.id, subjectName: "Misure Elettroniche", mode: "Pomodoro", pause: 0)
        s.context.insert(session); XCTAssertTrue(s.save())
        XCTAssertFalse(s.activeSubjectChoices.contains { $0.0 == completed.id })
        XCTAssertEqual(s.consultationSubjectChoices.last?.0, completed.id)
        XCTAssertEqual(s.historySubjectChoices.last?.0, .subject(completed.id))
        XCTAssertTrue(HistorySubjectSelection.subject(completed.id).matches(session))
        XCTAssertEqual(s.homeExams.map(\.id), [openExam.id])
        XCTAssertEqual(NextExamCountdown.nearest(in: s.homeExams, at: s.now)?.id, openExam.id)
        let options = s.editingSubjectChoices(currentID: session.subjectID, currentName: session.subjectName)
        XCTAssertEqual(options.first?.0, completed.id)
        XCTAssertTrue(options.contains { $0.0 == active.id }); XCTAssertEqual(options.filter { $0.0 == completed.id }.count,1)
        XCTAssertTrue(s.subjectChoiceIsAllowed(completed.id, retaining: completed.id))
        XCTAssertFalse(s.subjectChoiceIsAllowed(completed.id, retaining: original.id))
        let before = session.subjectName
        completed.isCompleted = false; XCTAssertTrue(s.save())
        XCTAssertTrue(s.activeSubjectIDs.contains(completed.id)); XCTAssertEqual(s.homeExams.count,2)
        XCTAssertEqual(session.subjectName,before)
        XCTAssertEqual(NextExamCountdown.nearest(in: s.homeExams, at: s.now)?.id, exam.id)
        for subject in s.subjects { subject.isCompleted = true }; XCTAssertTrue(s.save())
        XCTAssertTrue(s.activeSubjectChoices.isEmpty); XCTAssertNil(s.preparedSubject)
        s.start(); XCTAssertNil(s.active)
    }
    func testLegacyNamesRemainConsultableWithoutCaseChangesOrSentinelCollision() throws {
        let s = try store()
        let legacy = StudySession(start: s.now.addingTimeInterval(-1000), end: s.now, duration: 1000, subjectID: UUID(), subjectName: "Tutte", mode: "Cronometro", pause: 0)
        s.context.insert(legacy); XCTAssertTrue(s.save())
        XCTAssertTrue(s.historySubjectChoices.contains { $0.0 == .legacyName("Tutte") })
        XCTAssertTrue(HistorySubjectSelection.legacyName("Tutte").matches(legacy))
    }
}

extension CompletedSubjectsTests {
    func testNamesAreNeverCapitalizedInCatalogCountdownOrBackup() throws {
        let s = try store()
        let name = "Teoria dei Sistemi — f(x) e iOS"
        let subject = Subject(name: name); s.context.insert(subject)
        let exam = StudyExam(title: "esame di Teoria dei Sistemi", date: s.now.addingTimeInterval(86400), subjectID: subject.id)
        s.context.insert(exam); XCTAssertTrue(s.save())
        XCTAssertEqual(s.activeSubjectChoices.first { $0.0 == subject.id }?.1, name)
        XCTAssertEqual(NextExamCountdown.nearest(in: s.homeExams, at: s.now)?.title, exam.title)
        let copy = try JSONDecoder().decode(SubjectRecord.self, from: JSONEncoder().encode(SubjectRecord(subject)))
        XCTAssertEqual(copy.name,name)
    }
}
