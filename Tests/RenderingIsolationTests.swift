import XCTest
import Combine
import SwiftUI
@testable import KomorebiStudy

@MainActor final class RenderingIsolationTests: XCTestCase {
    private func store() throws -> StudyStore {
        try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "RenderingTests.\(UUID())")!)
    }
    func testSecondsPublishOnlyToClockAndMidnightRefreshesStore() throws {
        let s = try store()
        let start = Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600)
        s.now = start
        var storeUpdates = 0, clockUpdates = 0
        let storeToken = s.objectWillChange.sink { storeUpdates += 1 }
        let clockToken = s.clock.$now.dropFirst().sink { _ in clockUpdates += 1 }
        for second in 1...60 { s.now = start.addingTimeInterval(Double(second)) }
        XCTAssertEqual(clockUpdates, 60)
        XCTAssertEqual(storeUpdates, 0, "A ticking clock must not refresh hidden sections and settings")
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        s.now = tomorrow
        XCTAssertEqual(storeUpdates, 1, "Dates, daily totals and seasonal themes must refresh at midnight")
        XCTAssertEqual(s.now, tomorrow)
        withExtendedLifetime([storeToken, clockToken]) {}
    }
    func testClockRecognizesTimeZoneAndDaylightSavingBoundaries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        let formatter = ISO8601DateFormatter()
        let start = formatter.date(from: "2026-03-28T23:00:00Z")!
        let clock = StudyClock(now: start, calendar: calendar)
        XCTAssertFalse(clock.crossesCalendarBoundary(start.addingTimeInterval(3600), calendar: calendar))
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start)!
        XCTAssertEqual(nextDay.timeIntervalSince(start), 23 * 3600)
        XCTAssertTrue(clock.crossesCalendarBoundary(nextDay, calendar: calendar))
        clock.update(nextDay, calendar: calendar)
        XCTAssertFalse(clock.crossesCalendarBoundary(nextDay.addingTimeInterval(1), calendar: calendar))
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        XCTAssertTrue(clock.crossesCalendarBoundary(nextDay, calendar: calendar))
    }
    func testIsolatedClockKeepsLiveTotalsPauseAndMidnightSplit() throws {
        let s = try store()
        let midnight = Calendar.current.startOfDay(for: Date())
        let start = midnight.addingTimeInterval(-120)
        s.active = ActiveTimer(start: start, target: nil, subjectName: "Test", mode: .stopwatch)
        s.now = midnight.addingTimeInterval(60)
        XCTAssertEqual(s.liveToday, s.today + 60, accuracy: 0.001)
        XCTAssertEqual(s.active!.displayed(at: s.now), 180, accuracy: 0.001)
        s.active?.pause(at: s.now)
        s.now = midnight.addingTimeInterval(600)
        XCTAssertEqual(s.liveToday, s.today + 60, accuracy: 0.001)
        XCTAssertEqual(s.active!.displayed(at: s.now), 180, accuracy: 0.001)
        s.active?.resume(at: s.now)
        s.now = midnight.addingTimeInterval(660)
        XCTAssertEqual(s.liveToday, s.today + 120, accuracy: 0.001)
    }
    func testNaturalCompletionStillRunsOnTick() throws {
        let s = try store()
        s.active = ActiveTimer(start: Date().addingTimeInterval(-120), target: 60, subjectName: "Test", mode: .custom)
        s.tick()
        XCTAssertEqual(s.completed?.duration, 60)
        XCTAssertEqual(s.sessions.first?.duration, 60)
    }
    func testWindowPolicyAndLowPowerDoNotAlterTimer() throws {
        for visible in [true, false] {
            for mini in [true, false] {
                for occluded in [true, false] {
                    for active in [true, false] {
                        for lowPower in [true, false] {
                            let state = RenderingState.resolve(windowVisible: visible, miniaturized: mini, occluded: occluded, appActive: active, lowPower: lowPower)
                            XCTAssertEqual(state.visible, visible && !mini && !occluded && active)
                            XCTAssertEqual(state.ambientMotion, visible && !mini && !occluded && active && !lowPower)
                        }
                    }
                }
            }
        }
        let s = try store(); s.start()
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(XCTUnwrap(s.active))
        _ = RenderingState.resolve(windowVisible: false, miniaturized: true, occluded: true, appActive: false, lowPower: true)
        XCTAssertEqual(try encoder.encode(XCTUnwrap(s.active)), before)
    }
    func testStoreAndClockCanBeReleased() throws {
        weak var weakStore: StudyStore?
        weak var weakClock: StudyClock?
        do {
            let s = try store(); weakStore = s; weakClock = s.clock
            s.now = s.now.addingTimeInterval(1)
        }
        XCTAssertNil(weakStore); XCTAssertNil(weakClock)
    }
}

extension RenderingIsolationTests {
    func testLiveTimerHasCurrentValueBeforeOnAppear() throws {
        let s = try store()
        let instant = Date(timeIntervalSince1970: 10000)
        s.now = instant
        s.active = ActiveTimer(start: instant.addingTimeInterval(-30), target: 1500, subjectName: "Test", mode: .pomodoro)
        let renderer = ImageRenderer(content: LiveStudyTime { date in
            Text(clockText(s.active!.displayed(at: date)))
        }.environmentObject(s).frame(width: 200, height: 50))
        XCTAssertNotNil(renderer.nsImage)
        XCTAssertEqual(s.active?.displayed(at: s.clock.now), 1470)
    }
    func testThemesAndTimerRenderAcrossModesAndDecorationOptions() throws {
        try ThemeFonts.register()
        let s = try store()
        let instant = s.now
        s.active = ActiveTimer(start: instant.addingTimeInterval(-60), target: 3000, subjectName: "Materia con un nome molto lungo per verificare il layout", mode: .pomodoro)
        for package in [ThemeRegistry.defaultPackage, HalloweenTheme.package] {
            for mode in ThemeMode.allCases {
                for decorations in [true, false] {
                    let theme = package.resolve(mode: mode, options: [ThemeOptionID.decorations: decorations])
                    for width in [CGFloat(160), 312] {
                        let content = TimerFace()
                            .environmentObject(s).environment(\.studyTheme, theme)
                            .environment(\.komorebiMotion, "Off")
                            .frame(width: width, height: width + 120).background(theme.palette.background)
                        let image = try XCTUnwrap(ImageRenderer(content: content).nsImage)
                        XCTAssertEqual(image.size.width, width)
                        XCTAssertGreaterThan(image.size.height, width)
                    }
                }
            }
        }
    }
}

extension RenderingIsolationTests {
    func testChartPointerPublishesOnlyWhenBucketChanges() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_792_764_000))
        let buckets = (0..<7).map { TimeBucket(date: calendar.date(byAdding: .day, value: $0, to: start)!, value: Double($0)) }
        var selected: Date?, changes = 0
        // A thousand distinct pointer dates within one bar must cause one update.
        for second in 0..<1000 {
            let next = StatisticsChartSelection.bucketDate(for: start.addingTimeInterval(Double(second)), buckets: buckets, unit: .day, calendar: calendar)
            if next != selected { selected = next; changes += 1 }
        }
        XCTAssertEqual(changes, 1)
        XCTAssertEqual(selected, start)
        XCTAssertEqual(StatisticsChartSelection.bucketDate(for: buckets[1].date, buckets: buckets, unit: .day, calendar: calendar), buckets[1].date)
        XCTAssertNil(StatisticsChartSelection.bucketDate(for: start.addingTimeInterval(-1), buckets: buckets, unit: .day, calendar: calendar))
        XCTAssertNil(StatisticsChartSelection.bucketDate(for: nil, buckets: buckets, unit: .day, calendar: calendar))
        XCTAssertNil(StatisticsChartSelection.bucketDate(for: start, buckets: [], unit: .day, calendar: calendar))
    }
    func testChartMonthlySelectionUsesMonthStartAcrossDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let end = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 23)))
        let buckets = [TimeBucket(date: start, value: 2.5)]
        XCTAssertEqual(StatisticsChartSelection.bucketDate(for: end, buckets: buckets, unit: .month, calendar: calendar), start)
        let november = try XCTUnwrap(calendar.date(byAdding: .month, value: 1, to: start))
        XCTAssertNil(StatisticsChartSelection.bucketDate(for: november, buckets: buckets, unit: .month, calendar: calendar))
    }
    func testMenuSurfaceCoversHostBackgroundInBothThemesAndModes() throws {
        for package in ThemeRegistry.packages {
            for mode in ThemeMode.allCases {
                let color = NSColor(package.resolve(mode: mode).palette.background)
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 350, height: 500), styleMask: [.borderless], backing: .buffered, defer: false)
                let root = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 500))
                let surface = MenuPanelWindowSurface.Host(color: color)
                window.contentView = root
                root.addSubview(surface)
                surface.apply()
                XCTAssertTrue(window.isOpaque)
                XCTAssertEqual(window.backgroundColor, color)
                XCTAssertEqual(try XCTUnwrap(window.contentView?.layer?.backgroundColor).alpha, 1, accuracy: 0.001)
                XCTAssertNil(surface.hitTest(.zero))
                // Theme changes repaint the whole host, not just the content rectangle.
                let other = NSColor(package.resolve(mode: mode == .light ? .dark : .light).palette.background)
                surface.color = other; surface.apply()
                XCTAssertEqual(window.backgroundColor, other)
                window.contentView = nil
            }
        }
    }
}
