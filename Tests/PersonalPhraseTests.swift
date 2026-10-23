import XCTest
import SwiftUI
@testable import KomorebiStudy

@MainActor final class PersonalPhraseTests: XCTestCase {
    override func tearDown() { L10n.language = .italian; super.tearDown() }

    func testOldSettingsAndBlankMessagesRemainNeutral() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(UserSettings())) as? [String: Any])
        json.removeValue(forKey: "personalPhrases")
        var settings = try JSONDecoder().decode(UserSettings.self, from: JSONSerialization.data(withJSONObject: json))
        for slot in PersonalPhraseSlot.allCases { XCTAssertNil(settings.personalPhrase(for: slot)) }
        settings.personalPhrases = ["home": " \n ", "timer": ""]
        XCTAssertNil(settings.personalPhrase(for: .home))
        XCTAssertNil(settings.personalPhrase(for: .timer))
    }
    func testSettingsPersistAndBackupWithoutTranslatingOrChangingActiveTimer() throws {
        let suite = "PersonalPhrases.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = try StudyStore(inMemory: true, defaults: defaults)
        store.active = ActiveTimer(start: Date(), target: 1500, subjectName: "Test", mode: .pomodoro)
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let timerBefore = try encoder.encode(store.active)
        store.settings.personalPhrases = ["home": "Una cosa alla volta ✨", "timer": "Keep going **your way**", "dailyGoal": "Il mio obiettivo", "menu": "Un passo"]
        let restored = try JSONDecoder().decode(UserSettings.self, from: XCTUnwrap(defaults.data(forKey: "settings")))
        XCTAssertEqual(restored.personalPhrases, store.settings.personalPhrases)
        for language in AppLanguage.allCases {
            L10n.language = language
            XCTAssertEqual(restored.personalPhrase(for: .home), "Una cosa alla volta ✨")
            XCTAssertEqual(restored.personalPhrase(for: .timer), "Keep going **your way**")
        }
        let backup = Backup(settings: store.settings, subjects: [], sessions: [])
        let decoded = try JSONDecoder().decode(Backup.self, from: encoder.encode(backup))
        XCTAssertEqual(decoded.settings.personalPhrases, store.settings.personalPhrases)
        XCTAssertEqual(try encoder.encode(store.active), timerBefore)
    }
    func testLongPersonalMessagesRenderWithinAvailableWidthInEveryTheme() throws {
        let defaults = UserDefaults(suiteName: "PersonalPhrases.Render.\(UUID())")!
        let store = try StudyStore(inMemory: true, defaults: defaults)
        store.settings.personalPhrases = Dictionary(uniqueKeysWithValues: PersonalPhraseSlot.allCases.map { ($0.rawValue, String(repeating: "La mia frase personale, anche molto lunga. ", count: 30)) })
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                for slot in PersonalPhraseSlot.allCases {
                    let view = PersonalPhrase(slot: slot).frame(width: DesignSystem.PreservedGeometry.points240)
                        .environmentObject(store).environment(\.studyTheme, package.resolve(mode: mode))
                    let image = try XCTUnwrap(ImageRenderer(content: view).nsImage)
                    XCTAssertEqual(image.size.width, DesignSystem.PreservedGeometry.points240)
                    XCTAssertLessThan(image.size.height, DesignSystem.PreservedGeometry.points132)
                }
            }
        }
    }
}
