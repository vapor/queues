import Foundation

extension Date {
    func second() -> Int? {
        return Calendar.current.dateComponents([.second], from: self).second
    }

    func minute() -> Int? {
        return Calendar.current.dateComponents([.minute], from: self).minute
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

    func weekOfMonth() -> Int? {
        return Calendar.current.dateComponents([.weekOfMonth], from: self).weekOfMonth
    }

    func weekOfYear() -> Int? {
        return Calendar.current.dateComponents([.weekOfYear], from: self).weekOfYear
    }

    func month() -> Int? {
        return Calendar.current.dateComponents([.month], from: self).month
    }

    func quarter() -> Int? {
        // Bug: doesn't work in ios 12 and macOS Mojave 10.14
        //return Calendar.current.dateComponents([.quarter], from: self).quarter

        // workaround
        let formatter = DateFormatter()
        formatter.dateFormat = "Q"
        guard let quarter = Int(formatter.string(from: self)) else {
            return nil
        }

        // quarter must be between 1 and 4 (inclusive)
        if quarter < 1 || quarter > 4 {
            return nil
        }

        return quarter
    }

    func year() -> Int? {
        return Calendar.current.dateComponents([.year], from: self).year
    }

    func yearForWeekOfYear() -> Int? {
        return Calendar.current.dateComponents([.yearForWeekOfYear], from: self).yearForWeekOfYear
    }

    // finds the number of weeks in a given year
    func weeksInYear() -> Int? {
        //return NSCalendar.current.range(of: .weekOfYear, in: .yearForWeekOfYear, for: self)?.count
        func p(_ year: Int) -> Int {
            return (year + year/4 - year/100 + year/400) % 7
        }

        guard let year = self.year() else {
            return nil
        }

        if p(year) == 4 || p(year-1) == 3 {
            return 53
        } else {
            return 52
        }
    }

    func resolveCalendarComponent(for ruleTimeUnit: RecurrenceRuleTimeUnit) -> Calendar.Component {
        switch ruleTimeUnit {
        case .second:
            return .second
        case .minute:
            return .minute
        case .hour:
            return .hour
        case .dayOfWeek:
            return .weekday
        case .dayOfMonth:
            return .day
        case .weekOfMonth:
            return .weekOfMonth
        case .weekOfYear:
            return .weekOfYear
        case .month:
            return .month
        case .quarter:
            return .quarter
        case .year:
            return .year
        }
    }

    func resolveDateComponentValue(for ruleTimeUnit: RecurrenceRuleTimeUnit) -> Int? {
        switch ruleTimeUnit {
        case .second:
            return self.second()
        case .minute:
            return self.minute()
        case .hour:
            return self.hour()
        case .dayOfWeek:
            return self.dayOfWeek()
        case .dayOfMonth:
            return self.dayOfMonth()
        case .weekOfMonth:
            return self.weekOfMonth()
        case .weekOfYear:
             return self.weekOfYear()
        case .month:
            return self.month()
        case .quarter:
            return self.quarter()
        case .year:
            return self.year()
        }
    }

    func resolveDateComponentValue(for scheduleTimeUnit: ScheduleTimeUnit) -> Int? {
        switch scheduleTimeUnit {
        case .second:
            return self.second()
        case .minute:
            return self.minute()
        case .hour:
            return self.hour()
        case .day:
            return self.dayOfWeek()
        case .week:
            return self.dayOfWeek()
        case .month:
             return self.month()
        case .year:
            return self.year()
        }
    }

    func componentsToString() -> String {
        var componentString = ""

        componentString += "year: \(String(describing: self.year()))\n"
        componentString += "quarter: \(String(describing: self.quarter()))\n"
        componentString += "month: \(String(describing: self.month()))\n"
        componentString += "weekOfYear: \(String(describing: self.weekOfYear()))\n"
        componentString += "weekOfMonth: \(String(describing: self.weekOfMonth()))\n"
        componentString += "dayOfMonth: \(String(describing: self.dayOfMonth()))\n"
        componentString += "dayOfWeek: \(String(describing: self.dayOfWeek()))\n"
        componentString += "hour: \(String(describing: self.hour()))\n"
        componentString += "minute: \(String(describing: self.minute()))\n"
        componentString += "second: \(String(describing: self.second()))\n"

        return componentString
    }
}
