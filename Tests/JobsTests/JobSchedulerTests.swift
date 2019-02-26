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
    }

    static var allTests = [
        ("testReccurrenceRuleSimple", testReccurrenceRuleSimple),
    ]
}
