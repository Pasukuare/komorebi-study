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


@MainActor final class CalendarPigmentTests: XCTestCase {
    func testSharesZeroOneTwoAndManyRemainStable() throws {
        let store = try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "CalendarTest.\(UUID())")!)
        let start = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-86400)
        let interval = DateInterval(start: start, duration: 86400)
        XCTAssertTrue(store.calendarShares(in: interval).isEmpty)
        let colors = ["Cielo", "Rosa", "Lavanda", "Terra", "Muschio", "Tramonto"]
        for (index, seconds) in [10800.0, 3600, 30, 60, 90, 120].enumerated() {
            let subject = Subject(name: "Materia \(index)", color: colors[index]); store.context.insert(subject)
            store.context.insert(StudySession(start: start, end: start.addingTimeInterval(seconds), duration: seconds, subjectID: subject.id, subjectName: subject.name, mode: "Cronometro", pause: 0))
            store.refresh()
            let shares = store.calendarShares(in: interval)
            XCTAssertEqual(shares.count, index + 1)
            XCTAssertEqual(shares.reduce(0) { $0 + $1.fraction }, 1, accuracy: 0.00001)
            if index == 0 { XCTAssertEqual(shares[0].fraction, 1) }
            if index == 1 { XCTAssertEqual(shares[0].fraction, 0.75); XCTAssertEqual(shares[1].fraction, 0.25) }
            XCTAssertEqual(shares.map(\.id), store.calendarShares(in: interval).map(\.id))
            let locations = calendarPigmentStops(shares).map(\.location)
            XCTAssertEqual(locations, locations.sorted()); XCTAssertEqual(locations.first, 0); XCTAssertEqual(locations.last, 1)
        }
    }
    func testMeasuredIntervalsAcrossMidnightExcludePause() throws {
        let store = try StudyStore(inMemory: true, defaults: UserDefaults(suiteName: "CalendarTest.\(UUID())")!)
        let midnight = Calendar.current.startOfDay(for: Date())
        let subject = store.subjects.first!
        let session = StudySession(start: midnight.addingTimeInterval(-3600), end: midnight.addingTimeInterval(3600), duration: 2700, subjectID: subject.id, subjectName: subject.name, mode: "Cronometro", pause: 4500)
        session.activityData = try JSONEncoder().encode([StudyInterval(start: midnight.addingTimeInterval(-1800), end: midnight), StudyInterval(start: midnight.addingTimeInterval(2700), end: midnight.addingTimeInterval(3600))])
        store.context.insert(session); store.refresh()
        XCTAssertEqual(store.calendarShares(in: DateInterval(start: midnight.addingTimeInterval(-86400), end: midnight)).first!.seconds, 1800)
        XCTAssertEqual(store.calendarShares(in: DateInterval(start: midnight, duration: 86400)).first!.seconds, 900)
        XCTAssertEqual(session.duration, 2700)
    }
}
