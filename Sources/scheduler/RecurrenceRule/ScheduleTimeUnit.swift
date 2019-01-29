//
//  ScheduleTimeUnits.swift
//  App
//
//  Created by Reid Nantes on 2019-01-27.
//

import Foundation

public enum ScheduleTimeUnit {
    case second
    case minute
    case hour
    case day
    case week
    case month
    case year
}

public enum RecurrenceRuleTimeUnit: CaseIterable {
    case year
    case month
    case dayOfMonth
    case dayOfWeek
    case hour
    case minute
    case second
}
