import XCTest
import SwiftData
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class StudyUnitTests: XCTestCase {
    func testGeneratorsAndBreakRules() {
        XCTAssertEqual(UnitRules.numbered(from:1,through:20,prefix:"Lezione ").count,20)
        let pages = UnitRules.pages(from:1,through:100,block:15,prefix:"Pag. ")
        XCTAssertEqual(pages.count,7); XCTAssertEqual(pages.last?.firstPage,91); XCTAssertEqual(pages.last?.lastPage,100)
        XCTAssertTrue(UnitRules.pages(from:1,through:100,block:0,prefix:"").isEmpty)
        XCTAssertTrue(UnitRules.numbered(from:4,through:1,prefix:"").isEmpty)
        XCTAssertEqual(UnitRules.breakMinutes(studiedMinutes:40),8)
        XCTAssertEqual(UnitRules.breakMinutes(studiedMinutes:10),5)
        XCTAssertEqual(UnitRules.breakMinutes(studiedMinutes:150),20)
    }
    func testMedianRequiresThreeAndUsesMinutesPerPage() {
        let samples = [UnitRules.Sample(minutes:20,pages:10),.init(minutes:40,pages:20),.init(minutes:90,pages:30)]
        XCTAssertNil(UnitRules.estimate(samples:Array(samples.prefix(2))))
        XCTAssertEqual(UnitRules.estimate(samples:samples),40)
        XCTAssertEqual(UnitRules.estimate(samples:samples,pageCount:15),30)
    }
    func store() throws -> StudyStore { try StudyStore(inMemory:true,defaults:UserDefaults(suiteName:"Units.\(UUID())")!) }
    func testResumeMergesAndDeletionKeepsHistory() throws {
        let s = try store(), subject = try XCTUnwrap(s.subjects.first)
        s.addUnits(subject:subject,seeds:UnitRules.numbered(from:1,through:2,prefix:"Lezione "),kind:.lesson)
        s.chooseMode(.unit)
        let unit = try XCTUnwrap(s.preparedUnit)
        XCTAssertNil(s.preparedTarget)
        let end = Date().addingTimeInterval(-1)
        s.active = ActiveTimer(start:end.addingTimeInterval(-600),target:nil,subjectID:subject.id,subjectName:subject.name,mode:.unit,unitID:unit.id,unitTitle:unit.title)
        s.finishUnit(finished:false,at:end)
        XCTAssertEqual(s.sessions.count,1); XCTAssertEqual(s.sessions.first?.duration,600)
        XCTAssertEqual(unit.unitState,.inProgress)
        s.active = ActiveTimer(start:end.addingTimeInterval(0.1),target:nil,subjectID:subject.id,subjectName:subject.name,mode:.unit,unitID:unit.id,unitTitle:unit.title)
        s.finishUnit(finished:true,at:end.addingTimeInterval(0.6))
        XCTAssertEqual(s.sessions.count,1); XCTAssertEqual(s.sessions[0].duration,600.5,accuracy:0.001)
        XCTAssertEqual(unit.unitState,.finished); XCTAssertEqual(s.active?.isBreak,true)
        XCTAssertEqual(s.active?.target,300)
        s.deleteUnit(unit)
        XCTAssertEqual(s.sessions.count,1); XCTAssertEqual(s.sessions[0].unitTitle,"Lezione 1")
        s.skipBreak(); XCTAssertEqual(s.preparedUnit?.title,"Lezione 2")
        let revision = s.unitCacheRevision
        s.refresh(); XCTAssertEqual(revision,s.unitCacheRevision)
        s.now = Date().addingTimeInterval(1); XCTAssertEqual(revision,s.unitCacheRevision)
    }
    func testLegacySettingsAndActiveTimerDecode() throws {
        let encoder = JSONEncoder(), decoder = JSONDecoder()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with:encoder.encode(UserSettings())) as? [String:Any])
        object.removeValue(forKey:"unitBreakFraction"); object.removeValue(forKey:"unitBreakMinimum"); object.removeValue(forKey:"unitBreakMaximum")
        let legacy = try decoder.decode(UserSettings.self,from:JSONSerialization.data(withJSONObject:object))
        XCTAssertEqual(UnitRules.breakMinutes(studiedMinutes:40,fraction:legacy.unitBreakFraction ?? 0.2),8)
        let s = StudySession(start:Date(),end:Date(),duration:0,subjectID:nil,subjectName:"Legacy",mode:"Pomodoro",pause:0,note:"Lezione 3 terminata")
        XCTAssertNil(s.unitID); XCTAssertEqual(SessionRecord(s).model.note,s.note)
    }
}

private enum UnitsV25 {
    @Model final class StudySession {
        @Attribute(.unique) var id: UUID
        var startDate: Date; var endDate: Date; var duration: Double; var subjectID: UUID?
        var subjectName: String; var timerMode: String; var pauseDuration: Double; var note: String
        var activityData: Data? = nil
        init(id:UUID, subjectID:UUID) {
            self.id=id; self.subjectID=subjectID; startDate=Date(timeIntervalSince1970:1000); endDate=Date(timeIntervalSince1970:1600)
            duration=500; pauseDuration=100; subjectName="Materia precedente"; timerMode="Pomodoro"; note="Lezione 3 terminata"
        }
    }
}
extension StudyUnitTests {
    func testPreviousSchemaIsBackedUpBeforeAddingUnits() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:directory) }
        let url=directory.appendingPathComponent("Study.store"), sessionID=UUID()
        do {
            let schema=Schema([Subject.self,StudyExam.self,UnitsV25.StudySession.self])
            let container=try ModelContainer(for:schema,configurations:[ModelConfiguration(schema:schema,url:url)])
            let context=ModelContext(container), subject=Subject(name:"Materia precedente")
            context.insert(subject); context.insert(UnitsV25.StudySession(id:sessionID,subjectID:subject.id)); try context.save()
        }
        XCTAssertTrue(ColorIDMigrationBackup.needsUnitsBackup(url))
        let store=try StudyStore(defaults:UserDefaults(suiteName:"UnitMigration.\(UUID())")!,archiveURL:url)
        let session=try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(session.id,sessionID); XCTAssertEqual(session.duration,500); XCTAssertEqual(session.pauseDuration,100)
        XCTAssertEqual(session.note,"Lezione 3 terminata"); XCTAssertNil(session.unitID); XCTAssertTrue(store.units.isEmpty)
        XCTAssertFalse(ColorIDMigrationBackup.needsUnitsBackup(url))
        let backups=try FileManager.default.contentsOfDirectory(at:directory.appendingPathComponent("Backups"),includingPropertiesForKeys:nil)
        let snapshot=try XCTUnwrap(backups.first { $0.lastPathComponent.hasPrefix("StudyUnits-") })
        XCTAssertTrue(ColorIDMigrationBackup.needsUnitsBackup(snapshot.appendingPathComponent("Study.store")))
        let second=try StudyStore(defaults:UserDefaults(suiteName:"UnitMigration2.\(UUID())")!,archiveURL:url)
        XCTAssertEqual(second.sessions.count,1)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:directory.appendingPathComponent("Backups").path).count,backups.count)
    }
}


extension StudyUnitTests {
    func testSharedDraftValidationReorderAndOptionalEstimate() throws {
        let s=try store(), subject=try XCTUnwrap(s.subjects.first)
        var draft=StudyUnitDraft(); XCTAssertFalse(draft.isValid)
        draft.title="Lezione 1"; XCTAssertTrue(draft.isValid)
        draft.estimate="non valido"; XCTAssertFalse(draft.isValid)
        draft.estimate="40,5"; XCTAssertTrue(draft.isValid)
        draft.kind = .pages; draft.firstPage="10"; draft.lastPage="5"; XCTAssertFalse(draft.isValid)
        draft.lastPage="20"; XCTAssertTrue(draft.isValid)
        let unit=StudyUnit(subjectID:subject.id,title:"Originale")
        draft.apply(to:unit); XCTAssertEqual(unit.pageCount,11); XCTAssertEqual(unit.estimatedMinutes,40.5)
        s.addUnits(subject:subject,seeds:UnitRules.numbered(from:1,through:3,prefix:"Lezione "),kind:.lesson)
        let first=try XCTUnwrap(s.unitsBySubject[subject.id]?.first)
        s.moveUnit(first,by:1); XCTAssertEqual(s.unitsBySubject[subject.id]?[1].id,first.id)
        s.moveUnit(first,by:-1); XCTAssertEqual(s.unitsBySubject[subject.id]?.first?.id,first.id)
    }
    func testUnitManagementRendersInAllThemes() throws {
        try ThemeFonts.register()
        let s=try store(), subject=try XCTUnwrap(s.subjects.first)
        subject.name="Teoria dei Sistemi — nome lungo della materia"
        s.addUnits(subject:subject,seeds:UnitRules.pages(from:1,through:100,block:15,prefix:"Pagine "),kind:.pages)
        s.chooseMode(.unit)
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme=package.resolve(mode:mode)
                let unit=try XCTUnwrap(s.units.first)
                let views:[(String,AnyView)] = [
                    ("unita",AnyView(StudyUnitsSection(subject:subject,initiallyExpanded:true))),
                    ("modifica-unita",AnyView(StudyUnitEditor(subject:subject,unit:unit))),
                    ("crea-piu-unita",AnyView(StudyUnitsBatchEditor(subject:subject))),
                    ("timer-per-unita",AnyView(TimerSetup())),
                    ("home-per-unita",AnyView(OverviewView(openTimer:{},openCalendar:{},openThemeSettings:{})))
                ]
                for (name,view) in views {
                    let rendered=view.frame(width:760,height:780,alignment:.topLeading).padding(DesignSystem.Spacing.md)
                        .environmentObject(s).environment(\.studyTheme,theme).environment(\.colorScheme,mode == .dark ? .dark : .light)
                        .environment(\.komorebiMotion,"Off").foregroundStyle(theme.palette.textPrimary).background(theme.palette.background)
                        .buttonStyle(ResponsiveButtonStyle()).textFieldStyle(StudyTextFieldStyle())
                    let host=NSHostingView(rootView:rendered)
                    let window=NSWindow(contentRect:CGRect(x:0,y:0,width:800,height:820),styleMask:[.borderless],backing:.buffered,defer:false)
                    window.contentView=host; host.frame=window.contentView!.bounds
                    host.layoutSubtreeIfNeeded(); RunLoop.main.run(until:Date().addingTimeInterval(0.05)); host.layoutSubtreeIfNeeded()
                    let bitmap=try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in:host.bounds)); host.cacheDisplay(in:host.bounds,to:bitmap)
                    if let path=ProcessInfo.processInfo.environment["KOMOREBI_UNITS_REVIEW"] {
                        let folder=URL(fileURLWithPath:path); try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
                        try XCTUnwrap(bitmap.representation(using:.png,properties:[:])).write(to:folder.appendingPathComponent("\(name)-\(package.id)-\(mode.rawValue).png"))
                    }
                    window.contentView=nil
                }
            }
        }
    }
}


extension StudyUnitTests {
    func testStartingEmptyCompletedSubjectAndActiveUnitEdits() throws {
        let s=try store(), subject=try XCTUnwrap(s.subjects.first)
        s.chooseMode(.unit); XCTAssertFalse(s.canStart)
        s.start(); XCTAssertNil(s.active)
        s.error=nil
        s.addUnits(subject:subject,seeds:[UnitSeed(title:"Capitolo 1")],kind:.chapter)
        XCTAssertTrue(s.canStart)
        let unit=try XCTUnwrap(s.preparedUnit)
        unit.estimatedMinutes=40; XCTAssertTrue(s.save())
        s.start(); XCTAssertNil(s.active?.target); XCTAssertEqual(s.active?.unitID,unit.id)
        XCTAssertEqual(s.active?.unitEstimate,40); XCTAssertEqual(unit.unitState,.inProgress)
        unit.title="Titolo modificato"; subject.isCompleted=true; XCTAssertTrue(s.save())
        XCTAssertEqual(s.active?.unitTitle,"Capitolo 1"); XCTAssertTrue(s.activeSubjects.isEmpty)
        s.finishUnit(finished:true)
        XCTAssertEqual(unit.unitState,.finished); XCTAssertEqual(s.sessions.first?.unitTitle,"Capitolo 1")
        s.skipBreak(); XCTAssertFalse(s.canStart)
    }
    func testUnitSettingsSanitizeAndBackupRoundTrip() throws {
        var settings=UserSettings(); settings.unitBreakFraction=Double.nan; settings.unitBreakMinimum=10; settings.unitBreakMaximum=3
        settings.sanitize(); XCTAssertEqual(settings.unitBreakFraction,0.2); XCTAssertEqual(settings.unitBreakMaximum,10)
        let s=try store(), subject=try XCTUnwrap(s.subjects.first)
        let unit=StudyUnit(subjectID:subject.id,title:"Video 1",kind:.video)
        s.context.insert(unit); XCTAssertTrue(s.save())
        let copy=try JSONDecoder().decode(UnitRecord.self,from:JSONEncoder().encode(UnitRecord(unit))).model
        XCTAssertEqual(copy.id,unit.id); XCTAssertEqual(copy.title,unit.title)
        let active=ActiveTimer(start:Date(),target:nil,subjectID:subject.id,subjectName:subject.name,mode:.unit,unitID:unit.id,unitTitle:unit.title,unitEstimate:20)
        let restored=try JSONDecoder().decode(ActiveTimer.self,from:JSONEncoder().encode(active))
        XCTAssertEqual(restored.unitID,unit.id); XCTAssertEqual(restored.unitEstimate,20)
    }
}
