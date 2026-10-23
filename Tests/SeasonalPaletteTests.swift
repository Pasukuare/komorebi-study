import XCTest
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class SeasonalPaletteTests: XCTestCase {
    func testSeasonBoundariesUseLocalCalendar() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        for (month, day, expected) in [(3,20,ThemeSeason.winter),(3,21,.spring),(6,20,.spring),(6,21,.summer),(9,22,.summer),(9,23,.autumn),(12,20,.autumn),(12,21,.winter),(1,1,.winter)] {
            let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 0)))
            XCTAssertEqual(ThemeSeason.current(at: date, calendar: calendar), expected)
        }
    }
    func testEditingWinsOverThemeSuggestionWithoutRewritingSelection() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)))
        var behavior = ThemeRegistry.defaultPackage.behavior
        XCTAssertEqual(SubjectColorGroup.initial(editing: false, colorID: "classici.salvia", behavior: behavior, date: date, calendar: calendar), .summer)
        XCTAssertEqual(SubjectColorGroup.initial(editing: true, colorID: "autunno.zucca", behavior: behavior, date: date, calendar: calendar), .autumn)
        XCTAssertEqual(SubjectColorGroup.initial(editing: true, colorID: "Cielo", behavior: behavior, date: date, calendar: calendar), .classics)
        behavior.initialColorTab = .season(.winter)
        XCTAssertEqual(SubjectColorGroup.initial(editing: false, colorID: "classici.salvia", behavior: behavior, date: date, calendar: calendar), .winter)
        XCTAssertEqual(SubjectColorGroup.initial(editing: true, colorID: "estate.mare", behavior: behavior, date: date, calendar: calendar), .summer)
    }
    func testAllSeasonalRolesMeetContrastOnEveryActualSurface() {
        XCTAssertEqual(SeasonalSubjectColors.values.count, 24)
        XCTAssertEqual(Set(SeasonalSubjectColors.values.map(\.id)).count, 24)
        for mode in ThemeMode.allCases {
            let theme = ThemeRegistry.defaultPackage.resolve(mode: mode)
            XCTAssertEqual(theme.subjectColors.count, 32)
            let surfaces = [theme.palette.background, theme.palette.surface, theme.palette.elevatedSurface]
            for choice in theme.subjectColors where !choice.id.hasPrefix("classici.") {
                XCTAssertEqual(SubjectColorID.canonical(choice.id), choice.id)
                XCTAssertEqual(theme.subjectChoice(choice.id).id, choice.id)
                let ink = rgb(choice.ink)
                for surface in surfaces {
                    let background = rgb(surface)
                    let tile = zip(ink, background).map { $0 * DesignSystem.SubjectAppearance.fillOpacity + $1 * (1 - DesignSystem.SubjectAppearance.fillOpacity) }
                    XCTAssertGreaterThanOrEqual(contrast(rgb(choice.text), background), 4.5, "\(mode) \(choice.id) testo")
                    XCTAssertGreaterThanOrEqual(contrast(rgb(choice.text), tile), 4.5, "\(mode) \(choice.id) testo tile")
                    XCTAssertGreaterThanOrEqual(contrast(rgb(choice.icon), tile), 3, "\(mode) \(choice.id) icona")
                }
            }
        }
    }
    func testSeasonalColorsPersistAndFeedCalendarWithoutMigration() throws {
        let suite = "KomorebiTests.Seasonal.\(UUID())"; let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = try StudyStore(inMemory: true, defaults: defaults)
        let subject = Subject(name: "Autunno", color: "autunno.zucca"); store.context.insert(subject)
        let start = Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600)
        store.context.insert(StudySession(start: start, end: start.addingTimeInterval(3600), duration: 3600, subjectID: subject.id, subjectName: subject.name, mode: TimerMode.stopwatch.rawValue, pause: 0))
        XCTAssertTrue(store.save())
        XCTAssertEqual(try store.migrateSubjectColorIDs(archiveURL: nil), 0)
        let records = [SubjectRecord(subject)]
        let restored = try JSONDecoder().decode([SubjectRecord].self, from: JSONEncoder().encode(records))
        XCTAssertEqual(restored[0].id, subject.id); XCTAssertEqual(restored[0].color, "autunno.zucca")
        let shares = store.calendarShares(in: DateInterval(start: start, duration: 3600))
        XCTAssertEqual(shares.first?.color, "autunno.zucca")
        for mode in ThemeMode.allCases {
            let theme = ThemeRegistry.defaultPackage.resolve(mode: mode)
            let stops = calendarPigmentStops(shares, theme: theme)
            XCTAssertEqual(stops.count, 2)
            XCTAssertEqual(stops.first?.color, theme.subjectColor(subject.color))
        }
    }
    private func rgb(_ color: Color) -> [Double] {
        let c = NSColor(color).usingColorSpace(.sRGB)!
        return [c.redComponent, c.greenComponent, c.blueComponent]
    }
    private func contrast(_ a: [Double], _ b: [Double]) -> Double {
        func luminance(_ c: [Double]) -> Double {
            zip(c, [0.2126,0.7152,0.0722]).reduce(0) { sum, v in sum + (v.0 <= 0.04045 ? v.0 / 12.92 : pow((v.0 + 0.055) / 1.055, 2.4)) * v.1 }
        }
        let x = luminance(a), y = luminance(b); return (max(x,y) + 0.05) / (min(x,y) + 0.05)
    }
}
