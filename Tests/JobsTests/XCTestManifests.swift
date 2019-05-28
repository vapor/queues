import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SchedulerTests.allTests),
        testCase(DateComponentRetrievalTests.allTests),
        testCase(RecurrenceRuleConstraintTests.allTests),
        testCase(RecurrenceRuleTests.allTests),
        testCase(CronTests.allTests)
    ]
}
#endif
