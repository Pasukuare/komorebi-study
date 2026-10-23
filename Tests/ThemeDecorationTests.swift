import XCTest
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class ThemeDecorationTests: XCTestCase {
    func testDefaultsAndCopyOnlyAffectRequestedOptionalContent() {
        let package = HalloweenTheme.package
        XCTAssertEqual(package.options.map(\.id), [ThemeOptionID.decorations, ThemeOptionID.themedText])
        let standard = package.resolve(mode: .dark)
        XCTAssertTrue(standard.decorationsEnabled)
        XCTAssertEqual(standard.copy.text(.timerSubtitle, fallback: "Standard"), "Standard")
        let themed = package.resolve(mode: .dark, options: [ThemeOptionID.themedText: true])
        XCTAssertEqual(themed.copy.text(.timerSubtitle, fallback: "Standard"), "La notte è lunga, una cosa alla volta.")
        XCTAssertEqual(themed.copy.streak(1), "1 notte di fila")
        XCTAssertEqual(themed.copy.streak(7), "7 notti di fila")
        XCTAssertEqual(themed.copy.streak(0), "0 notti di fila")
        XCTAssertEqual(themed.copy.emptyIllustration, .ghost)
        XCTAssertEqual(standard.copy.emptyIllustration, .standard)
        XCTAssertEqual(standard.copy.streak(1), "1 giorno di costanza")
        XCTAssertFalse(ThemeArtwork.bat.isEmpty)
        XCTAssertFalse(ThemeArtwork.ghost.isEmpty)
        XCTAssertEqual(standard.decoration.particleCount, 7)
        XCTAssertEqual(ThemeRegistry.defaultPackage.options.map(\.id), [ThemeOptionID.followSeason])
    }
    func testAnimationPrecedenceAndHiddenSections() {
        for visible in [true, false] {
            for enabled in [true, false] {
                for reduceMotion in [true, false] {
                    for animation in ["Off", "Reduced", "Full"] {
                        XCTAssertEqual(ThemeAnimationPolicy.moving(visible: visible, decorations: enabled, reduceMotion: reduceMotion, animations: animation), visible && enabled && !reduceMotion && animation != "Off")
                    }
                }
            }
        }
        let d = HalloweenTheme.package.dark.decoration
        for time in stride(from: 0.0, through: 8, by: 0.05) {
            let opacity = ThemeAnimationPolicy.candleOpacity(elapsed: time, decoration: d, active: true)
            XCTAssertGreaterThanOrEqual(opacity, 0.85); XCTAssertLessThanOrEqual(opacity, 1)
            XCTAssertEqual(ThemeAnimationPolicy.candleOpacity(elapsed: time, decoration: d, active: false), 1)
        }
        XCTAssertEqual(ThemeAnimationPolicy.candleOpacity(elapsed: 0, decoration: d, active: true), ThemeAnimationPolicy.candleOpacity(elapsed: 4, decoration: d, active: true), accuracy: 0.000001)
        XCTAssertNil(ThemeAnimationPolicy.batPhase(elapsed: 83, decoration: d, moving: true))
        XCTAssertEqual(ThemeAnimationPolicy.batPhase(elapsed: 87, decoration: d, moving: true), 0.5)
        XCTAssertNil(ThemeAnimationPolicy.batPhase(elapsed: 87, decoration: d, moving: false))
        XCTAssertNil(ThemeAnimationPolicy.batPhase(elapsed: 90, decoration: d, moving: true))
    }
    func testThemeOptionsPersistAndLandscapeReturnsWithoutChangingTimer() throws {
        let suite = "KomorebiTests.Decorations.\(UUID())"; let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = try StudyStore(inMemory: true, defaults: defaults)
        store.settings.onboarded = true; store.settings.landscape = "Night"; store.start()
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(XCTUnwrap(store.active))
        let colors = store.subjects.map(\.color)
        store.settings.themeID = HalloweenTheme.package.id
        store.settings.themeOptions = [HalloweenTheme.package.id: [ThemeOptionID.decorations: false, ThemeOptionID.themedText: true]]
        for mode in ["Light", "Dark"] {
            store.settings.appearance = mode
            let resolved = ThemeRegistry.resolve(settings: store.settings, system: .light)
            XCTAssertFalse(resolved.decorationsEnabled)
            XCTAssertEqual(resolved.copy.streak(1), "1 notte di fila")
            XCTAssertTrue(resolved.package.behavior.replacesLandscapes)
            XCTAssertEqual(store.settings.landscape, "Night")
        }
        store.settings.themeID = ThemeRegistry.defaultPackage.id
        XCTAssertFalse(ThemeRegistry.resolve(settings: store.settings, system: .light).package.behavior.replacesLandscapes)
        XCTAssertEqual(store.settings.landscape, "Night")
        XCTAssertEqual(store.subjects.map(\.color), colors)
        XCTAssertEqual(try encoder.encode(XCTUnwrap(store.active)), before)
        let reopened = try StudyStore(inMemory: true, defaults: defaults)
        XCTAssertEqual(reopened.settings.landscape, "Night")
        XCTAssertEqual(reopened.settings.themeOptions, store.settings.themeOptions)
        reopened.settings.themeID = HalloweenTheme.package.id
        let restored = ThemeRegistry.resolve(settings: reopened.settings, system: .light)
        XCTAssertFalse(restored.decorationsEnabled)
        XCTAssertEqual(restored.copy.streak(7), "7 notti di fila")
    }
}
