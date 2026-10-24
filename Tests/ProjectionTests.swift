import XCTest
import SwiftData
@testable import KomorebiStudy

@MainActor final class ProjectionTests: XCTestCase {
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Europe/Rome")!; return c }
    var today: Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 12))! }
    func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today)! }
    func calculate(target: Double? = 150, offset: Int = 27, start: Int = -10, entries: [ProjectionDailyHours] = []) -> StudyProjection? {
        ProjectionCalculator.calculate(requiredHours: target, preparationStart: day(start), examDate: day(offset), now: today, dailyGoal: 6, dailyHours: entries, calendar: calendar)
    }
    func testRequiredNumericalExample() throws {
        let entries = (-7 ... -1).map { ProjectionDailyHours(date: day($0), hours: 2) } + [.init(date: day(-9), hours: 6)]
        let r = try XCTUnwrap(calculate(entries: entries))
        XCTAssertEqual(r.doneHours,20); XCTAssertEqual(r.currentPace,2); XCTAssertEqual(r.daysRemaining,27)
        XCTAssertEqual(r.finalHours,74); XCTAssertEqual(try XCTUnwrap(r.necessaryPace),130/27,accuracy:0.0001)
        XCTAssertEqual(r.shortfall,76); XCTAssertEqual(r.status,.behind)
        XCTAssertEqual(r.daysRemaining, ExamCalendarDays.remaining(until: day(27), from: today, calendar: calendar))
    }
    func testMissingZeroTodayPastReachedAndYesterday() throws {
        XCTAssertNil(calculate(target:nil))
        let empty = try XCTUnwrap(calculate()); XCTAssertEqual(empty.currentPace,0); XCTAssertEqual(empty.finalHours,0)
        let due = try XCTUnwrap(calculate(offset:0)); XCTAssertNil(due.necessaryPace); XCTAssertEqual(due.status,.examToday)
        XCTAssertEqual(calculate(offset:-1)?.status,.past)
        let reached = try XCTUnwrap(calculate(target:10, entries:[.init(date:day(-1),hours:20)]))
        XCTAssertEqual(reached.status,.reached); XCTAssertEqual(reached.necessaryPace,0); XCTAssertEqual(reached.shortfall,0)
        let yesterday = try XCTUnwrap(calculate(start:-1,entries:[.init(date:day(-1),hours:4),.init(date:today,hours:2)]))
        XCTAssertEqual(yesterday.currentPace,4); XCTAssertEqual(yesterday.doneHours,6)
        XCTAssertEqual(calculate(start:0,entries:[.init(date:today,hours:2)])?.currentPace,2)
    }
    func testStatesTransitionAndUnsustainableAndZeroDays() throws {
        let sparse = [ProjectionDailyHours(date:day(-1),hours:14)]
        XCTAssertEqual(calculate(entries:sparse)?.currentPace,2,"Zero days must remain in the seven-day divisor")
        XCTAssertEqual(calculate(target:150,offset:1)?.status,.unsustainable)
        let inLine = (-7 ... -1).map { ProjectionDailyHours(date:day($0),hours:5) }
        XCTAssertEqual(calculate(entries:inLine)?.status,.onTrack)
        XCTAssertEqual(calculate(entries:[.init(date:day(-1),hours:160)])?.status,.reached)
    }
    func testStoreCacheIgnoresRunningTimerAndRefreshesAfterSaving() throws {
        let s = try StudyStore(inMemory:true,defaults:UserDefaults(suiteName:"Projection.\(UUID())")!)
        s.now = today
        let subject = s.subjects.first!
        let exam = StudyExam(title:subject.name,date:day(27),subjectID:subject.id)
        exam.requiredStudyHours = 150; exam.preparationStart = day(-10)
        s.context.insert(exam); XCTAssertTrue(s.save())
        let revision = s.projectionRevision
        s.refresh(); XCTAssertEqual(s.projectionRevision,revision)
        s.active = ActiveTimer(start:day(-1),target:nil,subjectID:subject.id,subjectName:subject.name,mode:.stopwatch)
        s.now = today.addingTimeInterval(1); XCTAssertEqual(s.projections[exam.id]?.doneHours,0)
        s.context.insert(StudySession(start:day(-1).addingTimeInterval(-3600),end:day(-1),duration:3600,subjectID:subject.id,subjectName:subject.name,mode:"Pomodoro",pause:0))
        XCTAssertTrue(s.save()); XCTAssertEqual(s.projections[exam.id]?.doneHours,1)
        XCTAssertGreaterThan(s.projectionRevision,revision)
        subject.isCompleted = true; XCTAssertTrue(s.save()); XCTAssertNil(s.projections[exam.id])
        subject.isCompleted = false; XCTAssertTrue(s.save()); XCTAssertNotNil(s.projections[exam.id])
        let record = try JSONDecoder().decode(ExamRecord.self,from:JSONEncoder().encode(ExamRecord(exam)))
        XCTAssertEqual(record.requiredStudyHours,150); XCTAssertEqual(record.preparationStart,exam.preparationStart)
    }
}

private enum ProjectionV23 {
    @Model final class StudyExam {
        @Attribute(.unique) var id: UUID
        var title: String; var date: Date; var hasTime: Bool; var subjectID: UUID?; var note: String
        var examKind: String? = nil; var examKindDetail: String? = nil
        init(id:UUID, subject:UUID) { self.id=id; title="Titolo storico"; date=Date(timeIntervalSince1970:123456); hasTime=true; subjectID=subject; note="Aula esistente"; examKind="written" }
    }
}
extension ProjectionTests {
    func testOldSchemaGetsBackupAndNoInventedHours() throws {
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:folder) }
        let url=folder.appendingPathComponent("Study.store"), id=UUID()
        do {
            let schema=Schema([Subject.self,StudySession.self,ProjectionV23.StudyExam.self])
            let container=try ModelContainer(for:schema,configurations:[ModelConfiguration(schema:schema,url:url)])
            let context=ModelContext(container); let subject=Subject(name:"Materia")
            context.insert(subject); context.insert(ProjectionV23.StudyExam(id:id,subject:subject.id)); try context.save()
        }
        XCTAssertTrue(ColorIDMigrationBackup.needsProjectionBackup(url))
        let s=try StudyStore(defaults:UserDefaults(suiteName:"ProjectionMigration.\(UUID())")!,archiveURL:url)
        let exam=try XCTUnwrap(s.exams.first)
        XCTAssertEqual(exam.id,id); XCTAssertEqual(exam.title,"Titolo storico"); XCTAssertEqual(exam.note,"Aula esistente")
        XCTAssertEqual(exam.examKind,"written"); XCTAssertNil(exam.requiredStudyHours); XCTAssertNil(exam.preparationStart)
        XCTAssertFalse(ColorIDMigrationBackup.needsProjectionBackup(url))
        let backups=try FileManager.default.contentsOfDirectory(at:folder.appendingPathComponent("Backups"),includingPropertiesForKeys:nil)
        let backup=try XCTUnwrap(backups.first { $0.lastPathComponent.hasPrefix("Projection-") })
        XCTAssertTrue(ColorIDMigrationBackup.needsProjectionBackup(backup.appendingPathComponent("Study.store")))
    }
}
