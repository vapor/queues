//
//  DateExtensionRetrival.swift
//  App
//
//  Created by Reid Nantes on 2019-01-27.
//

import Foundation

extension Date {
    func second() -> Int? {
        return Calendar.current.dateComponents([.second], from: self).second
    }

    func minute() -> Int? {
        return Calendar.current.dateComponents([.day], from: self).minute
    }

    func hour() -> Int? {
        return Calendar.current.dateComponents([.hour], from: self).hour
    }

    func dayOfWeek() -> Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }

    func dayOfMonth() -> Int? {
        return Calendar.current.dateComponents([.day], from: self).day
    }

    func month() -> Int? {
        return Calendar.current.dateComponents([.month], from: self).month
    }

    func year() -> Int? {
        return Calendar.current.dateComponents([.year], from: self).year
    }
}
