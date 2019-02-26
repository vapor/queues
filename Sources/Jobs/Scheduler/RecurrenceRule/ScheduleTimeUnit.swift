//
//  ScheduleTimeUnits.swift
//  App
//
//  Created by Reid Nantes on 2019-01-27.
//

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
