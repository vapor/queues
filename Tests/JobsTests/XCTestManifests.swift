import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DateComponentRetrievalTests.allTests),
        testCase(JobSchedulerTests.allTests),
        testCase(JobsTests.allTests)
    ]
}
#endif
