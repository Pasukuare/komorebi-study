import XCTest
import SwiftUI
import SwiftData
@testable import KomorebiStudy

@MainActor final class SubjectEditorTests: XCTestCase {
    func testEditingDraftDoesNotChangeSubjectUntilSaved() {
        let subject = Subject(name: "Originale", icon: "book", weeklyGoal: 5)
        let id = subject.id
        var draft = SubjectEditDraft(subject: subject)
        draft.name = "  Analisi II  "
        draft.icon = "atom"
        draft.goal = 12
        XCTAssertEqual(subject.name, "Originale", "Discarding the draft must leave the model unchanged")
        XCTAssertEqual(subject.weeklyGoal, 5)
        draft.apply(to: subject)
        XCTAssertEqual(subject.id, id)
        XCTAssertEqual(subject.name, "Analisi II")
        XCTAssertEqual(subject.icon, "atom")
        XCTAssertEqual(subject.weeklyGoal, 12)
    }
    func testValidationPreservesExistingGoalRules() {
        let subject = Subject(name: "Originale")
        var draft = SubjectEditDraft(subject: subject)
        draft.name = " \n "
        XCTAssertFalse(draft.isValid)
        draft.name = "Analisi"
        XCTAssertTrue(draft.isValid)
        draft.goal = .infinity
        draft.apply(to: subject)
        XCTAssertEqual(subject.weeklyGoal, 5)
        draft.goal = 200
        draft.apply(to: subject)
        XCTAssertEqual(subject.weeklyGoal, 168)
    }
    func testEditorRendersInBothThemesAndModesWithoutMutatingSubject() throws {
        let defaults = UserDefaults(suiteName: "SubjectEditorTests.\(UUID().uuidString)")!
        let store = try StudyStore(inMemory: true, defaults: defaults)
        let subject = Subject(name: "Materia con un nome lungo per verificare il pannello di modifica")
        subject.isCompleted = true; subject.grade = "30 e lode"
        let original = subject.name
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let editor = SubjectEditor(subject: subject)
                    .environmentObject(store)
                    .environment(\.studyTheme, package.resolve(mode: mode))
                let renderer = ImageRenderer(content: editor)
                let image = try XCTUnwrap(renderer.nsImage)
                XCTAssertEqual(image.size.width, DesignSystem.PreservedGeometry.points480)
                XCTAssertGreaterThan(image.size.height, 0)
                XCTAssertLessThanOrEqual(image.size.height, DesignSystem.PreservedGeometry.points650)
                XCTAssertEqual(subject.name, original)
            }
        }
    }

    func testCompletionAndOptionalGradeSurviveSaveReopenAndBackup() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let schema = Schema([Subject.self])
        let config = ModelConfiguration(schema: schema, url: folder.appendingPathComponent("Test.store"))
        let id: UUID
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            let subject = Subject(name: "Analisi")
            id = subject.id
            context.insert(subject)
            var draft = SubjectEditDraft(subject: subject)
            draft.completed = true; draft.grade = " 30 e lode "
            XCTAssertFalse(subject.isCompleted)
            XCTAssertNil(subject.grade)
            draft.apply(to: subject)
            try context.save()
        }
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let subject = try XCTUnwrap(context.fetch(FetchDescriptor<Subject>()).first)
        XCTAssertEqual(subject.id, id)
        XCTAssertTrue(subject.isCompleted)
        XCTAssertEqual(subject.grade, "30 e lode")
        let backup = try JSONDecoder().decode(SubjectRecord.self, from: JSONEncoder().encode(SubjectRecord(subject)))
        XCTAssertTrue(backup.model.isCompleted)
        XCTAssertEqual(backup.model.grade, "30 e lode")
        var draft = SubjectEditDraft(subject: subject)
        draft.completed = false
        draft.apply(to: subject)
        XCTAssertFalse(subject.isCompleted)
        XCTAssertEqual(subject.grade, "30 e lode", "Reopening a subject must not silently erase its grade")
        draft.completed = true; draft.grade = " \n "
        draft.apply(to: subject)
        XCTAssertNil(subject.grade)
    }

    func testLegacySubjectBackupWithoutCompletionFieldsStillDecodes() throws {
        let subject = Subject(name: "Materia precedente")
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(SubjectRecord(subject))) as? [String: Any])
        object.removeValue(forKey: "completed"); object.removeValue(forKey: "grade")
        let record = try JSONDecoder().decode(SubjectRecord.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(record.model.id, subject.id)
        XCTAssertFalse(record.model.isCompleted)
        XCTAssertNil(record.model.grade)
    }

}

/// Frozen pre-completion schema: migration tests must not create the old store with the new model.
private enum SubjectBeforeCompletion {
    @Model final class Subject {
        @Attribute(.unique) var id: UUID
        var name: String
        var icon: String
        var color: String
        var weeklyGoal: Double
        init(id: UUID) {
            self.id = id; name = "Materia precedente"; icon = "book"
            color = "classici.salvia"; weeklyGoal = 5
        }
    }
}

extension SubjectEditorTests {
    func testExistingSubjectStoreMigratesWithoutLosingIdentity() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Study.store")
        let id = UUID()
        do {
            let schema = Schema([SubjectBeforeCompletion.Subject.self])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let context = ModelContext(container)
            context.insert(SubjectBeforeCompletion.Subject(id: id))
            try context.save()
        }
        let schema = Schema([Subject.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = ModelContext(container)
        let subject = try XCTUnwrap(context.fetch(FetchDescriptor<Subject>()).first)
        XCTAssertEqual(subject.id, id)
        XCTAssertEqual(subject.name, "Materia precedente")
        XCTAssertEqual(subject.weeklyGoal, 5)
        XCTAssertFalse(subject.isCompleted)
        XCTAssertNil(subject.grade)
        subject.isCompleted = true; subject.grade = "28/30"
        try context.save()
    }
}
