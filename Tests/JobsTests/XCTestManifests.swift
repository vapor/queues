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

extension DateComponentRetrievalTests {
    static let __allTests = [
        ("testCalendarIdentifier", testCalendarIdentifier),
        ("testDateComponentRetrival", testDateComponentRetrival),
        ("testDayOfWeek", testDayOfWeek),
        ("testWeekOfMonth", testWeekOfMonth),
        ("testWeekOfYear", testWeekOfYear),
        ("testWeeksInYear", testWeeksInYear),
        ("testQuarters", testQuarters),
        ("testTimeZone", testTimeZone)
    ]
}

extension RecurrenceRuleConstraintTests {
    static let __allTests = [
        ("testRecurrenceRuleCreation", testRecurrenceRuleCreation),
        ("testRecurrenceRuleCreationSet", testRecurrenceRuleCreationSet),
        ("testRecurrenceRuleCreationRange", testRecurrenceRuleCreationRange),
        ("testRecurrenceRuleCreationStep", testRecurrenceRuleCreationStep)
    ]
}

extension RecurrenceRuleTests {
    static let __allTests = [
        ("testReccurrenceRuleEvaluationSimple", testReccurrenceRuleEvaluationSimple),
        ("testReccurrenceRuleEvaluationStepSimple", testReccurrenceRuleEvaluationStepSimple),
        ("testReccurrenceRuleEvaluationStepNotDivisible", testReccurrenceRuleEvaluationStepNotDivisible),
        ("testReccurrenceRuleEvaluationTimezone", testReccurrenceRuleEvaluationTimezone),
        ("testNextDateWhereSimple", testNextDateWhereSimple),
        ("testNextDateWhere", testNextDateWhere),
        ("testResolveNextDateThatSatisfiesRule", testResolveNextDateThatSatisfiesRule),
        ("testResolveNextDateThatSatisfiesRuleLeapYear", testResolveNextDateThatSatisfiesRuleLeapYear),
        ("testResolveNextDateThatSatisfiesRuleImpossible", testResolveNextDateThatSatisfiesRuleLeapYear)
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
        testCase(DateComponentRetrievalTests.__allTests),
        testCase(RecurrenceRuleConstraintTests.__allTests),
        testCase(RecurrenceRuleTests.__allTests),
    ]
}
#endif
