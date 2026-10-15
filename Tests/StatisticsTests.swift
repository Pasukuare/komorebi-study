import XCTest
@testable import KomorebiStudy
final class StatisticsTests: XCTestCase {
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; c.firstWeekday = 2; c.minimumDaysInFirstWeek = 4; return c
    }
    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
    func testCurrentWeekComparesSameElapsedDays() {
        let now = date(2026, 9, 15, 12)
        let range = StatisticsRange(period: .week, anchor: now, now: now, calendar: calendar)
        XCTAssertEqual(range.days, 2)
        XCTAssertEqual(range.previousComparable?.start, date(2026, 9, 7))
        XCTAssertEqual(range.previousComparable?.end, date(2026, 9, 8, 12))
    }
    func testHistoricalMonthUsesWholeMonth() {
        let range = StatisticsRange(period: .month, anchor: date(2026, 8, 10), now: date(2026, 9, 15), calendar: calendar)
        XCTAssertEqual(range.days, 31)
        XCTAssertEqual(range.previousComparable?.start, date(2026, 7, 1))
        XCTAssertEqual(range.previousComparable?.end, date(2026, 8, 1))
    }
    func testAlwaysIncludesEarliestSession() {
        let range = StatisticsRange(period: .all, anchor: date(2026, 9, 15), now: date(2026, 9, 15, 12), firstDate: date(2024, 3, 5, 14), calendar: calendar)
        XCTAssertEqual(range.interval.start, date(2024, 3, 5))
        XCTAssertNil(range.previousComparable)
    }
    func testShortPreviousMonthDoesNotSpillIntoCurrentMonth() {
        let range = StatisticsRange(period: .month, anchor: date(2026, 3, 31), now: date(2026, 3, 31, 12), calendar: calendar)
        XCTAssertEqual(range.previousComparable?.end, date(2026, 3, 1))
    }
}
