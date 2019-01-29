//
//  RecurrenceTimeAmount.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation

public struct ScheduleTimeAmount {
    /// The seconds representation of the `ScheduleTimeAmount`.
    public let amount: Int
    public let timeUnit: ScheduleTimeUnit


    private init(_ amount: Int, timeUnit: ScheduleTimeUnit) {
        self.amount = amount
        self.timeUnit = timeUnit
    }

    public static func seconds(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount, timeUnit: .second)
    }

    public static func minutes(_ amount: Int) -> ScheduleTimeAmount{
        return ScheduleTimeAmount(amount, timeUnit: .minute)
    }

    public static func hours(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount, timeUnit: .hour)
    }

    public static func days(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount, timeUnit: .day)
    }

    public static func weeks(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount, timeUnit: .week)
    }

    public static func months(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount, timeUnit: .month)
    }

    public static func years(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount, timeUnit: .year)
    }
}
