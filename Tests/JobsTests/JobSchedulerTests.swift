import XCTest
@testable import Jobs

final class JobSchedulerTests: XCTestCase {
    func testReccurrenceRuleSimple() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(abbreviation: "EST")

        let reccurrenceRule = try RecurrenceRule().atMonth(2).atHour(3)

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date1))

        // Fri, Feb 1, 2019 03:00:01
        let date2 = dateFormatter.date(from: "2019-02-01T03:00:01")!
        XCTAssertEqual(false, try reccurrenceRule.evaluate(date: date2))

        // Fri, Feb 1, 2019 04:00:00
        let date3 = dateFormatter.date(from: "2019-02-01T04:00:00")!
        XCTAssertEqual(false, try reccurrenceRule.evaluate(date: date3))
    }

    func testReccurrenceRuleStepSimple() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(abbreviation: "EST")

        let reccurrenceRule = try RecurrenceRule().atMonth(2).every(.minutes(15))

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date1))

        // Fri, Feb 1, 2019 03:15:00
        let date2 = dateFormatter.date(from: "2019-02-01T03:15:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date2))

        // Fri, Feb 1, 2019 03:30:00
        let date3 = dateFormatter.date(from: "2019-02-01T03:30:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date3))

        // Fri, Feb 1, 2019 03:45:00
        let date4 = dateFormatter.date(from: "2019-02-01T03:45:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date4))

        // Fri, Feb 1, 2019 04:45:00
        let date5 = dateFormatter.date(from: "2019-02-01T04:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date5))
    }

    func testReccurrenceRuleStepNotDivisible() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(abbreviation: "EST")

        let reccurrenceRule = try RecurrenceRule().atMonth(2).every(.minutes(22))

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date1))

        // Fri, Feb 1, 2019 03:22:00
        let date2 = dateFormatter.date(from: "2019-02-01T03:22:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date2))

        // Fri, Feb 1, 2019 03:44:00
        let date3 = dateFormatter.date(from: "2019-02-01T03:44:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date3))

        // Fri, Feb 1, 2019 04:00:00
        let date4 = dateFormatter.date(from: "2019-02-01T04:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date4))

        // Fri, Feb 1, 2019 04:04:00
        // should evaluate to false beacuse the minute step constraint is multiples within hour
        // ex step constraint of 22 minutes [3:00, 3:22, 3:44, 4:00, 4:22, ...]
        let date5 = dateFormatter.date(from: "2019-02-01T04:06:00")!
        XCTAssertEqual(false, try reccurrenceRule.evaluate(date: date5))

    }

    func testNextDateWhere() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(abbreviation: "EST")

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        /// should reset values less than month to their default values
        let date2 = try date1.nextDateWhere(next: .month, is: 4)!
        XCTAssertEqual(dateFormatter.date(from: "2019-04-01T00:00:00")!, date2)

        let date3 = try date2.nextDateWhere(next: .dayOfMonth, is: 26)!
        /// should reset values less than dayOfMonth to their default values
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:00:00")!, date3)

        let date4 = try date3.nextDateWhere(next: .minute, is: 33)!
        /// should reset values less than dayOfMonth to their default values
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:33:00")!, date4)
    }

    func testResolveNextDateThatSatisfiesRule() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(abbreviation: "EST")

        let reccurrenceRule = try RecurrenceRule().atMonth(4).atDayOfMonth(26).every(.minutes(33))

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        let date2 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(date: date1)
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:00:00")!, date2)

        let date3 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(date: date2)
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:33:00")!, date3)
    }

    func testResolveNextDateThatSatisfiesRuleLeapYear() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(abbreviation: "EST")

        let reccurrenceRule = try RecurrenceRule().atMonth(2).atDayOfMonth(29)

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        let date2 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(date: date1)
        XCTAssertEqual(dateFormatter.date(from: "2020-02-29T00:00:00")!, date2)
    }

    static var allTests = [
        ("testReccurrenceRuleSimple", testReccurrenceRuleSimple),
        ("testReccurrenceRuleStepSimple", testReccurrenceRuleStepSimple),
        ("testReccurrenceRuleStepNotDivisible", testReccurrenceRuleStepNotDivisible),
        ("testNextDateWhere", testNextDateWhere),
        ("testResolveNextDateThatSatisfiesRule", testResolveNextDateThatSatisfiesRule),
        ("testResolveNextDateThatSatisfiesRuleLeapYear", testResolveNextDateThatSatisfiesRuleLeapYear)
    ]
}
