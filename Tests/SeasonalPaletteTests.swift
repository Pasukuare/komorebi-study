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

extension SeasonalPaletteTests {
    func testSeasonalSwatchesRemainPerceptuallySeparatedInEveryThemeAndMode() {
        func lab(_ color: Color) -> [Double] {
            let c = ThemeContrast.rgb(color).map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
            let xyz = [(0.4124564*c[0]+0.3575761*c[1]+0.1804375*c[2])/0.95047,
                       0.2126729*c[0]+0.7151522*c[1]+0.0721750*c[2],
                       (0.0193339*c[0]+0.1191920*c[1]+0.9503041*c[2])/1.08883]
            let f = xyz.map { $0 > 0.008856 ? pow($0, 1/3) : 7.787*$0+16/116 }
            return [116*f[1]-16, 500*(f[0]-f[1]), 200*(f[1]-f[2])]
        }
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme = package.resolve(mode: mode)
                for group in SubjectColorGroup.allCases where group != .classics {
                    let colors = theme.subjectColors.filter { SubjectColorGroup.group(for: $0.id) == group }
                    for i in colors.indices {
                        for j in colors.indices where j > i {
                            let distance = sqrt(zip(lab(colors[i].ink), lab(colors[j].ink)).reduce(0) { $0 + pow($1.0-$1.1, 2) })
                            // A regression guard for collapsed swatches, not a guarantee of universal color recognition.
                            XCTAssertGreaterThan(distance, 10, "\(package.id) \(mode) \(colors[i].id) / \(colors[j].id)")
                        }
                    }
                }
            }
        }
    }

    func testPaletteContactSheetsRenderAtActualSwatchSize() throws {
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let theme = package.resolve(mode: mode)
                let sheet = VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    Text(package.name).font(theme.typography.title)
                    ForEach(SubjectColorGroup.allCases) { group in
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Label(group.title, systemImage: group.symbol).font(theme.typography.heading)
                            Text(group.paletteDescription).font(theme.typography.caption)
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(theme.subjectColors.filter { SubjectColorGroup.group(for: $0.id) == group }) { choice in
                                    VStack(spacing: DesignSystem.Spacing.xs) {
                                        Circle().fill(choice.ink).frame(width: DesignSystem.SubjectAppearance.swatch, height: DesignSystem.SubjectAppearance.swatch)
                                        Text(L10n.tr(choice.name)).font(theme.typography.caption).foregroundStyle(choice.text)
                                    }
                                }
                            }
                        }
                    }
                }.padding(DesignSystem.Spacing.xl).foregroundStyle(theme.palette.textPrimary).background(theme.palette.background)
                let renderer = ImageRenderer(content: sheet); renderer.scale = 2
                let image = try XCTUnwrap(renderer.nsImage)
                if let folder = ProcessInfo.processInfo.environment["KOMOREBI_PALETTE_RENDER"] {
                    let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: folder).appendingPathComponent("palette-\(package.id)-\(mode.rawValue).png"))
                }
            }
        }
    }
}
