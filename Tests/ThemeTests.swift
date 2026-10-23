import XCTest
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class ThemeTests: XCTestCase {
    func testLegacySettingsDecodeWithoutThemeAndKeepModeAndLandscape() throws {
        var old = UserSettings(); old.appearance = "Dark"; old.theme = "Night"
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as! [String: Any]
        json.removeValue(forKey: "themeID"); json.removeValue(forKey: "themeOptions")
        let decoded = try JSONDecoder().decode(UserSettings.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.themeID)
        XCTAssertEqual(decoded.landscape, "Night")
        XCTAssertEqual(decoded.appearance, "Dark")
        XCTAssertEqual(ThemeRegistry.resolve(settings: decoded, system: .light).mode, .dark)
        XCTAssertEqual(ThemeRegistry.package(decoded.themeID).id, ThemeRegistry.defaultPackage.id)
    }
    func testThemeModeAndLandscapeAreIndependent() {
        var settings = UserSettings()
        settings.themeID = ThemeRegistry.defaultPackage.id
        settings.landscape = "Sunset"
        for preference in ["Light", "Dark", "System"] {
            settings.appearance = preference
            for system in [ColorScheme.light, .dark] {
                let result = ThemeRegistry.resolve(settings: settings, system: system)
                XCTAssertEqual(result.package.id, settings.themeID)
                XCTAssertEqual(result.mode, preference == "Light" ? .light : preference == "Dark" ? .dark : system == .dark ? .dark : .light)
                XCTAssertEqual(settings.landscape, "Sunset")
            }
        }
        settings.themeID = "future-theme"
        _ = ThemeRegistry.resolve(settings: settings, system: .dark)
        XCTAssertEqual(settings.themeID, "future-theme", "Unknown preferences must not be overwritten by the fallback")
        XCTAssertEqual(settings.appearance, "System")
    }
    func testThemePackageDeclaresBehaviorWithoutOfferingFutureFeatures() {
        XCTAssertEqual(ThemeRegistry.packages.count, 2)
        let package = ThemeRegistry.defaultPackage
        XCTAssertEqual(package.behavior.initialColorTab, .currentSeason)
        XCTAssertFalse(package.behavior.replacesLandscapes)
        XCTAssertTrue(package.behavior.supportsSeason)
        XCTAssertNil(package.behavior.suggestionWindow)
        XCTAssertEqual(package.options.map(\.id), [ThemeOptionID.followSeason])
        XCTAssertTrue(package.copy.overrides.isEmpty)
        XCTAssertFalse(package.name.isEmpty); XCTAssertFalse(package.subtitle.isEmpty)
    }
    func testEveryPaletteTokenAndSubjectColorMatchesBaselineInBothModes() {
        for mode in ThemeMode.allCases {
            let resolved = ThemeRegistry.defaultPackage.resolve(mode: mode)
            let colors: [(Color, Color)] = [
                (resolved.palette.background, DesignSystem.Palette.background),
                (resolved.palette.surface, DesignSystem.Palette.surface),
                (resolved.palette.elevatedSurface, DesignSystem.Palette.elevatedSurface),
                (resolved.palette.border, DesignSystem.Palette.border),
                (resolved.palette.textPrimary, DesignSystem.Palette.textPrimary),
                (resolved.palette.textSecondary, DesignSystem.Palette.textSecondary),
                (resolved.palette.textTertiary, DesignSystem.Palette.textTertiary),
                (resolved.palette.accent, DesignSystem.Palette.accent),
                (resolved.palette.accentHover, DesignSystem.Palette.accentHover),
                (resolved.palette.accentSurface, DesignSystem.Palette.accentSurface),
                (resolved.palette.success, DesignSystem.Palette.success),
                (resolved.palette.successSurface, DesignSystem.Palette.successSurface),
                (resolved.palette.warning, DesignSystem.Palette.warning),
                (resolved.palette.warningSurface, DesignSystem.Palette.warningSurface),
                (resolved.palette.error, DesignSystem.Palette.error),
                (resolved.palette.errorSurface, DesignSystem.Palette.errorSurface),
                (resolved.palette.interval, DesignSystem.Palette.interval),
                (resolved.palette.action, DesignSystem.Palette.action),
                (resolved.palette.actionHover, DesignSystem.Palette.actionHover),
                (resolved.palette.onAction, DesignSystem.Palette.onAction),
                (resolved.palette.light, DesignSystem.Palette.light),
                (resolved.palette.spotlight, DesignSystem.Palette.light),
                (resolved.palette.hill, DesignSystem.Palette.hill),
                (resolved.palette.timerDivider, DesignSystem.Palette.timerDivider),
                (resolved.palette.timerBorder, DesignSystem.Palette.timerBorder),
                (resolved.palette.timerTrack, DesignSystem.Palette.timerTrack),
                (resolved.palette.timerGradientStart, DesignSystem.Palette.timerGradientStart),
                (resolved.palette.timerGradientEnd, DesignSystem.Palette.timerGradientEnd),
                (resolved.appearance.amberInk, DesignSystem.PreservedAppearance.amberInk),
                (resolved.shadows.medium.color, DesignSystem.Shadows.medium.color)]
            NSAppearance(named: mode == .dark ? .darkAqua : .aqua)!.performAsCurrentDrawingAppearance {
                for (actual, expected) in colors { assertColor(actual, expected) }
                for old in SubjectPalette.choices { assertColor(resolved.subjectColor(old.id), old.ink) }
            }
            XCTAssertEqual(resolved.typography.timerDigits, DesignSystem.Typography.timerDigits)
            XCTAssertEqual(resolved.typography.body, DesignSystem.Typography.body)
            XCTAssertEqual(resolved.preservedTypography.menuWordmark, DesignSystem.PreservedTypography.menuWordmark)
            XCTAssertEqual(resolved.decoration.hillCount, DesignSystem.PreservedDecoration.hillCount)
            XCTAssertEqual(resolved.decoration.particleCount, DesignSystem.PreservedDecoration.particleCount)
            XCTAssertEqual(resolved.decoration.parallax, DesignSystem.PreservedDecoration.parallax)
            XCTAssertEqual(resolved.copy.streak(7), "7 giorni di costanza")
            XCTAssertEqual(resolved.subjectChoice("futura.ignota").id, "futura.ignota")
            assertColor(resolved.subjectColor("futura.ignota"), resolved.subjectColor(SubjectColorID.neutralID))
        }
    }
    func testResolvedVariantsCanOverrideTokensWithoutChangingSemanticIDs() {
        var alternate = ThemeRegistry.defaultPackage
        alternate.dark.palette.accent = .orange
        alternate.copy.overrides[.timerSubtitle] = "Una luce diversa."
        let light = alternate.resolve(mode: .light), dark = alternate.resolve(mode: .dark)
        XCTAssertNotEqual(light.palette.accent, dark.palette.accent)
        XCTAssertEqual(light.copy.text(.timerSubtitle, fallback: "Fallback"), "Una luce diversa.")
        XCTAssertEqual(dark.subjectChoice("Cielo").id, "classici.azzurro-polvere")
        XCTAssertEqual(light.subjectColors.map(\.id), dark.subjectColors.map(\.id))
    }
    func testSettingsPersistWithoutChangingActiveTimerOrSubjects() throws {
        let suite = "KomorebiTests.Theme.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = try StudyStore(inMemory: true, defaults: defaults)
        store.settings.onboarded = true
        store.start()
        let active = try XCTUnwrap(store.active)
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let timerBefore = try encoder.encode(active)
        let subjectIDs = store.subjects.map { ($0.id, $0.color) }
        store.settings.themeID = ThemeRegistry.defaultPackage.id
        store.settings.appearance = "Dark"
        store.settings.landscape = "Rain"
        store.settings.themeOptions = [ThemeRegistry.defaultPackage.id: [:]]
        XCTAssertEqual(try encoder.encode(XCTUnwrap(store.active)), timerBefore)
        for (index, subject) in store.subjects.enumerated() {
            XCTAssertEqual(subject.id, subjectIDs[index].0); XCTAssertEqual(subject.color, subjectIDs[index].1)
        }
        let reopened = try StudyStore(inMemory: true, defaults: defaults)
        XCTAssertEqual(reopened.settings.themeID, ThemeRegistry.defaultPackage.id)
        XCTAssertEqual(reopened.settings.appearance, "Dark")
        XCTAssertEqual(reopened.settings.landscape, "Rain")
        XCTAssertEqual(reopened.settings.themeOptions, store.settings.themeOptions)
    }
    func testTransitionRespectsReducedMotionAndOff() {
        XCTAssertEqual(ThemeTransition.duration(reduceMotion: false, animations: "Full"), 0.3)
        XCTAssertEqual(ThemeTransition.duration(reduceMotion: false, animations: "Reduced"), 0.3)
        XCTAssertEqual(ThemeTransition.duration(reduceMotion: true, animations: "Full"), 0)
        XCTAssertEqual(ThemeTransition.duration(reduceMotion: false, animations: "Off"), 0)
    }
    private func assertColor(_ actual: Color, _ expected: Color, file: StaticString = #filePath, line: UInt = #line) {
        let a = NSColor(actual).usingColorSpace(.sRGB)!, b = NSColor(expected).usingColorSpace(.sRGB)!
        for (x, y) in zip([a.redComponent, a.greenComponent, a.blueComponent, a.alphaComponent], [b.redComponent, b.greenComponent, b.blueComponent, b.alphaComponent]) {
            XCTAssertEqual(x, y, accuracy: 0.000001, file: file, line: line)
        }
    }
}
