import XCTest

extension JobStorageTests {
    static let __allTests = [
        ("testStringRepresentationIsValidJSON", testStringRepresentationIsValidJSON),
    ]
}

extension JobsConfigTests {
    static let __allTests = [
        ("testAddingAlreadyRegistratedJobsAreIgnored", testAddingAlreadyRegistratedJobsAreIgnored),
        ("testAddingJobs", testAddingJobs),
    ]
}

extension JobsTests {
    static let __allTests = [
        ("testStub", testStub),
    ]
}

extension QueueNameTests {
    static let __allTests = [
        ("testKeyIsGeneratedCorrectly", testKeyIsGeneratedCorrectly),
    ]
}


// Scheduler tests
extension SchedulerTests {
    static let __allTests = [
        ("testSchedulerCustomConstriants", testSchedulerCustomConstriants),
        ("testScheduler", testScheduler)
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(JobStorageTests.__allTests),
        testCase(JobsConfigTests.__allTests),
        testCase(JobsTests.__allTests),
        testCase(QueueNameTests.__allTests),
        testCase(SchedulerTests.__allTests),
    ]
}
#endif
