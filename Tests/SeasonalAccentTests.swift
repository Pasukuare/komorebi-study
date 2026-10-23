import XCTest
import SwiftUI
@testable import KomorebiStudy
@MainActor final class SeasonalAccentTests: XCTestCase {
    func testAllSeasonsPreserveBaseAndHaveAccessibleFillAndInk() throws {
        var rows = ["utilizzo,fr,fg,fb,br,bg,bb,soglia,rapporto"]
        func record(_ fg: Color, _ bg: Color, _ threshold: Double, _ label: String) {
            rows.append(([label] + (ThemeContrast.rgb(fg) + ThemeContrast.rgb(bg) + [threshold, ThemeContrast.ratio(fg,bg)]).map { String($0) }).joined(separator: ","))
        }
        for mode in ThemeMode.allCases {
            let base = ThemeRegistry.defaultPackage.resolve(mode: mode)
            for season in [ThemeSeason.spring,.summer,.autumn,.winter] {
                let v = SeasonalAccent.apply(to: mode == .light ? ThemeRegistry.defaultPackage.light : ThemeRegistry.defaultPackage.dark, mode: mode, season: season)
                XCTAssertEqual(v.palette.background, base.palette.background)
                XCTAssertEqual(v.palette.surface, base.palette.surface)
                XCTAssertEqual(v.typography.timerDigits, base.typography.timerDigits)
                XCTAssertEqual(v.subjectColors.map(\.ink), base.subjectColors.map(\.ink))
                for fill in [v.palette.action,v.palette.actionHover,v.palette.actionPressed!,v.palette.accentSurface] { XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(.white, fill),4.5); record(.white,fill,4.5,mode.rawValue+" "+season.rawValue+" riempimento") }
                XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(v.palette.onDisabledAction,v.palette.disabledAction),4.5)
                XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(v.palette.timerGradientEnd,v.palette.background),3)
                for surface in [v.palette.background,v.palette.surface,v.palette.elevatedSurface] { XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(v.palette.accent,surface),4.5); record(v.palette.accent,surface,4.5,mode.rawValue+" "+season.rawValue+" ink") }
            }
        }
        if let path = ProcessInfo.processInfo.environment["KOMOREBI_SEASON_AUDIT"] { try (rows.joined(separator:"\n")+"\n").write(toFile:path,atomically:true,encoding:.utf8) }
    }
    func testDefaultOffAndUnsupportedThemesIgnoreOption() {
        let package = ThemeRegistry.defaultPackage
        XCTAssertEqual(package.resolve(mode: .light).palette.accent, package.light.palette.accent)
        let h = HalloweenTheme.package
        XCTAssertEqual(h.resolve(mode: .dark,options:[ThemeOptionID.followSeason:true]).palette.accent,h.dark.palette.accent)
        let date = Calendar.current.date(from: DateComponents(year:2026,month:10,day:23))!
        XCTAssertNotEqual(package.resolve(mode:.light,options:[ThemeOptionID.followSeason:true],date:date).palette.accent,package.light.palette.accent)
    }
}
