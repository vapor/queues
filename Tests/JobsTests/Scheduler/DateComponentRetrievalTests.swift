import XCTest
@testable import Jobs

final class DateComponentRetrievalTests: XCTestCase {

    func testCalendarIdentifier() {
        let gregorianCalendar = Calendar.init(identifier: .gregorian)
        let iso8601Calendar = Calendar.init(identifier: .gregorian)

        XCTAssertEqual(gregorianCalendar.identifier, Calendar.current.identifier)
        XCTAssertEqual(iso8601Calendar.identifier, Calendar.current.identifier)
    }

    static var allTests = [
        ("testCalendarIdentifier", testCalendarIdentifier),
    ]
}
