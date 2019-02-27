import Foundation

public enum ScheduleTimeUnit: CaseIterable {
    case second
    case minute
    case hour
    case day
    case week
    case month
    case year
}

// inclusive
func resolveValidUpperBound(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> Int? {
    switch ruleTimeUnit {
    case .second:
        return 59
    case .minute:
        return 59
    case .hour:
        return 23
    case .dayOfWeek:
        return 7
    case .dayOfMonth:
        return 31
    case .weekOfMonth:
        return 5
    case .weekOfYear:
        return 52
    case .month:
        return 12
    case .quarter:
        return 4
    case .year:
        return nil
    }
}

// inclusive
func resolveValidLowerBound(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> Int? {
    switch ruleTimeUnit {
    case .second:
        return 0
    case .minute:
        return 0
    case .hour:
        return 0
    case .dayOfWeek:
        return 1
    case .dayOfMonth:
        return 1
    case .weekOfMonth:
        return 1
    case .weekOfYear:
        return 1
    case .month:
        return 1
    case .quarter:
        return 1
    case .year:
        return 1970
    }
}


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

let recurrenceRuleTimeUnits: [RecurrenceRuleTimeUnit] = [
    .year,
    .quarter,
    .month,
    .weekOfYear,
    .weekOfMonth,
    .dayOfMonth,
    .dayOfWeek,
    .hour,
    .minute,
    .second
]


