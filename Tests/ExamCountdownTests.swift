import XCTest
import SwiftUI
@testable import KomorebiStudy

@MainActor final class ExamCountdownTests: XCTestCase {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }
    func date(_ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }
    override func tearDown() { L10n.language = .italian; super.tearDown() }

    func testNearestUsesCalendarDatesAndIgnoresPastExamsWithoutMutatingThem() throws {
        let today = date(10, 24, 15)
        let past = StudyExam(title: "Passato", date: date(10, 23))
        let next = StudyExam(title: "Analisi", date: date(10, 28))
        let later = StudyExam(title: "Fisica", date: date(12, 1))
        let summary = try XCTUnwrap(NextExamCountdown.nearest(in: [later, past, next], at: today, calendar: calendar))
        XCTAssertEqual(summary.id, next.id)
        XCTAssertEqual(summary.days, 4)
        XCTAssertEqual(summary.title, "Analisi")
        XCTAssertNil(NextExamCountdown.nearest(in: [], at: today, calendar: calendar))
        XCTAssertNil(NextExamCountdown.nearest(in: [past], at: today, calendar: calendar))
        XCTAssertEqual(next.date, date(10, 28))
    }
    func testTodayTomorrowAndDSTBoundaries() throws {
        for (today, examDate, expected) in [(date(10,24,15), date(10,24), 0),
                                           (date(10,24,15), date(10,25), 1),
                                           (date(10,24,15), date(10,26), 2),
                                           (date(3,28,15), date(3,30), 2)] {
            let exam = StudyExam(title: "Esame", date: examDate)
            let result = try XCTUnwrap(NextExamCountdown.nearest(in: [exam], at: today, calendar: calendar))
            XCTAssertEqual(result.days, expected)
        }
        let exam = StudyExam(title: "Con orario", date: date(10,24,9), hasTime: true)
        XCTAssertEqual(NextExamCountdown.nearest(in: [exam], at: date(10,24,15), calendar: calendar)?.days, 0)
    }
    func testSameDateHasStableTieBreakAndTextIsLocalized() throws {
        let a = StudyExam(title: "A", date: date(10,26))
        let b = StudyExam(title: "B", date: a.date)
        let first = try XCTUnwrap(NextExamCountdown.nearest(in: [a,b], at: date(10,24), calendar: calendar))
        XCTAssertEqual(first.id, NextExamCountdown.nearest(in: [b,a], at: date(10,24), calendar: calendar)?.id)
        L10n.language = .italian; XCTAssertEqual(first.countdownText, "Esame tra 2 giorni")
        L10n.language = .english; XCTAssertEqual(first.countdownText, "Exam in 2 days")
        XCTAssertEqual(first.title, first.id == a.id ? "A" : "B")
    }
    func testHeaderRendersWithLongExamNameInEveryThemeAndLanguage() throws {
        let exam = StudyExam(title: String(repeating: "Un nome molto lungo per la materia ", count: 8), date: date(10,28))
        for language in AppLanguage.allCases {
            L10n.language = language
            for package in ThemeRegistry.packages {
                for mode in ThemeMode.allCases {
                    for streak in [0, 7] {
                        let view = HomeExamCountdown(exams: [exam], date: date(10,24), streak: streak)
                            .frame(width: DesignSystem.PreservedGeometry.points240)
                            .environment(\.studyTheme, package.resolve(mode: mode))
                        let image = try XCTUnwrap(ImageRenderer(content: view).nsImage)
                        XCTAssertEqual(image.size.width, DesignSystem.PreservedGeometry.points240)
                        XCTAssertLessThan(image.size.height, DesignSystem.PreservedGeometry.points132)
                    }
                }
            }
        }
    }
}

extension ExamCountdownTests {
    func testLinkedExamCaseAliasUsesSubjectSpellingWithoutChangingStoredTitle() throws {
        let store = try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "ExamCase.\(UUID())")!)
        let subject = Subject(name: "Teoria dei Sistemi")
        store.context.insert(subject)
        let exam = StudyExam(title: "Teoria Dei Sistemi", date: date(11,20), subjectID: subject.id)
        store.context.insert(exam); XCTAssertTrue(store.save())
        XCTAssertEqual(store.examDisplayTitle(exam), "Teoria dei Sistemi")
        let next = try XCTUnwrap(NextExamCountdown.nearest(in: [exam], at: date(10,24), titleForExam: store.examDisplayTitle))
        XCTAssertEqual(next.title, "Teoria dei Sistemi")
        XCTAssertEqual(exam.title, "Teoria Dei Sistemi", "Display must not rewrite the saved exam title")
        subject.name = "teoria dei sistemi"; XCTAssertTrue(store.save())
        XCTAssertEqual(store.examDisplayTitle(exam), subject.name)
        XCTAssertEqual(exam.title, "Teoria Dei Sistemi")
    }
    func testDistinctExamTitlesAndUnlinkedExamsRemainExactlyAsWritten() {
        let custom = StudyExam(title: "Parziale di Teoria Dei Sistemi", date: Date())
        XCTAssertEqual(custom.displayTitle(linkedSubjectName: "Teoria dei Sistemi"), custom.title)
        let unlinked = StudyExam(title: "Teoria Dei Sistemi", date: Date())
        XCTAssertEqual(unlinked.displayTitle(linkedSubjectName: nil), unlinked.title)
        let accent = StudyExam(title: "Fisicà", date: Date())
        XCTAssertEqual(accent.displayTitle(linkedSubjectName: "Fisica"), "Fisicà")
    }
}
