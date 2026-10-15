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
