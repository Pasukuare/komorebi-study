import XCTest
import SwiftData
import SwiftUI
import AppKit
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

extension ProjectionTests {
    func testTargetInputAndLiveStateChanges() throws {
        XCTAssertNil(ProjectionTargetInput.hours("")); XCTAssertNil(ProjectionTargetInput.hours("0"))
        XCTAssertNil(ProjectionTargetInput.hours("-4")); XCTAssertNil(ProjectionTargetInput.hours("nan"))
        XCTAssertEqual(ProjectionTargetInput.hours("4,8"),4.8)
        let s=try StudyStore(inMemory:true,defaults:UserDefaults(suiteName:"ProjectionState.\(UUID())")!)
        s.now=today; s.settings.dailyGoal=6
        let a=s.subjects.first!, b=Subject(name:"Seconda"), c=Subject(name:"Completata")
        c.isCompleted=true; s.context.insert(b); s.context.insert(c)
        let exam=StudyExam(title:a.name,date:day(27),subjectID:a.id); exam.requiredStudyHours=150; exam.preparationStart=day(-10)
        let second=StudyExam(title:b.name,date:day(19),subjectID:b.id)
        let excluded=StudyExam(title:c.name,date:day(5),subjectID:c.id)
        for e in [exam,second,excluded] { s.context.insert(e) }
        func saveHours(_ hours:Double, offset:Int) {
            let start=calendar.startOfDay(for:day(offset)).addingTimeInterval(3600)
            s.context.insert(StudySession(start:start,end:start.addingTimeInterval(hours*3600),duration:hours*3600,subjectID:a.id,subjectName:a.name,mode:"Cronometro",pause:0))
        }
        saveHours(6,offset:-9); for d in -7 ... -1 { saveHours(2,offset:d) }; XCTAssertTrue(s.save())
        XCTAssertEqual(s.projectionExams.map(\.id),[second.id,exam.id]); XCTAssertNil(second.requiredStudyHours)
        XCTAssertEqual(s.projections[exam.id]?.finalHours,74); XCTAssertEqual(s.projections[exam.id]?.status,.behind)
        for d in -7 ... -1 { saveHours(3,offset:d) }; XCTAssertTrue(s.save()); XCTAssertEqual(s.projections[exam.id]?.status,.onTrack)
        for d in -7 ... -1 { saveHours(17,offset:d) }; XCTAssertTrue(s.save()); XCTAssertEqual(s.projections[exam.id]?.status,.reached)
        a.isCompleted=true; XCTAssertTrue(s.save()); XCTAssertFalse(s.projectionExams.contains { $0.id==exam.id })
        a.isCompleted=false; XCTAssertTrue(s.save()); XCTAssertTrue(s.projectionExams.contains { $0.id==exam.id })
        let revision=s.projectionRevision
        for _ in 0..<1000 { _=s.projections[exam.id] }
        XCTAssertEqual(s.projectionRevision,revision)
    }
    func testProjectionScreensForReview() throws {
        guard let output=ProcessInfo.processInfo.environment["KOMOREBI_PROJECTION_REVIEW"] else { return }
        try ThemeFonts.register()
        let s=try StudyStore(inMemory:true,defaults:UserDefaults(suiteName:"ProjectionReview.\(UUID())")!)
        s.now=today; s.settings.dailyGoal=6; s.settings.animations="Off"; s.settings.dismissedThemeCampaigns=["halloween-2026"]
        let subject=s.subjects.first!; subject.name="Teoria dei Sistemi"
        let exam=StudyExam(title:subject.name,date:day(27),subjectID:subject.id)
        exam.requiredStudyHours=150; exam.preparationStart=day(-13); s.context.insert(exam)
        let secondSubject=Subject(name:"Matematica",color:"primavera.glicine"), completed=Subject(name:"Misure Elettroniche")
        completed.isCompleted=true; s.context.insert(secondSubject); s.context.insert(completed)
        let second=StudyExam(title:secondSubject.name,date:day(19),subjectID:secondSubject.id)
        let excluded=StudyExam(title:completed.name,date:day(5),subjectID:completed.id)
        s.context.insert(second); s.context.insert(excluded)
        for offset in [-12,-11,-10] + Array(-7 ... -1) {
            let hours:Double=2
            let start=calendar.startOfDay(for:day(offset)).addingTimeInterval(3600)
            s.context.insert(StudySession(start:start,end:start.addingTimeInterval(hours*3600),duration:hours*3600,subjectID:subject.id,subjectName:subject.name,mode:"Pomodoro",pause:0))
        }
        XCTAssertTrue(s.save())
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                func capture<V:View>(_ view:V, name:String) throws {
                    let host=NSHostingView(rootView:view.frame(width:720).padding(DesignSystem.Spacing.lg)
                        .environmentObject(s).environment(\.studyTheme,package.resolve(mode:mode))
                        .environment(\.colorScheme,mode == .dark ? .dark : .light).environment(\.komorebiMotion,"Off")
                        .foregroundStyle(package.resolve(mode:mode).palette.textPrimary).background(package.resolve(mode:mode).palette.background)
                        .buttonStyle(ResponsiveButtonStyle()).textFieldStyle(StudyTextFieldStyle()))
                    let size=host.fittingSize
                    let window=NSWindow(contentRect:CGRect(origin:.zero,size:size),styleMask:[.borderless],backing:.buffered,defer:false)
                    window.contentView=host; host.frame=CGRect(origin:.zero,size:size)
                    host.layoutSubtreeIfNeeded(); RunLoop.main.run(until:Date().addingTimeInterval(0.05)); host.layoutSubtreeIfNeeded()
                    let bitmap=try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in:host.bounds)); host.cacheDisplay(in:host.bounds,to:bitmap)
                    try XCTUnwrap(bitmap.representation(using:.png,properties:[:])).write(to:URL(fileURLWithPath:output).appendingPathComponent("\(name)-\(package.id)-\(mode.rawValue).png"))
                    window.contentView=nil
                }
                try capture(ProjectionCard(openCalendar:{},initialExamID:exam.id),name:"proiezione")
                exam.requiredStudyHours=nil; exam.preparationStart=nil; XCTAssertTrue(s.save())
                try capture(ProjectionCard(openCalendar:{}),name:"ore-vuote")
                exam.requiredStudyHours=150; exam.preparationStart=day(-13); XCTAssertTrue(s.save())
            }
        }
    }
}
