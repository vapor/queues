import Foundation

enum RecurrenceRuleError: Error {
    case atLeastOneRecurrenceRuleConstraintRequiredToIntialize
    case lowerBoundGreaterThanUpperBound
    case noSetConstraintForRecurrenceRuleTimeUnit
    case couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
    case noConstraintsSetForRecurrenceRule
    case coundNotResolveNextInstanceWithin1000Years
    case couldNotResolveYearConstraitFromDate
    case couldNotResloveNextValueFromConstraint
    case ruleInsatiable
    case couldNotParseHourAndMinuteFromString
    case startHourAndMinuteGreaterThanEndHourAndMinute
}

/// Defines the rule for when to run a job based on the given constraints
///
/// - warning: RecurrenceRule only supports the Gregorian calendar (i.e. Calendar.identifier.gregorian or Calendar.identifier.iso8601)
///
/// - Note: RecurrenceRule uses the local TimeZone as default
internal struct RecurrenceRule {
    internal enum TimeUnit: CaseIterable {
        case second
        case minute
        case hour
        case dayOfWeek
        case dayOfMonth
        case month
        case quarter
        case year
    }

    var timeZone: TimeZone

    private(set) var yearConstraint: YearRecurrenceRuleConstraint?
    private(set) var quarterConstraint: QuarterRecurrenceRuleConstraint?
    private(set) var monthConstraint: MonthRecurrenceRuleConstraint?
    private(set) var dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint?
    private(set) var dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint?
    private(set) var hourConstraint: HourRecurrenceRuleConstraint?
    private(set) var minuteConstraint: MinuteRecurrenceRuleConstraint?
    private(set) var secondConstraint: SecondRecurrenceRuleConstraint?

    private let timeUnitOrder: [RecurrenceRule.TimeUnit] = [
        .year,
        .quarter,
        .month,
        .dayOfMonth,
        .dayOfWeek,
        .hour,
        .minute,
        .second
    ]

    init(timeZone: TimeZone = TimeZone.current) {
        self.timeZone = timeZone
    }

    init(yearConstraint: YearRecurrenceRuleConstraint? = nil,
         monthConstraint: MonthRecurrenceRuleConstraint? = nil,
         dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint? = nil,
         dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint? = nil,
         hourConstraint: HourRecurrenceRuleConstraint? = nil,
         minuteConstraint: MinuteRecurrenceRuleConstraint? = nil,
         secondConstraint: SecondRecurrenceRuleConstraint? = nil,
         timeZone: TimeZone = TimeZone.current) throws {
        self.timeZone = timeZone
        self.yearConstraint = yearConstraint
        self.monthConstraint = monthConstraint
        self.dayOfMonthConstraint = dayOfMonthConstraint
        self.dayOfWeekConstraint = dayOfWeekConstraint
        self.hourConstraint = hourConstraint
        self.minuteConstraint = minuteConstraint
        self.secondConstraint = secondConstraint
    }

    internal mutating func setYearConstraint(_ yearConstraint: YearRecurrenceRuleConstraint) {
        self.yearConstraint = yearConstraint
    }

    internal mutating func setQuarterConstraint(_ quarterConstraint: QuarterRecurrenceRuleConstraint) {
        self.quarterConstraint = quarterConstraint
    }

    internal mutating func setMonthConstraint(_ monthConstraint: MonthRecurrenceRuleConstraint) {
        self.monthConstraint = monthConstraint
    }

    internal mutating func setDayOfMonthConstraint(_ dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint) {
        self.dayOfMonthConstraint = dayOfMonthConstraint
    }

    internal mutating func setDayOfWeekConstraint(_ dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint) {
        self.dayOfWeekConstraint = dayOfWeekConstraint
    }

    internal mutating func setHourConstraint(_ hourConstraint: HourRecurrenceRuleConstraint) {
        self.hourConstraint = hourConstraint
    }

    internal mutating func setMinuteConstraint(_ minuteConstraint: MinuteRecurrenceRuleConstraint) {
        self.minuteConstraint = minuteConstraint
    }

    internal mutating func setSecondConstraint(_ secondConstraint: SecondRecurrenceRuleConstraint) {
        self.secondConstraint = secondConstraint
    }

    ///  Sets the timeZone used by rule constraintss
    ///
    /// - Parameter timeZone: The TimeZone constraints reference against
    internal mutating func usingTimeZone(_ timeZone: TimeZone) {
        self.timeZone = timeZone
    }
}
