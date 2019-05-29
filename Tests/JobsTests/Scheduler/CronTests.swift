import XCTest
import NIO
@testable import Jobs

final class CronTests: XCTestCase {

    func testInvalidCronStrings() throws {
        // test not enough fields
        XCTAssertThrowsError(try Scheduler().cron("* * * *"))

        // test too many fields
        XCTAssertThrowsError(try Scheduler().cron("*/5 * 4 * 1-3 1"))
        XCTAssertThrowsError(try Scheduler().cron("*/5 * 4 * 1-3 abc"))

        // test incorrect fields
        XCTAssertThrowsError(try Scheduler().cron("-1 * * * 1"))
        XCTAssertThrowsError(try Scheduler().cron("1-2-3 * * * 1"))
        XCTAssertThrowsError(try Scheduler().cron("21* * * 1"))

        // test fields out of range
        XCTAssertThrowsError(try Scheduler().cron("-1 * * * *"))
        XCTAssertThrowsError(try Scheduler().cron("* -1 * * *"))
        XCTAssertThrowsError(try Scheduler().cron("* * 0 * *"))
        XCTAssertThrowsError(try Scheduler().cron("* * * 0 *"))
        XCTAssertThrowsError(try Scheduler().cron("* * * * -1"))
        XCTAssertThrowsError(try Scheduler().cron("60 * * * *"))
        XCTAssertThrowsError(try Scheduler().cron("* 24 * * *"))
        XCTAssertThrowsError(try Scheduler().cron("* * 32 * *"))
        XCTAssertThrowsError(try Scheduler().cron("* * * 13 *"))
        XCTAssertThrowsError(try Scheduler().cron("* * * * 7"))
    }

    func testCronJobParser() throws {
        // test good cron strings
        XCTAssertNoThrow(try Scheduler().cron("*/5 * 4 * 1-3"))
        XCTAssertNoThrow(try Scheduler().cron("1 2 3 4 5"))
        XCTAssertNoThrow(try Scheduler().cron("*/1 */2 */3 */4 */5"))
        XCTAssertNoThrow(try Scheduler().cron("1-5 1-5 1-5 1-5 1-5"))
        XCTAssertNoThrow(try Scheduler().cron("1,3,5 1,3,5 1,3,5 1,3,5 1,3,5"))

        // test all stars
        XCTAssertNoThrow(try Scheduler().cron("* * * * *"))

        // test spaces
        XCTAssertNoThrow(try Scheduler().cron("*/5    *   4 * 1-3  "))
    }

    static var allTests = [
        ("testInvalidCronStrings", testInvalidCronStrings),
        ("testCronJobParser", testCronJobParser)
    ]

}
