import XCTest
import SwiftUI
import AppKit
import SwiftData
@testable import KomorebiStudy

@MainActor final class SubjectWorkflowRenderTests: XCTestCase {
    func testWorkflowScreensUseIsolatedFixturesInAllThemes() throws {
        guard let output = ProcessInfo.processInfo.environment["KOMOREBI_WORKFLOW_REVIEW"] else { return }
        try ThemeFonts.register()
        let store = try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "WorkflowReview.\(UUID())")!)
        store.settings.onboarded = true; store.settings.animations = "Off"
        store.settings.dismissedThemeCampaigns = ["halloween-" + String(Calendar.current.component(.year, from: store.now))]
        let a = store.subjects.first!; a.name = "Teoria dei Sistemi"
        let b = Subject(name: "Misure Elettroniche", color: "inverno.brina"); b.isCompleted = true; b.grade = "18"
        let c = Subject(name: "Tesi", color: "autunno.zucca")
        store.context.insert(b); store.context.insert(c)
        let end = store.day.start.addingTimeInterval(-3600)
        let history = StudySession(start: end.addingTimeInterval(-1800), end: end, duration: 1800, subjectID: b.id, subjectName: b.name, mode: "Pomodoro", pause: 0)
        b.completionVersion = nil
        SubjectCompletionMigration.apply(subjects: [b], sessions: [history])
        store.context.insert(history)
        store.context.insert(StudySession(start: store.day.start, end: store.day.start.addingTimeInterval(1200), duration: 1200, subjectID: a.id, subjectName: a.name, mode: "Pomodoro", pause: 0))
        store.context.insert(StudyExam(title: b.name, date: store.now.addingTimeInterval(86400), subjectID: b.id))
        store.context.insert(StudyExam(title: a.name, date: store.now.addingTimeInterval(5*86400), subjectID: a.id))
        store.settings.lastSubject = b.id
        if ProcessInfo.processInfo.environment["KOMOREBI_PROJECTION_HOME"] != nil {
            let prep = Calendar.current.date(byAdding: .day, value: -10, to: store.now)!
            for exam in try store.context.fetch(FetchDescriptor<StudyExam>()) where exam.subjectID == a.id {
                exam.requiredStudyHours = 150; exam.preparationStart = prep
            }
        }
        XCTAssertTrue(store.save())
        let fixtureEncoder = JSONEncoder(); fixtureEncoder.dateEncodingStrategy = .iso8601; fixtureEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try fixtureEncoder.encode(Backup(settings: store.settings, subjects: store.subjects.map(SubjectRecord.init), sessions: store.sessions.map(SessionRecord.init), exams: store.exams.map(ExamRecord.init)))
            .write(to: URL(fileURLWithPath: output).appendingPathComponent("Fixture-materie.json"))
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                store.settings.themeID = package.id
                let theme = package.resolve(mode: mode)
                func capture<V: View>(_ view: V, name: String, width: CGFloat = 920, height: CGFloat = 650) throws {
                    let host = NSHostingView(rootView: view.frame(width: width, height: height)
                        .environmentObject(store).environment(\.studyTheme, theme)
                        .environment(\.colorScheme, mode == .dark ? .dark : .light)
                        .environment(\.komorebiMotion, "Off")
                        .foregroundStyle(theme.palette.textPrimary).background(theme.palette.background)
                        .buttonStyle(ResponsiveButtonStyle()).textFieldStyle(StudyTextFieldStyle()).toggleStyle(StudyToggleStyle()))
                    host.appearance = NSAppearance(named: mode == .dark ? .darkAqua : .aqua)
                    let window = NSWindow(contentRect: CGRect(x: 0,y: 0,width: width,height: height), styleMask: [.borderless], backing: .buffered, defer: false)
                    window.contentView = host; host.frame = window.contentView!.bounds
                    host.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date().addingTimeInterval(0.06)); host.layoutSubtreeIfNeeded()
                    let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: output).appendingPathComponent("\(name)-\(package.id)-\(mode.rawValue).png"))
                    window.contentView = nil
                }
                try capture(OverviewView(openTimer: {}, openCalendar: {}, openThemeSettings: {}), name: "home", height: ProcessInfo.processInfo.environment["KOMOREBI_PROJECTION_HOME"] == nil ? 1000 : 1700)
                try capture(HomeView(), name: "timer")
                try capture(MenuPanel(), name: "menu", width: 350)
                try capture(CalendarView(), name: "calendario")
                try capture(HistoryView(), name: "cronologia")
                try capture(StatisticsView(), name: "statistiche")
                try capture(SessionEditor(session: history), name: "modifica-sessione", width: 520)
                try capture(ExamEditor(exam: nil, initialDate: store.now), name: "nuovo-esame", width: 520)
                try capture(SubjectsView(), name: "sezioni-materie", height: 1700)
                let states = store.subjects.map { ($0, $0.isCompleted) }
                for (subject, _) in states { subject.isCompleted = true }; XCTAssertTrue(store.save())
                try capture(OverviewView(openTimer: {}, openCalendar: {}, openThemeSettings: {}), name: "home-zero-attive", height: 1000)
                try capture(HomeView(), name: "timer-zero-attive")
                try capture(MenuPanel(), name: "menu-zero-attive", width: 350)
                for (subject, completed) in states { subject.isCompleted = completed }; XCTAssertTrue(store.save())
            }
        }
        for subject in store.subjects { subject.isCompleted = true }; XCTAssertTrue(store.save())
        let manifest = ["active": store.activeSubjectChoices.map { $0.1 }, "consultation": store.consultationSubjectChoices.map { $0.1 }, "history": store.historySubjectChoices.map { $0.1 }]
        try JSONEncoder().encode(manifest).write(to: URL(fileURLWithPath: output).appendingPathComponent("zero-attive.json"))
    }
}
