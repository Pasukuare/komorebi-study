import XCTest
@testable import KomorebiStudy

@MainActor final class SidebarTests: XCTestCase {
    func testVisibilityPersistsAcrossReopeningWithoutChangingTimer() throws {
        let name = "SidebarTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let first = try StudyStore(inMemory: true, defaults: defaults)
        XCTAssertTrue(first.settings.showsSidebar)
        first.active = ActiveTimer(start: Date(), target: 1500, subjectName: "Prova isolata", mode: .pomodoro)
        let active = first.active
        first.settings.sidebarIsVisible = false
        XCTAssertEqual(first.active?.id, active?.id)
        let reopened = try StudyStore(inMemory: true, defaults: defaults)
        XCTAssertFalse(reopened.settings.showsSidebar)
        reopened.settings.sidebarIsVisible = true
        let third = try StudyStore(inMemory: true, defaults: defaults)
        XCTAssertTrue(third.settings.showsSidebar)
    }
    func testLegacySettingsDefaultToOpenAndPreserveOtherSettings() throws {
        var settings = UserSettings(); settings.dailyGoal = 5; settings.themeID = "halloween"
        let encoded = try JSONEncoder().encode(settings)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "sidebarIsVisible")
        let decoded = try JSONDecoder().decode(UserSettings.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertTrue(decoded.showsSidebar)
        XCTAssertEqual(decoded.dailyGoal, 5)
        XCTAssertEqual(decoded.themeID, "halloween")
    }
}

extension SidebarTests {
    func testReducedMotionAndDisabledAnimationsMakeSidebarInstant() {
        for mode in ["Off", "Reduced", "Full"] {
            XCTAssertEqual(DesignSystem.SidebarToggle.duration(reduceMotion: true, animations: mode), 0)
            XCTAssertEqual(DesignSystem.SidebarToggle.duration(reduceMotion: false, animations: mode), mode == "Off" ? 0 : 0.25)
        }
    }
}
