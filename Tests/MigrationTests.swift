import XCTest
import SwiftData
@testable import KomorebiStudy
@MainActor final class MigrationTests: XCTestCase {
    func testAddingExamModelPreservesExistingArchive() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Study.store")
        let id = UUID()
        do {
            let old = Schema([StudySession.self, Subject.self])
            let container = try ModelContainer(for: old, configurations: [ModelConfiguration(schema: old, url: url)])
            let context = ModelContext(container)
            context.insert(StudySession(id: id, start: Date(), end: Date(), duration: 0, subjectID: nil, subjectName: "Archivio precedente", mode: "Pomodoro", pause: 0))
            try context.save()
        }
        let new = Schema([StudySession.self, Subject.self, StudyExam.self])
        let container = try ModelContainer(for: new, configurations: [ModelConfiguration(schema: new, url: url)])
        let context = ModelContext(container)
        XCTAssertEqual(try context.fetch(FetchDescriptor<StudySession>()).first?.id, id)
        context.insert(StudyExam(title: "Esame", date: Date()))
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<StudyExam>()), 1)
    }
}

@MainActor final class SubjectColorMigrationTests: XCTestCase {
    func makeStore() throws -> StudyStore {
        try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "Colors.\(UUID())")!)
    }
    func testDoubleMigrationPreservesAssociationsAndUnknownIDs() throws {
        let store = try makeStore()
        let subject = Subject(name: "Analisi", icon: "function", weeklyGoal: 7)
        subject.color = "Cielo" // Real legacy storage, bypassing the new-model initializer.
        let unknown = Subject(name: "Futuro", color: "autunno.zucca")
        store.context.insert(subject); store.context.insert(unknown)
        let session = StudySession(start: Date().addingTimeInterval(-3600), end: Date(), duration: 3500, subjectID: subject.id, subjectName: subject.name, mode: "Cronometro", pause: 100, note: "Appunti da conservare")
        let exam = StudyExam(title: "Esame", date: Date(), subjectID: subject.id)
        store.context.insert(session); store.context.insert(exam); XCTAssertTrue(store.save())
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(SessionRecord(session))
        XCTAssertEqual(try store.migrateSubjectColorIDs(), 1)
        let first = try encoder.encode(store.subjects.map(SubjectRecord.init))
        XCTAssertEqual(try store.migrateSubjectColorIDs(), 0)
        XCTAssertEqual(try encoder.encode(store.subjects.map(SubjectRecord.init)), first)
        XCTAssertEqual(try encoder.encode(SessionRecord(session)), before)
        XCTAssertEqual(subject.color, "classici.azzurro-polvere")
        XCTAssertEqual(subject.icon, "function"); XCTAssertEqual(subject.name, "Analisi"); XCTAssertEqual(subject.weeklyGoal, 7)
        XCTAssertEqual(session.subjectID, subject.id); XCTAssertEqual(exam.subjectID, subject.id)
        XCTAssertEqual(unknown.color, "autunno.zucca")
        XCTAssertEqual(SubjectPalette.choice(unknown.color).id, unknown.color)
        XCTAssertEqual(SubjectPalette.choice(unknown.color).name, "Grigio caldo")
        for appearance in ["Light", "Dark", "System"] {
            store.settings.appearance = appearance
            store.settings.theme = "Night"
            XCTAssertEqual(subject.color, "classici.azzurro-polvere")
            XCTAssertEqual(unknown.color, "autunno.zucca")
        }
    }
    func testOldBackupUsesSameImportPathAndNewExportUsesIDs() throws {
        let store = try makeStore()
        let subject = Subject(name: "Programmazione", icon: "terminal", color: "Cielo", weeklyGoal: 8)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let initial = try encoder.encode(Backup(settings: store.settings, subjects: [SubjectRecord(subject)], sessions: []))
        var oldJSON = try JSONSerialization.jsonObject(with: initial) as! [String: Any]
        var subjects = oldJSON["subjects"] as! [[String: Any]]
        subjects[0]["color"] = "Cielo"; oldJSON["subjects"] = subjects
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let old = try decoder.decode(Backup.self, from: JSONSerialization.data(withJSONObject: oldJSON))
        let imported = old.subjects[0].model // Exactly the conversion used by restore().
        store.context.insert(imported); XCTAssertTrue(store.save())
        XCTAssertEqual(imported.id, subject.id); XCTAssertEqual(imported.color, "classici.azzurro-polvere")
        XCTAssertEqual(imported.weeklyGoal, 8); XCTAssertEqual(imported.icon, "terminal")
        let exported = try encoder.encode(Backup(settings: store.settings, subjects: [SubjectRecord(imported)], sessions: []))
        XCTAssertEqual(try decoder.decode(Backup.self, from: exported).subjects[0].color, "classici.azzurro-polvere")
        imported.color = "futuro.colore-ignoto"
        XCTAssertEqual(try decoder.decode(Backup.self, from: encoder.encode(Backup(settings: store.settings, subjects: [SubjectRecord(imported)], sessions: []))).subjects[0].color, "futuro.colore-ignoto")
    }
    func testStartupMigrationBacksUpLegacyDataAndSecondPassDoesNothing() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Study.store")
        let schema = Schema([StudySession.self, Subject.self, StudyExam.self])
        let id: UUID
        do {
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let context = ModelContext(container)
            let subject = Subject(name: "Archivio precedente", icon: "atom", weeklyGoal: 6)
            id = subject.id; subject.color = "Tramonto"; context.insert(subject)
            context.insert(StudySession(start: Date().addingTimeInterval(-3600), end: Date(), duration: 3600, subjectID: id, subjectName: subject.name, mode: "Cronometro", pause: 0))
            try context.save()
        }
        let defaults = UserDefaults(suiteName: "ColorDisk.\(UUID())")!
        let first = try StudyStore(defaults: defaults, archiveURL: url)
        XCTAssertEqual(first.subjects.first?.color, "classici.ocra")
        XCTAssertEqual(first.sessions.first?.subjectID, id)
        let folders = try FileManager.default.contentsOfDirectory(at: directory.appendingPathComponent("Backups"), includingPropertiesForKeys: nil)
        XCTAssertEqual(folders.count, 1)
        let backupContainer = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: folders[0].appendingPathComponent("Study.store"))])
        let backup = ModelContext(backupContainer)
        XCTAssertEqual(try backup.fetch(FetchDescriptor<Subject>()).first?.color, "Tramonto")
        XCTAssertEqual(try backup.fetch(FetchDescriptor<StudySession>()).first?.subjectID, id)
        let second = try StudyStore(defaults: defaults, archiveURL: url)
        XCTAssertEqual(try second.migrateSubjectColorIDs(), 0)
        XCTAssertEqual(second.subjects.first?.id, id)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.appendingPathComponent("Backups").path).count, 1)
        if let path = ProcessInfo.processInfo.environment["KOMOREBI_COLOR_MIGRATION_EVIDENCE"] {
            let out = URL(fileURLWithPath: path, isDirectory: true)
            try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
            let snapshot = try ColorIDMigrationBackup.create(archiveURL: url, preferences: [:])
            try Data(contentsOf: snapshot.appendingPathComponent("Study.store")).write(to: out.appendingPathComponent("migrated-test.store"), options: .atomic)
        }
    }
    func testBackupFailureDoesNotModifyLegacyID() throws {
        let store = try makeStore()
        let subject = Subject(name: "Test"); subject.color = "Rosa"
        store.context.insert(subject); XCTAssertTrue(store.save())
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        XCTAssertThrowsError(try store.migrateSubjectColorIDs(archiveURL: directory.appendingPathComponent("missing.store")))
        XCTAssertEqual(subject.color, "Rosa")
    }
    func testAllAliasesCanonicalAndFutureValuesUntouched() {
        XCTAssertEqual(Set(SubjectColorID.legacyAliases.values).count, 8)
        for (legacy, id) in SubjectColorID.legacyAliases {
            XCTAssertEqual(SubjectColorID.canonical(legacy), id)
            XCTAssertEqual(SubjectColorID.canonical(id), id)
            XCTAssertTrue(SubjectPalette.choices.contains { $0.id == id })
        }
        for id in ["autunno.zucca", "sconosciuto", "#C9748F", "", " CLASSICI.SALVIA "] {
            XCTAssertEqual(SubjectColorID.canonical(id), id)
            XCTAssertEqual(SubjectPalette.choice(id).id, id)
        }
    }
}
