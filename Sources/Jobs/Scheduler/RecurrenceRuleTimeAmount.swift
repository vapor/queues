import Foundation

public enum RecurrenceRuleTimeUnit: CaseIterable {
    case second
    case minute
    case hour
    case dayOfWeek
    case dayOfMonth
    case weekOfMonth
    case weekOfYear
    case month
    case quarter
    case year
}

public struct RecurrenceRuleTimeAmount {
    /// The seconds representation of the `ScheduleTimeAmount`.
    public let amount: Int
    public let timeUnit: RecurrenceRuleTimeUnit

    private init(_ amount: Int, timeUnit: RecurrenceRuleTimeUnit) {
        self.amount = amount
        self.timeUnit = timeUnit
    }

    public static func seconds(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .second)
    }

    public static func minutes(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .minute)
    }

    public static func hours(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .hour)
    }

    public static func daysOfWeek(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .dayOfWeek)
    }

    public static func daysOfMonth(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .dayOfMonth)
    }

    public static func weeksOfMonth(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .weekOfMonth)
    }

    public static func weeksOfYear(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .weekOfYear)
    }

    public static func months(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .month)
    }

    public static func quarters(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .quarter)
    }

    public static func years(_ amount: Int) -> RecurrenceRuleTimeAmount {
        return RecurrenceRuleTimeAmount(amount, timeUnit: .year)
    }
}
