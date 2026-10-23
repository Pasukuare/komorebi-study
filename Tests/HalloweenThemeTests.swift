import XCTest
import SwiftUI
import CoreText
@testable import KomorebiStudy

@MainActor final class HalloweenThemeTests: XCTestCase {
    func testFontsAreBundledLicensedAndRegisteredWithExactPostScriptNames() throws {
        try ThemeFonts.register()
        for (file, name) in zip(ThemeFonts.files, ThemeFonts.postScriptNames) {
            XCTAssertNotNil(ThemeFonts.resourceBundle.url(forResource: file, withExtension: nil, subdirectory: "Fonts"))
            XCTAssertEqual(CTFontCopyPostScriptName(CTFontCreateWithName(name as CFString, 20, nil)) as String, name)
        }
        for file in ["OFL-IMFellEnglish.txt", "OFL-PirataOne.txt"] {
            let url = try XCTUnwrap(ThemeFonts.resourceBundle.url(forResource: file, withExtension: nil, subdirectory: "Fonts"))
            XCTAssertTrue(try String(contentsOf: url, encoding: .utf8).contains("SIL OPEN FONT LICENSE Version 1.1"))
        }
    }
    func testBehaviorIsDeclaredAndTimerAndBodyRemainSans() {
        let theme = HalloweenTheme.package
        XCTAssertEqual(theme.behavior.initialColorTab, .season(.autumn))
        XCTAssertTrue(theme.behavior.replacesLandscapes); XCTAssertFalse(theme.behavior.supportsSeason)
        XCTAssertEqual(theme.behavior.suggestionWindow, ThemeSuggestionWindow(startMonth: 10, startDay: 15, endMonth: 11, endDay: 1))
        for mode in ThemeMode.allCases {
            let resolved = theme.resolve(mode: mode), baseline = ThemeRegistry.defaultPackage.resolve(mode: mode)
            XCTAssertEqual(resolved.typography.timerFontName, "PirataOne-Regular")
            XCTAssertEqual(resolved.typography.body, baseline.typography.body)
            XCTAssertNotEqual(resolved.typography.heading, baseline.typography.heading)
            XCTAssertEqual(resolved.subjectColors.map(\.id), baseline.subjectColors.map(\.id))
        }
    }
    func testTextControlsAndSubjectRolesMeetContrastInEveryMode() {
        var auditRows: [String] = ["utilizzo,fr,fg,fb,br,bg,bb,soglia,rapporto"]
        func check(_ foreground: Color, _ background: Color, _ threshold: Double, _ label: String) {
            let ratio = ThemeContrast.ratio(foreground, background)
            XCTAssertGreaterThanOrEqual(ratio, threshold, label)
            auditRows.append(([label] + (ThemeContrast.rgb(foreground) + ThemeContrast.rgb(background) + [threshold, ratio]).map { String($0) }).joined(separator: ","))
        }
        for mode in ThemeMode.allCases {
            let theme = HalloweenTheme.package.resolve(mode: mode), p = theme.palette
            let surfaces = [p.background, p.sidebar, p.surface, p.elevatedSurface]
            for surface in surfaces {
                for text in [p.textPrimary, p.textSecondary, p.textTertiary, p.accent, p.interval, p.success, p.error, p.warning, p.placeholder!, p.disabledText!] {
                    check(text, surface, 4.5, "\(mode) testo")
                    let hoverBackground = ThemeContrast.composite(p.spotlight, on: surface, opacity: DesignSystem.Interaction.spotlightOpacity)
                    let hoverText = ThemeContrast.composite(p.spotlight, on: text, opacity: DesignSystem.Interaction.spotlightOpacity)
                    check(hoverText, hoverBackground, 4.5, "\(mode) hover")
                }
                check(p.controlBorder, surface, 3, "\(mode) bordo")
                check(p.accent, surface, 3, "\(mode) focus")
                for alpha in [0.055, 0.13] {
                    check(p.accent, ThemeContrast.composite(p.accent, on: surface, opacity: alpha), 4.5, "\(mode) bottone neutro")
                }
                for alpha in [0.07, 0.16] {
                    check(p.error, ThemeContrast.composite(p.error, on: surface, opacity: alpha), 4.5, "\(mode) bottone distruttivo")
                }

                check(p.sliderTrack, surface, 3, "\(mode) slider")
                for choice in theme.subjectColors {
                    let tile = ThemeContrast.composite(choice.ink, on: surface, opacity: DesignSystem.SubjectAppearance.fillOpacity)
                    check(choice.text, surface, 4.5, "\(mode) \(choice.id)")
                    check(choice.text, tile, 4.5, "\(mode) \(choice.id) tile")
                    check(choice.icon, tile, 3, "icona tile")
                }
            }
            for action in [p.action, p.actionHover, p.actionPressed!] {
                check(p.onAction, action, 4.5, "\(mode) CTA")
            }
            check(p.onDisabledAction, p.disabledAction, 4.5, "icona tile")
            check(p.textPrimary, p.accentSurface, 4.5, "icona tile")
            check(p.textPrimary, p.sidebarSelection, 4.5, "icona tile")
        }
        if let path = ProcessInfo.processInfo.environment["KOMOREBI_HALLOWEEN_AUDIT"] {
            try? (auditRows.joined(separator: "\n") + "\n").write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
