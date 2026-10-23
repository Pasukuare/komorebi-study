import XCTest
import SwiftUI
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
                XCTAssertEqual(subject.name, original)
            }
        }
    }

}
