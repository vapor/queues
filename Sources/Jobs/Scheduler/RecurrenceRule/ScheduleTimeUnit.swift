import Foundation

public enum ScheduleTimeUnit: CaseIterable {
    case second
    case minute
    case hour
    case dayOfWeek
    case day
    case week
    case month
    case quarter
    case year
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
