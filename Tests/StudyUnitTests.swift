import XCTest
import SwiftData
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
