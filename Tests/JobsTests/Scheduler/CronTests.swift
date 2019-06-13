import XCTest
import NIO
@testable import Jobs

final class CronTests: XCTestCase {

    func testInvalidCronStrings() throws {
        var config = JobsConfiguration()
        config.schedule(Cleanup()).hourly().at(17)

        // test not enough fields
        //XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* * * *"))

        // test too many fields
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("*/5 * 4 * 1-3 1"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("*/5 * 4 * 1-3 abc"))
//
//        // test incorrect fields
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("-1 * * * 1"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("1-2-3 * * * 1"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("21* * * 1"))
//
//        // test fields out of range
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("-1 * * * *"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* -1 * * *"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* * 0 * *"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* * * 0 *"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* * * * -1"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("60 * * * *"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* 24 * * *"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* * 32 * *"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* * * 13 *"))
//        XCTAssertThrowsError(try config.schedule(Cleanup()).cron("* * * * 7"))
    }

    func testCronJobParser() throws {
        var config = JobsConfiguration()

        // test good cron strings
//        XCTAssertNoThrow(try config.schedule(Cleanup()).cron("*/5 * 4 * 1-3"))
//        XCTAssertNoThrow(try config.schedule(Cleanup()).cron("1 2 3 4 5"))
//        XCTAssertNoThrow(try config.schedule(Cleanup()).cron("*/1 */2 */3 */4 */5"))
//        XCTAssertNoThrow(try config.schedule(Cleanup()).cron("1-5 1-5 1-5 1-5 1-5"))
//        XCTAssertNoThrow(try config.schedule(Cleanup()).cron("1,3,5 1,3,5 1,3,5 1,3,5 1,3,5"))
//
//        // test all stars
//        XCTAssertNoThrow(try config.schedule(Cleanup()).cron("* * * * *"))
//
//        // test spaces
//        XCTAssertNoThrow(try config.schedule(Cleanup()).cron("*/5    *   4 * 1-3  "))
    }

    static var allTests = [
        ("testInvalidCronStrings", testInvalidCronStrings),
        ("testCronJobParser", testCronJobParser)
    ]

}
