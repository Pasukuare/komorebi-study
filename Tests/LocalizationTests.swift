import XCTest
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class LocalizationTests: XCTestCase {
    override func tearDown() { L10n.language = .italian; super.tearDown() }

    private struct LiveLanguageProbe: View {
        @ObservedObject private var language = AppLocalization.shared
        @State private var identity = UUID()
        let sample: (String, UUID) -> Void
        var body: some View {
            let value = L10n.tr("Impostazioni")
            let _ = sample(value, identity)
            Text(value)
        }
    }
    func testLeafControlsRefreshOnLanguageChangeWithoutLosingState() {
        L10n.language = .italian
        var samples: [(String, UUID)] = []
        let host = NSHostingView(rootView: LiveLanguageProbe { samples.append(($0, $1)) })
        host.frame = NSRect(x: 0, y: 0, width: 200, height: 60)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.03))
        let initial = samples.last
        XCTAssertEqual(initial?.0, "Impostazioni")
        L10n.language = .english
        RunLoop.main.run(until: Date().addingTimeInterval(0.03))
        host.layoutSubtreeIfNeeded()
        XCTAssertEqual(samples.last?.0, "Settings")
        XCTAssertEqual(samples.last?.1, initial?.1, "Changing language must preserve local State")
        window.contentView = nil
    }
    func testLegacySettingsAndUnknownLanguageRemainCompatible() throws {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(UserSettings())) as? [String: Any])
        object.removeValue(forKey: "language")
        let legacy = try JSONDecoder().decode(UserSettings.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(legacy.appLanguage, .italian)
        var future = legacy; future.language = "future-language"
        XCTAssertEqual(future.appLanguage, .italian)
        XCTAssertEqual(future.language, "future-language")
    }
    func testLanguagePersistsWithoutChangingActiveTimerOrUserContent() throws {
        let suite = "LanguageTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = try StudyStore(inMemory: true, defaults: defaults)
        let subject = Subject(name: "Studio", color: "autunno.zucca")
        store.context.insert(subject); store.save()
        let session = StudySession(start: Date().addingTimeInterval(-600), end: Date(), duration: 600, subjectID: subject.id, subjectName: "Studio", mode: TimerMode.stopwatch.rawValue, pause: 0, note: "La mia nota")
        store.context.insert(session); store.save()
        store.active = ActiveTimer(start: Date().addingTimeInterval(-20), target: nil, subjectName: "Studio", mode: .stopwatch)
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(XCTUnwrap(store.active))
        store.settings.language = "en"
        XCTAssertEqual(L10n.language, .english)
        XCTAssertEqual(store.actionTitle, "Pause")
        XCTAssertEqual(try encoder.encode(XCTUnwrap(store.active)), before)
        XCTAssertEqual(subject.name, "Studio"); XCTAssertEqual(subject.color, "autunno.zucca")
        XCTAssertEqual(session.note, "La mia nota"); XCTAssertEqual(session.timerMode, "Cronometro")
        let saved = try JSONDecoder().decode(UserSettings.self, from: XCTUnwrap(defaults.data(forKey: "settings")))
        XCTAssertEqual(saved.appLanguage, .english)
        store.settings.language = "it"
        XCTAssertEqual(store.actionTitle, "Sospendi")
    }
    func testEnglishCatalogCoversScreensEnumsAndStaticPickerMetadata() {
        L10n.language = .english
        for key in Page.allCases.map(\.rawValue) + StudyPeriod.allCases.map(\.rawValue) + TimerMode.allCases.map(\.rawValue) {
            if !["Home", "Timer", "Pomodoro"].contains(key) { XCTAssertNotEqual(L10n.tr(key), key, key) }
        }
        for icon in SubjectIcons.all { XCTAssertTrue(L10n.englishKeys.contains(icon.name), icon.name) }
        for category in SubjectIcons.categories { XCTAssertTrue(L10n.englishKeys.contains(category.name)) }
        for group in SubjectColorGroup.allCases { XCTAssertFalse(group.title.isEmpty) }
        for package in ThemeRegistry.packages {
            XCTAssertTrue(L10n.englishKeys.contains(package.subtitle))
            for option in package.options {
                XCTAssertTrue(L10n.englishKeys.contains(option.title)); XCTAssertTrue(L10n.englishKeys.contains(option.detail))
            }
            for color in package.resolve(mode: .dark).subjectColors { XCTAssertTrue(L10n.englishKeys.contains(color.name), color.name) }
        }
        XCTAssertEqual(TimerMode.stopwatch.rawValue, "Cronometro")
        XCTAssertEqual(TimerMode.stopwatch.displayName, "Stopwatch")
        XCTAssertEqual(TimerMode.displayName(for: "future-mode"), "future-mode")
    }
    func testFormattingPluralDatesAndAppErrorsFollowSelectedLanguage() {
        L10n.language = .english
        XCTAssertEqual(L10n.count(1, singular: "%@ sessione", plural: "%@ sessioni"), "1 session")
        XCTAssertEqual(L10n.count(2, singular: "%@ sessione", plural: "%@ sessioni"), "2 sessions")
        XCTAssertEqual(L10n.tr("Pausa breve: %@ · lunga ogni %@ sessioni", "5m", "4"), "Short break: 5m · long break every 4 sessions")
        XCTAssertTrue(L10n.errorMessage(CocoaError(.fileReadCorruptFile)).hasPrefix("The file is invalid or damaged."))
        XCTAssertEqual(L10n.message("Timer sospeso durante lo stop."), "Timer paused during sleep.")
        XCTAssertEqual(L10n.locale.language.languageCode?.identifier, "en")
        XCTAssertEqual(L10n.displayCalendar.shortStandaloneWeekdaySymbols[0], "Sun")
        L10n.language = .italian
        XCTAssertEqual(L10n.count(1, singular: "%@ sessione", plural: "%@ sessioni"), "1 sessione")
        XCTAssertEqual(L10n.message("Timer paused during sleep."), "Timer sospeso durante lo stop.")
        XCTAssertEqual(L10n.locale.language.languageCode?.identifier, "it")
    }
    func testNativeMenuTranslationPreservesActionsShortcutsAndUnrelatedTitles() {
        let menu = NSMenu(title: "Test")
        let copy = NSMenuItem(title: "Copia", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        copy.keyEquivalentModifierMask = [.command]
        let userTitle = NSMenuItem(title: "Copia", action: nil, keyEquivalent: "")
        menu.addItem(copy); menu.addItem(userTitle)
        L10n.language = .english; NativeAppLanguageMenus.translate(menu)
        XCTAssertEqual(copy.title, "Copy"); XCTAssertEqual(userTitle.title, "Copia")
        XCTAssertEqual(copy.action, #selector(NSText.copy(_:)))
        XCTAssertEqual(copy.keyEquivalent, "c"); XCTAssertEqual(copy.keyEquivalentModifierMask, [.command])
        L10n.language = .italian; NativeAppLanguageMenus.translate(menu)
        XCTAssertEqual(copy.title, "Copia")
    }
    func testNeutralThemeCopyDoesNotRestoreEncouragementFromLegacyOptions() {
        L10n.language = .english
        for package in ThemeRegistry.packages {
            for options in [[:], [ThemeOptionID.themedText: true]] {
                let theme = package.resolve(mode: .dark, options: options)
                XCTAssertFalse(package.options.contains { $0.id == ThemeOptionID.themedText })
                XCTAssertEqual(theme.copy.streak(1), "Streak: 1 day")
                XCTAssertEqual(theme.copy.streak(7), "Streak: 7 days")
                XCTAssertFalse(theme.copy.text(.greeting, fallback: "Nessuna sessione attiva").contains("step"))
            }
        }
    }
    func testEnglishScreensRenderInBothThemesAndModes() throws {
        try ThemeFonts.register()
        let store = try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "EnglishRender.\(UUID())")!)
        store.settings.language = "en"
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let screens: [(String, AnyView)] = [
                    ("Home", AnyView(OverviewView(openTimer: {}, openCalendar: {}, openThemeSettings: {}))),
                    ("Timer", AnyView(HomeView())), ("Settings", AnyView(SettingsView(revealTheme: .constant(false)))),
                    ("Subjects", AnyView(SubjectsView())), ("History", AnyView(HistoryView())),
                    ("Calendar", AnyView(CalendarView())), ("Statistics", AnyView(StatisticsView())),
                    ("Menu", AnyView(MenuPanel()))
                ]
                for (name, screen) in screens {
                    let content = screen.environmentObject(store).environment(\.locale, AppLanguage.english.locale)
                        .environment(\.studyTheme, package.resolve(mode: mode))
                        .frame(width: 920, height: 650)
                    let renderer = ImageRenderer(content: content)
                    renderer.scale = 1
                    XCTAssertNotNil(renderer.nsImage, "\(package.id) / \(mode) / \(name)")
                }
            }
        }
    }
}
