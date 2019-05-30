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

extension CronTests {
    static let __allTests = [
        ("testInvalidCronStrings", testInvalidCronStrings),
        ("testCronJobParser", testCronJobParser)
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
        testCase(CronTests.__allTests),
    ]
}
#endif
