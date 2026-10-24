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

extension StudyUnitTests {
    func testEstimatesArePerSubjectAndTypeAndProjectionDoesNotInventHours() throws {
        let s=try store(), a=try XCTUnwrap(s.subjects.first)
        let b=Subject(name:"Libro",color:"autunno.zucca"), completed=Subject(name:"Conclusa")
        completed.isCompleted=true; s.context.insert(b); s.context.insert(completed)
        let end=Date().addingTimeInterval(-86400)
        for (index,minutes) in [20.0,40,60].enumerated() {
            let unit=StudyUnit(subjectID:a.id,title:"Lezione \(index+1)",order:index)
            unit.state=StudyUnitState.finished.rawValue; s.context.insert(unit)
            let session=StudySession(start:end.addingTimeInterval(-minutes*60),end:end,duration:minutes*60,subjectID:a.id,subjectName:a.name,mode:TimerMode.unit.rawValue,pause:0)
            session.unitID=unit.id; session.unitTitle=unit.title; session.unitFinished=true; s.context.insert(session)
            let pages=StudyUnit(subjectID:b.id,title:"Pagine \(index)",kind:.pages,order:index,firstPage:1,lastPage:10)
            pages.state=StudyUnitState.finished.rawValue; s.context.insert(pages)
            let reading=StudySession(start:end.addingTimeInterval(-minutes*60),end:end,duration:minutes*60,subjectID:b.id,subjectName:b.name,mode:TimerMode.unit.rawValue,pause:0)
            reading.unitID=pages.id; s.context.insert(reading)
        }
        let next=StudyUnit(subjectID:a.id,title:"Lezione 4",order:3)
        let pageTarget=StudyUnit(subjectID:b.id,title:"Pagine 31–45",kind:.pages,order:3,firstPage:31,lastPage:45)
        let otherKind=StudyUnit(subjectID:a.id,title:"Capitolo",kind:.chapter,order:4,estimatedMinutes:50)
        s.context.insert(next); s.context.insert(pageTarget); s.context.insert(otherKind); XCTAssertTrue(s.save())
        XCTAssertEqual(s.unitEstimates[next.id],40); XCTAssertEqual(s.unitEstimates[pageTarget.id],60)
        XCTAssertEqual(s.unitSummaries[a.id]?.finished,3); XCTAssertEqual(s.unitSummaries[a.id]?.averageMinutes,40)
        XCTAssertNil(s.unitSummaries[a.id]?.remainingMinutes,"Manual estimates do not fabricate automatic evidence for another kind")
        s.deleteUnit(otherKind)
        XCTAssertEqual(s.unitSummaries[a.id]?.remainingMinutes,40)
        XCTAssertEqual(s.unitSummaries[b.id]?.remainingMinutes,60)
        XCTAssertFalse(s.activeSubjects.contains { $0.id == completed.id })
        let revision=s.unitCacheRevision
        for _ in 0..<1000 { _ = s.unitSummaries[a.id]; _ = s.unitEstimates[next.id] }
        XCTAssertEqual(s.unitCacheRevision,revision)
        next.state=StudyUnitState.finished.rawValue; XCTAssertTrue(s.save())
        XCTAssertEqual(s.unitSummaries[a.id]?.finished,4); XCTAssertNil(s.unitSummaries[a.id]?.remainingMinutes)
    }
    func testCumulativeSessionKeepsMidnightAndPauseAllocation() throws {
        let s=try store(), subject=try XCTUnwrap(s.subjects.first)
        let unit=StudyUnit(subjectID:subject.id,title:"Unità lunga")
        s.context.insert(unit); XCTAssertTrue(s.save())
        let midnight=Calendar.current.startOfDay(for:Date()).addingTimeInterval(-86400)
        let start=midnight.addingTimeInterval(-1800), end=midnight.addingTimeInterval(1800)
        s.active=ActiveTimer(start:start,target:nil,subjectID:subject.id,subjectName:subject.name,mode:.unit,unitID:unit.id,unitTitle:unit.title)
        s.active?.pause(at:midnight.addingTimeInterval(-600)); s.active?.resume(at:midnight.addingTimeInterval(600))
        s.finishUnit(finished:false,at:end)
        let resumed=midnight.addingTimeInterval(86400+600)
        s.active=ActiveTimer(start:resumed,target:nil,subjectID:subject.id,subjectName:subject.name,mode:.unit,unitID:unit.id,unitTitle:unit.title)
        s.finishUnit(finished:true,at:resumed.addingTimeInterval(600))
        let session=try XCTUnwrap(s.sessions.first); XCTAssertEqual(s.sessions.count,1); XCTAssertEqual(session.duration,3000)
        let yesterday=DateInterval(start:midnight,end:midnight.addingTimeInterval(86400))
        XCTAssertEqual(s.contribution(session,in:yesterday),1200,accuracy:0.001)
        XCTAssertEqual(s.contribution(session,in:DateInterval(start:midnight.addingTimeInterval(-86400),end:midnight)),1200,accuracy:0.001)
        XCTAssertEqual(s.contribution(session,in:DateInterval(start:resumed,end:resumed.addingTimeInterval(600))),600,accuracy:0.001)
    }
}

extension StudyUnitTests {
    func testIntegratedScreensRenderWithLessonsPagesAndCompletedSubject() throws {
        try ThemeFonts.register()
        let s=try store(), a=try XCTUnwrap(s.subjects.first)
        a.name="Lezioni di analisi"
        let book=Subject(name:"Libro di fisica",color:"estate.mare"), done=Subject(name:"Materia completata")
        done.isCompleted=true; s.context.insert(book); s.context.insert(done)
        for subject in [a,book] {
            for i in 1...4 {
                let unit=StudyUnit(subjectID:subject.id,title:subject.id == a.id ? "Lezione \(i)" : "Pagine \((i-1)*15+1)–\(i*15)",kind:subject.id == a.id ? .lesson : .pages,order:i,firstPage:subject.id == a.id ? nil : (i-1)*15+1,lastPage:subject.id == a.id ? nil : i*15)
                if i<4 {
                    unit.state=StudyUnitState.finished.rawValue
                    let end=Calendar.current.date(byAdding:.day,value:-i,to:Date())!
                    let session=StudySession(start:end.addingTimeInterval(-2400),end:end,duration:2400,subjectID:subject.id,subjectName:subject.name,mode:TimerMode.unit.rawValue,pause:0)
                    session.unitID=unit.id; session.unitTitle=unit.title; session.unitFinished=true; s.context.insert(session)
                }
                s.context.insert(unit)
            }
        }
        let exam=StudyExam(title:a.name,date:Calendar.current.date(byAdding:.day,value:27,to:Date())!,subjectID:a.id)
        exam.requiredStudyHours=100; exam.preparationStart=Calendar.current.date(byAdding:.day,value:-10,to:Date())
        s.context.insert(exam); XCTAssertTrue(s.save()); s.chooseMode(.unit); s.chooseSubject(a.id)
        let unit=try XCTUnwrap(s.preparedUnit)
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme=package.resolve(mode:mode)
                func capture<V:View>(_ view:V,_ name:String,height:CGFloat=800) throws {
                    let host=NSHostingView(rootView:view.frame(width:1100,height:height,alignment:.topLeading).environmentObject(s)
                        .environment(\.studyTheme,theme).environment(\.colorScheme,mode == .dark ? .dark : .light)
                        .environment(\.komorebiMotion,"Off").foregroundStyle(theme.palette.textPrimary).background(theme.palette.background)
                        .buttonStyle(ResponsiveButtonStyle()).toggleStyle(StudyToggleStyle()).textFieldStyle(StudyTextFieldStyle()))
                    let window=NSWindow(contentRect:CGRect(x:0,y:0,width:1100,height:height),styleMask:[.borderless],backing:.buffered,defer:false)
                    window.contentView=host; host.frame=window.contentView!.bounds
                    host.layoutSubtreeIfNeeded(); RunLoop.main.run(until:Date().addingTimeInterval(0.05)); host.layoutSubtreeIfNeeded()
                    let bitmap=try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in:host.bounds)); host.cacheDisplay(in:host.bounds,to:bitmap)
                    if let path=ProcessInfo.processInfo.environment["KOMOREBI_UNITS_REVIEW"] {
                        let folder=URL(fileURLWithPath:path); try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
                        try XCTUnwrap(bitmap.representation(using:.png,properties:[:])).write(to:folder.appendingPathComponent("\(name)-\(package.id)-\(mode.rawValue).png"))
                    }
                    window.contentView=nil
                }
                s.active=nil
                try capture(OverviewView(openTimer:{},openCalendar:{},openThemeSettings:{}),"home-integrata",height:1700)
                try capture(StatisticsView(),"statistiche-unita",height:1400)
                try capture(HistoryView(),"cronologia-unita")
                try capture(ProjectionCard(openCalendar:{}),"proiezione-unita",height:1050)
                s.active=ActiveTimer(start:Date().addingTimeInterval(-1200),target:nil,subjectID:a.id,subjectName:a.name,mode:.unit,unitID:unit.id,unitTitle:unit.title,unitEstimate:40)
                try capture(HomeView(),"timer-unita-attiva",height:1000)
                s.active=ActiveTimer(start:Date(),pausedAt:Date(),target:480,subjectID:a.id,subjectName:a.name,mode:.unit,isBreak:true)
                try capture(SessionControls(),"pausa-unita",height:500)
                s.active=nil
                let states=s.units.map { ($0,$0.state) }
                for unit in s.units { unit.state=StudyUnitState.finished.rawValue }; XCTAssertTrue(s.save())
                XCTAssertNil(s.preparedUnit); XCTAssertFalse(s.canStart)
                try capture(TimerSetup(),"unita-tutte-finite",height:600)
                for (unit,state) in states { unit.state=state }; XCTAssertTrue(s.save())
                XCTAssertEqual(s.preparedUnit?.id,unit.id); XCTAssertTrue(s.canStart)
            }
        }
    }
}


extension StudyUnitTests {
    func testRecoveredUnitSegmentIsNotCountedTwice() throws {
        let s=try store(), subject=try XCTUnwrap(s.subjects.first)
        let unit=StudyUnit(subjectID:subject.id,title:"Unità recuperata")
        s.context.insert(unit); XCTAssertTrue(s.save())
        let end=Date().addingTimeInterval(-10)
        let active=ActiveTimer(start:end.addingTimeInterval(-600),target:nil,subjectID:subject.id,subjectName:subject.name,mode:.unit,unitID:unit.id,unitTitle:unit.title)
        s.active=active; s.finishUnit(finished:false,at:end)
        s.active=active; s.finishUnit(finished:false,at:end)
        XCTAssertEqual(s.sessions.count,1); XCTAssertEqual(s.sessions[0].duration,600,accuracy:0.001)
        s.active=active; s.finishUnit(finished:true,at:end.addingTimeInterval(5))
        XCTAssertEqual(s.sessions[0].duration,605,accuracy:0.001)
    }
}
