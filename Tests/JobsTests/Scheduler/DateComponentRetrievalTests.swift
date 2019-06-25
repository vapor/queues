import XCTest
@testable import Jobs

final class DateComponentRetrievalTests: XCTestCase {

    func testCalendarIdentifier() {
        let gregorianCalendar = Calendar.init(identifier: .gregorian)
        let iso8601Calendar = Calendar.init(identifier: .gregorian)

        XCTAssertEqual(gregorianCalendar.identifier, Calendar.current.identifier)
        XCTAssertEqual(iso8601Calendar.identifier, Calendar.current.identifier)
    }

    func testDateComponentRetrival() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Sat, Feb 16, 2019
        let feb162019 = dateFormatter.date(from: "2019-02-16T14:42:20")!
        XCTAssertEqual(2019, feb162019.year())
        XCTAssertEqual(2, feb162019.month())
        XCTAssertEqual(16, feb162019.dayOfMonth())
        XCTAssertEqual(14, feb162019.hour())
        XCTAssertEqual(42, feb162019.minute())
        XCTAssertEqual(20, feb162019.second())

        // more advanced date components
        XCTAssertEqual(1, feb162019.quarter())
        XCTAssertEqual(7, feb162019.weekOfYear())
        XCTAssertEqual(3, feb162019.weekOfMonth())
        XCTAssertEqual(7, feb162019.dayOfWeek())
    }

    func testDayOfWeek() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Sat, Feb 16, 2019
        let feb162019 = dateFormatter.date(from: "2019-02-16T14:42:20")!
        XCTAssertEqual(7, feb162019.dayOfWeek())

        // Sun, Feb 17, 2019
        let feb172019 = dateFormatter.date(from: "2019-02-17T14:42:20")!
        XCTAssertEqual(1, feb172019.dayOfWeek())
    }

    func testWeekOfMonth() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Fri, Feb 1, 2019
        let feb012019 = dateFormatter.date(from: "2019-02-01T00:00:00")!
        XCTAssertEqual(1, feb012019.weekOfMonth())

        // Sun, Feb 3, 2019
        let feb032019 = dateFormatter.date(from: "2019-02-03T00:00:00")!
        XCTAssertEqual(2, feb032019.weekOfMonth())

        // Mon, Feb 4, 2019
        let feb042019 = dateFormatter.date(from: "2019-02-04T00:00:00")!
        XCTAssertEqual(2, feb042019.weekOfMonth())

        // Sat, Feb 23, 2019
        let feb232019 = dateFormatter.date(from: "2019-02-23T00:00:00")!
        XCTAssertEqual(4, feb232019.weekOfMonth())

        // Sun, Feb 24, 2019
        let feb242019 = dateFormatter.date(from: "2019-02-24T00:00:00")!
        XCTAssertEqual(5, feb242019.weekOfMonth())

        // Mon, Feb 25, 2019
        let feb252019 = dateFormatter.date(from: "2019-02-25T00:00:00")!
        XCTAssertEqual(5, feb252019.weekOfMonth())
    }

    func testWeekOfYear() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Tue, Jan 1, 2019
        let jan012019 = dateFormatter.date(from: "2019-01-01T00:00:00")!
        XCTAssertEqual(1, jan012019.weekOfYear())

        // Fri, Dec 27, 2019
        let dec272019 = dateFormatter.date(from: "2019-12-27T00:00:00")!
        XCTAssertEqual(52, dec272019.weekOfYear())

        /// Must be careful because even though it Dec 31, 2019 is in the last week of the year
        /// this is because 2019 has 52 weeks + <7 days
        /// weekOfYear returns 1
        /// year returns 2019
        /// yeyearForWeekOfYear returns 2020

        // Tue, Dec 31, 2019
        let dec312019 = dateFormatter.date(from: "2019-12-31T00:00:00")!
        XCTAssertEqual(1, dec312019.weekOfYear())
        XCTAssertEqual(2019, dec312019.year())
        XCTAssertEqual(2020, dec312019.yearForWeekOfYear())
        XCTAssertEqual(52, dec312019.weeksInYear())

        // Fri, Dec 25, 2020
        let dec252020 = dateFormatter.date(from: "2020-12-25T00:00:00")!
        XCTAssertEqual(52, dec252020.weekOfYear())

        // Tue, Dec 31, 2020
        let dec312020 = dateFormatter.date(from: "2020-12-31T00:00:00")!
        XCTAssertEqual(1, dec312020.weekOfYear())
        XCTAssertEqual(2020, dec312020.year())
        XCTAssertEqual(2021, dec312020.yearForWeekOfYear())
        XCTAssertEqual(53, dec312020.weeksInYear())
    }

    func testWeeksInYear() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let jan012019 = dateFormatter.date(from: "2019-02-01T00:00:00")!
        XCTAssertEqual(52, jan012019.weeksInYear())

        let jan012020 = dateFormatter.date(from: "2020-02-01T00:00:00")!
        XCTAssertEqual(53, jan012020.weeksInYear())
    }

    func testQuarters() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // jan 1 2019
        let jan012019 = dateFormatter.date(from: "2019-01-01")!
        XCTAssertEqual(1, jan012019.quarter())

        // apr 1 2019
        let apr012019 = dateFormatter.date(from: "2019-04-01")!
        XCTAssertEqual(2, apr012019.quarter())

        // jul 1 2019
        let jul012019 = dateFormatter.date(from: "2019-07-01")!
        XCTAssertEqual(3, jul012019.quarter())

        // oct 1 2019
        let oct012019 = dateFormatter.date(from: "2019-10-01")!
        XCTAssertEqual(4, oct012019.quarter())
    }

    func testTimeZone() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        guard let timeZoneEST = TimeZone.init(abbreviation: "EST") else {
            XCTFail()
            return
        }

        guard let timeZoneUTC = TimeZone.init(abbreviation: "UTC") else {
            XCTFail()
            return
        }

        // jan 20 2019 EST
        dateFormatter.timeZone = timeZoneEST
        let jan202019EST = dateFormatter.date(from: "2019-01-20T13:00:00")!
        XCTAssertEqual(13, jan202019EST.hour(atTimeZone: timeZoneEST))
        XCTAssertEqual(18, jan202019EST.hour(atTimeZone: timeZoneUTC))

        // jan 20 2019 UTC (5 hours ahead of EST)
        dateFormatter.timeZone = timeZoneUTC
        let jan202019UTC = dateFormatter.date(from: "2019-01-20T13:00:00")!
        XCTAssertEqual(13, jan202019UTC.hour(atTimeZone: timeZoneUTC))
        XCTAssertEqual(8, jan202019UTC.hour(atTimeZone: timeZoneEST))
    }

}
