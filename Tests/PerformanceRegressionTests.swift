import XCTest
import CryptoKit
import SwiftUI
@testable import KomorebiStudy

@MainActor final class PerformanceRegressionTests: XCTestCase {
    /// Opt-in Release microbenchmarks. They measure these code paths, not app FPS or watts.
    func testReleaseWorkloads() throws {
        guard let output = ProcessInfo.processInfo.environment["KOMOREBI_BENCHMARK_OUTPUT"] else { return }
        #if DEBUG
        throw XCTSkip("Performance measurements require a Release build")
        #endif
        let candidates = (0..<400).map { index in
            let frame = CGRect(x: (index % 20) * 50, y: (index / 20) * 48, width: 48, height: 44)
            return StudyHoverCandidate(id: index, frame: frame, visibleFrame: frame, radius: 8, depth: 4, enabled: index % 5 != 0)
        }
        var checksum = 0
        var start = ContinuousClock.now
        for index in 0..<20_000 {
            checksum += StudyHoverPolicy.winner(at: CGPoint(x: (index * 7) % 1000, y: (index * 11) % 960), candidates: candidates) ?? 0
        }
        let hover = start.duration(to: .now)
        XCTAssertGreaterThan(checksum, 0)
        let store = try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "PerfFixtures.\(UUID())")!)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let saved = (0..<1000).map { index -> StudySession in
            let beginning = today.addingTimeInterval(-Double(index % 90) * 86400 + 3600)
            let session = StudySession(start: beginning, end: beginning.addingTimeInterval(3600), duration: 3000, subjectID: nil, subjectName: "Fixture", mode: TimerMode.pomodoro.rawValue, pause: 600)
            session.activityData = try! JSONEncoder().encode([StudyInterval(start: beginning, end: beginning.addingTimeInterval(1500)), StudyInterval(start: beginning.addingTimeInterval(2100), end: beginning.addingTimeInterval(3600))])
            return session
        }
        store.sessions = saved
        let interval = DateInterval(start: today.addingTimeInterval(-7 * 86400), end: today.addingTimeInterval(86400))
        var total = 0.0
        start = .now
        for _ in 0..<200 { total += store.total(in: interval) }
        let totals = start.duration(to: .now)
        XCTAssertGreaterThan(total, 0)
        start = .now
        for day in 0..<31 {
            let beginning = today.addingTimeInterval(-Double(day) * 86400)
            _ = store.calendarShares(in: DateInterval(start: beginning, end: beginning.addingTimeInterval(86400)))
        }
        let month = start.duration(to: .now)
        let days = (0..<31).map { day in DateInterval(start: today.addingTimeInterval(-Double(day) * 86400), duration: 86400) }
        start = .now
        let monthSnapshot = store.calendarShares(in: days)
        let monthBatch = start.duration(to: .now)
        start = .now
        let bucketSnapshot = store.totals(in: days)
        let bucketsBatch = start.duration(to: .now)
        XCTAssertEqual(monthSnapshot.count, 31)
        XCTAssertEqual(bucketSnapshot.count, 31)
        func seconds(_ duration: Duration) -> Double { Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18 }
        let result: [String: Any] = ["hover_20000_seconds": seconds(hover), "totals_200_seconds": seconds(totals), "calendar_31_days_seconds": seconds(month), "calendar_month_batch_seconds": seconds(monthBatch), "statistics_31_buckets_seconds": seconds(bucketsBatch), "hover_checksum": checksum, "total_checksum": total, "month_checksum": monthSnapshot.flatMap { $0 }.reduce(0) { $0 + $1.seconds }, "buckets_checksum": bucketSnapshot.reduce(0, +), "sessions": 1000, "configuration": "Run with swift test -c release", "scope": "Microbenchmarks only; not UI CPU, FPS, energy or memory"]
        try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: output))
    }
}

extension PerformanceRegressionTests {
    func testActivityDecodeCacheTracksExactPayloadAndCachesFailures() throws {
        let cache = StudyActivityCache()
        let id = UUID(), start = Date(timeIntervalSince1970: 1000)
        let original = try JSONEncoder().encode([StudyInterval(start: start, end: start.addingTimeInterval(60))])
        for _ in 0..<20 { XCTAssertEqual(cache.intervals(id: id, data: original)?.first?.end, start.addingTimeInterval(60)) }
        XCTAssertEqual(cache.decodeCount, 1)
        let edited = try JSONEncoder().encode([StudyInterval(start: start, end: start.addingTimeInterval(120))])
        XCTAssertEqual(cache.intervals(id: id, data: edited)?.first?.end, start.addingTimeInterval(120))
        XCTAssertEqual(cache.decodeCount, 2)
        for _ in 0..<20 { XCTAssertNil(cache.intervals(id: id, data: Data("{".utf8))) }
        XCTAssertEqual(cache.decodeCount, 3)
        XCTAssertEqual(cache.intervals(id: id, data: original)?.first?.end, start.addingTimeInterval(60))
        XCTAssertEqual(cache.decodeCount, 4)
    }
    func testCachedContributionsStayCorrectAfterTimingEditsAndForLegacyData() throws {
        let store = try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "CacheTiming.\(UUID())")!)
        let start = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-120)
        let session = StudySession(start: start, end: start.addingTimeInterval(240), duration: 180, subjectID: nil, subjectName: "Fixture", mode: TimerMode.stopwatch.rawValue, pause: 60)
        session.activityData = try JSONEncoder().encode([StudyInterval(start: start, end: start.addingTimeInterval(90)), StudyInterval(start: start.addingTimeInterval(150), end: start.addingTimeInterval(240))])
        let first = DateInterval(start: start, end: start.addingTimeInterval(120))
        let second = DateInterval(start: first.end, end: start.addingTimeInterval(240))
        XCTAssertEqual(store.contribution(session, in: first), 90)
        XCTAssertEqual(store.contribution(session, in: second), 90)
        session.updateTiming(start: start, end: start.addingTimeInterval(240), duration: 120, pause: 120)
        XCTAssertNil(session.activityData)
        XCTAssertEqual(store.contribution(session, in: first), 60)
        XCTAssertEqual(store.contribution(session, in: second), 60)
        session.activityData = Data("broken".utf8)
        XCTAssertEqual(store.contribution(session, in: first), 60, "Malformed payload must preserve proportional fallback")
        store.sessions = [session]
        XCTAssertEqual(store.total(in: DateInterval(start: start, end: second.end)), 120)
        XCTAssertEqual(store.total(in: first, subject: UUID()), 0)
    }
    func testScrollObserverIsSharedAndRemovedOnStop() {
        let clip = NSClipView()
        let session = StudyInteractionSession()
        for _ in 0..<100 { session.trackScroll(clip) }
        XCTAssertEqual(session.scrollContainerCount, 1)
        session.setInput(.keyboard)
        NotificationCenter.default.post(name: NSView.boundsDidChangeNotification, object: clip)
        XCTAssertEqual(session.input, .keyboard, "Scrolling clears hover, not keyboard input modality")
        session.stop()
        XCTAssertEqual(session.scrollContainerCount, 0)
        XCTAssertFalse(session.pointerFramePending)
    }
    func testPointerFramesAreQueuedAndCancelledWithoutKeepingTheSessionAlive() throws {
        weak var released: StudyInteractionSession?
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = view
        let previousMouseMoves = window.acceptsMouseMovedEvents
        do {
            let session = StudyInteractionSession(); released = session
            session.start(host: view)
            for index in 1...100 {
                let event = try XCTUnwrap(NSEvent.mouseEvent(with: .mouseMoved, location: NSPoint(x: index, y: 50), modifierFlags: [], timestamp: Double(index), windowNumber: window.windowNumber, context: nil, eventNumber: index, clickCount: 0, pressure: 0))
                session.receive(event)
            }
            XCTAssertTrue(session.pointerFramePending)
            session.resetHover()
            XCTAssertFalse(session.pointerFramePending)
            session.stop()
            XCTAssertEqual(window.acceptsMouseMovedEvents, previousMouseMoves)
        }
        XCTAssertNil(released, "Display-link target and monitor must not retain the session")
        window.contentView = nil
    }
}

extension PerformanceRegressionTests {
    func testFocusMouseBurstPublishesOnlyActualVisibilityChanges() async throws {
        let activity = FocusControlsActivity(timeout: .milliseconds(70))
        var publications = 0
        let token = activity.objectWillChange.sink { publications += 1 }
        for _ in 0..<1000 { activity.noteMovement() }
        XCTAssertEqual(publications, 0, "Moving the mouse while controls are visible must not redraw Focus")
        try await Task.sleep(for: .milliseconds(40))
        activity.noteMovement()
        try await Task.sleep(for: .milliseconds(45))
        XCTAssertTrue(activity.controlsVisible, "Movement extends the deadline without restarting the task")
        try await Task.sleep(for: .milliseconds(70))
        XCTAssertFalse(activity.controlsVisible)
        XCTAssertEqual(publications, 1)
        activity.noteMovement()
        XCTAssertTrue(activity.controlsVisible)
        XCTAssertEqual(publications, 2)
        activity.stop()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(activity.controlsVisible, "A cancelled task must not hide controls after the view leaves")
        withExtendedLifetime(token) {}
    }
    func testFocusActivityCanBeReleasedWithAnOutstandingDeadline() async throws {
        weak var released: FocusControlsActivity?
        do {
            let activity = FocusControlsActivity(timeout: .milliseconds(100))
            released = activity
            activity.noteMovement()
        }
        await Task.yield()
        XCTAssertNil(released)
    }
}

extension PerformanceRegressionTests {
    func testAmbientWaveformsKeepTheExactOriginalSamples() throws {
        let hashes = ["Pioggia": "61d22a3374d77e2e1edce4be4668d07ee9a0a147eb7cac7392a603271588fb9a", "Vento": "c61e1166c5d38a4f59cfc9c1e189fca290d425985bbaf62b3bcb2b77bf459f55", "Camino": "b7f971c5889f1940f393ee1eda100146de95f0ea2569b39ab7bdd19adf0fc85a"]
        for (sound, expected) in hashes {
            let data = try AmbientWaveform.makeData(sound: sound)
            XCTAssertEqual(data.count, 44 + 22050 * 12 * 2)
            XCTAssertEqual(Data(data.prefix(4)), Data("RIFF".utf8))
            XCTAssertEqual(SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(), expected, "PCM output must match the pre-refactor baseline byte for byte")
        }
    }
    func testCancelledAmbientGenerationDoesNotProduceAResult() async {
        let job = Task { @MainActor in
            try AmbientWaveform.makeData(sound: "Pioggia")
        }
        job.cancel()
        do { _ = try await job.value; XCTFail("Cancelled PCM generation must stop") }
        catch { XCTAssertTrue(error is CancellationError) }
    }
}

extension PerformanceRegressionTests {
    func testBatchedStatisticsAndCalendarPreservePauseMidnightAndSubjectShares() throws {
        let store = try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "BatchTiming.\(UUID())")!)
        let midnight = Calendar.current.startOfDay(for: Date())
        let start = midnight.addingTimeInterval(-120)
        let subjectA = Subject(name: "A", color: "classici.salvia")
        let subjectB = Subject(name: "B", color: "autunno.zucca")
        store.subjects = [subjectA, subjectB]
        let measured = StudySession(start: start, end: start.addingTimeInterval(240), duration: 180, subjectID: subjectA.id, subjectName: "A", mode: TimerMode.stopwatch.rawValue, pause: 60)
        measured.activityData = try JSONEncoder().encode([StudyInterval(start: start, end: start.addingTimeInterval(90)), StudyInterval(start: start.addingTimeInterval(150), end: start.addingTimeInterval(240))])
        let legacy = StudySession(start: start, end: start.addingTimeInterval(240), duration: 120, subjectID: subjectB.id, subjectName: "B", mode: TimerMode.stopwatch.rawValue, pause: 120)
        store.sessions = [measured, legacy]
        let intervals = [DateInterval(start: start, end: midnight), DateInterval(start: midnight, duration: 120)]
        XCTAssertEqual(store.totals(in: intervals), [150, 150])
        XCTAssertEqual(store.totals(in: intervals, subject: subjectA.id), [90, 90])
        XCTAssertEqual(store.totals(in: intervals, subject: subjectB.id), [60, 60])
        let shares = store.calendarShares(in: intervals)
        for day in shares {
            XCTAssertEqual(day.map(\.name), ["A", "B"])
            XCTAssertEqual(day.map(\.seconds), [90, 60])
            XCTAssertEqual(day.map(\.fraction), [0.6, 0.4])
            XCTAssertEqual(day.map(\.color), ["classici.salvia", "autunno.zucca"])
        }
        XCTAssertTrue(store.totals(in: []).isEmpty)
        XCTAssertTrue(store.calendarShares(in: [DateInterval(start: midnight.addingTimeInterval(3600), duration: 60)])[0].isEmpty)
        store.now = midnight.addingTimeInterval(3600)
        store.settings.streakMinutes = 1
        XCTAssertEqual(store.streak, 2)
        // A metadata edit does not invalidate the interval cache, but must update labels.
        subjectA.name = "Renamed"
        XCTAssertEqual(store.calendarShares(in: intervals)[0][0].name, "Renamed")
        measured.updateTiming(start: start, end: start.addingTimeInterval(240), duration: 60, pause: 180)
        XCTAssertEqual(store.totals(in: intervals), [90, 90])
    }
}

extension PerformanceRegressionTests {
    func testPointerSessionFallbackCleansDisplayLinkWithoutAnExplicitStop() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = view
        let previous = window.acceptsMouseMovedEvents
        weak var released: StudyInteractionSession?
        do {
            let session = StudyInteractionSession(); released = session
            session.start(host: view)
        }
        XCTAssertNil(released, "The frame callback and tracking area must not create a retain cycle")
        RunLoop.main.run(until: Date().addingTimeInterval(0.03))
        XCTAssertEqual(window.acceptsMouseMovedEvents, previous, "Fallback cleanup restores the window on the main queue")
        window.contentView = nil
    }
}
