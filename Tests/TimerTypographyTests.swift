import XCTest
import SwiftUI
import AppKit
@testable import KomorebiStudy

@MainActor final class TimerTypographyTests: XCTestCase {
    func testOnlyHalloweenUsesFixedDecorativeDigits() throws {
        try ThemeFonts.register()
        for mode in ThemeMode.allCases {
            let normal = ThemeRegistry.defaultPackage.resolve(mode: mode)
            let themed = HalloweenTheme.package.resolve(mode: mode)
            XCTAssertFalse(normal.cifreCellaFissa)
            XCTAssertNil(normal.typography.timerFontName)
            XCTAssertEqual(normal.typography.timerDigits, DesignSystem.Typography.timerDigits)
            XCTAssertTrue(themed.cifreCellaFissa)
            XCTAssertEqual(themed.typography.timerFontName, "PirataOne-Regular")
            XCTAssertEqual(themed.typography.timerGlowOpacity, mode == .dark ? 0.2 : 0)
            let menuSize = themed.typography.menuTimerPointSize
            let menuFont = try XCTUnwrap(NSFont(name: "PirataOne-Regular", size: menuSize))
            let menuMetrics = TimerGlyphMetrics(font: menuFont)
            XCTAssertEqual(menuMetrics.scale(in: CGSize(width: 220, height: themed.typography.timerLineHeight(at: menuSize)), text: "25:00"), 1)
            XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(themed.palette.textPrimary, themed.palette.background), 4.5)
            XCTAssertGreaterThanOrEqual(ThemeContrast.ratio(themed.palette.textPrimary, themed.palette.surface), 4.5)
        }
    }
    func testCountdownCellsDoNotMoveAcrossTenSeconds() throws {
        try ThemeFonts.register()
        let font = try XCTUnwrap(NSFont(name: "PirataOne-Regular", size: 60))
        let metrics = TimerGlyphMetrics(font: font)
        XCTAssertLessThan(metrics.separatorWidth, metrics.digitWidth)
        for digit in 0...9 { XCTAssertGreaterThanOrEqual(metrics.digitWidth, (String(digit) as NSString).size(withAttributes: [.font: font]).width) }
        for width in [CGFloat(132), 160, 232, 312] {
            let available = CGSize(width: width, height: width)
            let baseline = metrics.centers(for: "50:00", available: available).map(\.1)
            for second in 2990...3000 {
                XCTAssertEqual(metrics.centers(for: clockText(Double(second)), available: available).map(\.1), baseline)
            }
        }
    }
    func testAllSupportedDurationsFitAndRender() throws {
        try ThemeFonts.register()
        let font = try XCTUnwrap(NSFont(name: "PirataOne-Regular", size: 60))
        let metrics = TimerGlyphMetrics(font: font)
        for seconds in [1500.0, 3000, 5400, 86400, 3_153_600_000] {
            let text = clockText(seconds)
            for width in [CGFloat(132), 160, 232, 312] {
                let area = CGSize(width: width, height: width)
                let scale = metrics.scale(in: area, text: text)
                XCTAssertLessThanOrEqual(metrics.width(of: text) * scale, width + 0.001)
                XCTAssertLessThanOrEqual(metrics.lineHeight * scale, width + 0.001)
            }
        }
        for mode in ThemeMode.allCases {
            let theme = HalloweenTheme.package.resolve(mode: mode)
            let content = VStack(spacing: 16) {
                ForEach(["25:00", "50:00", "01:30:00", clockText(3_153_600_000)], id: \.self) { text in
                    ThemeFixedTimerDigits(text: text, pointSize: theme.typography.timerPointSize)
                        .frame(width: 132, height: 100)
                }
            }.padding(24).background(theme.palette.background).environment(\.studyTheme, theme)
            let renderer = ImageRenderer(content: content); renderer.scale = 2
            let image = try XCTUnwrap(renderer.nsImage)
            if let folder = ProcessInfo.processInfo.environment["KOMOREBI_TIMER_RENDER"] {
                let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
                try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: folder).appendingPathComponent("timer-\(mode.rawValue).png"))
            }
        }
    }
}

extension TimerTypographyTests {
    func testTimerFaceRendersStudyBreakLongBreakAndPauseAtEverySupportedSize() throws {
        try ThemeFonts.register()
        let suite = "TimerTypography.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = try StudyStore(inMemory: true, defaults: defaults)
        store.settings.animations = "Off"
        let now = Date(); store.now = now
        for mode in ThemeMode.allCases {
            for (name, duration, isBreak, paused) in [("studio",3000.0,false,false),("pausa-breve",300.0,true,false),("pausa-lunga",900.0,true,false),("sospeso",3000.0,false,true)] {
                store.active = ActiveTimer(start: now, pausedAt: paused ? now : nil, target: duration, subjectID: nil, subjectName: "La tua materia", mode: .pomodoro, isBreak: isBreak)
                for width in [CGFloat(180), 208, 280, 360] {
                    let theme = HalloweenTheme.package.resolve(mode: mode)
                    let content = TimerFace(minimal: width == 360).frame(width: width).padding(16)
                        .background(theme.palette.background).environment(\.studyTheme, theme)
                        .environment(\.komorebiMotion, "Off").environmentObject(store)
                    let renderer = ImageRenderer(content: content); renderer.scale = 2
                    let image = try XCTUnwrap(renderer.nsImage)
                    if let folder = ProcessInfo.processInfo.environment["KOMOREBI_TIMER_RENDER"], width == 180 || width == 360 {
                        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
                        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: folder).appendingPathComponent("face-\(name)-\(mode.rawValue)-\(Int(width)).png"))
                    }
                }
            }
        }
    }
}
