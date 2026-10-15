import XCTest
@testable import KomorebiStudy
final class TimerTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1000)
    func timer(target: Double? = 1500) -> ActiveTimer { ActiveTimer(start: start, target: target, subjectName: "Test", mode: .pomodoro) }
    func testLostTicksAndSleep() { let t = timer(); XCTAssertEqual(t.elapsed(at: start.addingTimeInterval(900)), 900); XCTAssertEqual(t.displayed(at: start.addingTimeInterval(2000)), 0) }
    func testPauseResume() { var t = timer(); t.pause(at: start.addingTimeInterval(100)); XCTAssertEqual(t.elapsed(at: start.addingTimeInterval(500)), 100); t.resume(at: start.addingTimeInterval(600)); XCTAssertEqual(t.elapsed(at: start.addingTimeInterval(700)), 200); XCTAssertEqual(t.pauseDuration, 500) }
    func testRepeatedPauseIsIdempotent() { var t = timer(); t.pause(at: start.addingTimeInterval(100)); t.pause(at: start.addingTimeInterval(200)); t.resume(at: start.addingTimeInterval(300)); t.resume(at: start.addingTimeInterval(500)); XCTAssertEqual(t.pauseDuration, 200) }
    func testRecoveryRoundTrip() throws { var t = timer(); t.pause(at: start.addingTimeInterval(100)); let recovered = try JSONDecoder().decode(ActiveTimer.self, from: JSONEncoder().encode(t)); XCTAssertEqual(recovered.elapsed(at: start.addingTimeInterval(99999)), 100); XCTAssertEqual(recovered.id, t.id) }
    func testStopwatchHasNoLimit() { let t = timer(target: nil); XCTAssertEqual(t.displayed(at: start.addingTimeInterval(36000)), 36000) }
    func testClockDoesNotGoNegative() { XCTAssertEqual(timer().elapsed(at: start.addingTimeInterval(-100)), 0) }
}
