import Foundation

extension Calendar {
    enum CalendarExtensionError: Error {
        case counldNotFindLowerBoundForRecurrenceRuleTimeUnit
        case counldNotFindUpperBoundForRecurrenceRuleTimeUnit
    }

    /// validates a value is within the bounds
    ///
    /// - Parameters:
    ///   - ruleTimeUnit: <#ruleTimeUnit description#>
    ///   - value: <#value description#>
    /// - Returns: <#return value description#>
    public func validate(ruleTimeUnit: RecurrenceRuleTimeUnit, value: Int) throws -> Bool {
        if let validLowerBound = try self.lowerBound(for: ruleTimeUnit) {
            if value < validLowerBound {
                return false
            }
        }

        if let validUpperBound = try Calendar.current.upperBound(for: ruleTimeUnit) {
            if value > validUpperBound {
                return false
            }
        }

        return true
    }

    public func rangeOfValidBounds(_ ruleTimeUnit: RecurrenceRuleTimeUnit) throws -> Int? {
        if let validLowerBound = try lowerBound(for: ruleTimeUnit), let validUpperBound = try upperBound(for: ruleTimeUnit) {
            return validUpperBound - validLowerBound
        } else {
            return nil
        }
    }

    ///  Resolves The lower bound (inclusive) of a given RecurrenceRuleTimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRuleTimeUnit
    /// - Returns: The lower bound(inclusive)
    public func lowerBound(for ruleTimeUnit: RecurrenceRuleTimeUnit) throws -> Int? {
        switch self.identifier {
        case .gregorian, .iso8601:
            return gregorianLowerBound(for: ruleTimeUnit)
        default:
            throw CalendarExtensionError.counldNotFindLowerBoundForRecurrenceRuleTimeUnit
        }
    }

    ///  Resolves The upper bound (inclusive) of a given RecurrenceRuleTimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRuleTimeUnit
    /// - Returns: The upper bound(inclusive)
    public func upperBound(for ruleTimeUnit: RecurrenceRuleTimeUnit) throws -> Int? {
        switch self.identifier {
        case .gregorian, .iso8601:
            return gregorianUpperBound(for: ruleTimeUnit)
        default:
            throw CalendarExtensionError.counldNotFindUpperBoundForRecurrenceRuleTimeUnit
        }
    }

    private func gregorianLowerBound(for ruleTimeUnit: RecurrenceRuleTimeUnit) -> Int? {
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

    private func gregorianUpperBound(for ruleTimeUnit: RecurrenceRuleTimeUnit) -> Int? {
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

}

extension Date {
    enum DateExtensionError: Error {
        case couldNotFindNextDate
        case couldNotValidateDateComponentValue
        case couldNotSetDateComponentToDefaultValue
    }

    private func calendar(atTimeZone timeZone: TimeZone? = nil) -> Calendar {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }

        return calendar
    }

    public func second(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.second], from: self).second
    }

    public func minute(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.minute], from: self).minute
    }

    public func hour(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.hour], from: self).hour
    }

    public func dayOfWeek(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.weekday], from: self).weekday
    }

    public func dayOfMonth(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.day], from: self).day
    }

    public func weekOfMonth(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.weekOfMonth], from: self).weekOfMonth
    }

    public func weekOfYear(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.weekOfYear], from: self).weekOfYear
    }

    public func month(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.month], from: self).month
    }

    public func quarter(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        // Bug: doesn't work in ios 12 and macOS Mojave 10.14
        // return Calendar.current.dateComponents([.quarter], from: self).quarter

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

    public func year(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.year], from: self).year
    }

    public func yearForWeekOfYear(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).dateComponents([.yearForWeekOfYear], from: self).yearForWeekOfYear
    }

    /// finds the number of weeks in a given year
    public func weeksInYear() -> Int? {
        // return NSCalendar.current.range(of: .weekOfYear, in: .yearForWeekOfYear, for: self)?.count
        func weeksInYearFormula(_ year: Int) -> Int {
            return (year + year/4 - year/100 + year/400) % 7
        }

        guard let year = self.year() else {
            return nil
        }

        if weeksInYearFormula(year) == 4 || weeksInYearFormula(year-1) == 3 {
            return 53
        } else {
            return 52
        }
    }

    /// Resolves the Calendar Component for a given RecurrenceRuleTimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRuleTimeUnit
    /// - Returns: The associated Calendar.Component
    private func resolveCalendarComponent(for ruleTimeUnit: RecurrenceRuleTimeUnit) -> Calendar.Component {
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

    /// resolve the Calendar Component for a given RecurrenceRuleTimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRuleTimeUnits
    /// - Returns: The associated Calendar Component
    public func dateComponentValue(for ruleTimeUnit: RecurrenceRuleTimeUnit, atTimeZone timeZone: TimeZone? = nil) -> Int? {
        switch ruleTimeUnit {
        case .second:
            return self.second(atTimeZone: timeZone)
        case .minute:
            return self.minute(atTimeZone: timeZone)
        case .hour:
            return self.hour(atTimeZone: timeZone)
        case .dayOfWeek:
            return self.dayOfWeek(atTimeZone: timeZone)
        case .dayOfMonth:
            return self.dayOfMonth(atTimeZone: timeZone)
        case .weekOfMonth:
            return self.weekOfMonth(atTimeZone: timeZone)
        case .weekOfYear:
            return self.weekOfYear(atTimeZone: timeZone)
        case .month:
            return self.month(atTimeZone: timeZone)
        case .quarter:
            return self.quarter(atTimeZone: timeZone)
        case .year:
            return self.year(atTimeZone: timeZone)
        }
    }

    /// resolve the Date Component value for a given RecurrenceRuleTimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRuleTimeUnits
    /// - Returns: The associated Date Component Value
    public func dateComponentValue(for scheduleTimeUnit: ScheduleTimeUnit, atTimeZone timeZone: TimeZone? = nil) -> Int? {
        switch scheduleTimeUnit {
        case .second:
            return self.second(atTimeZone: timeZone)
        case .minute:
            return self.minute(atTimeZone: timeZone)
        case .hour:
            return self.hour(atTimeZone: timeZone)
        case .dayOfWeek:
            return self.dayOfWeek(atTimeZone: timeZone)
        case .day:
            return self.dayOfMonth(atTimeZone: timeZone)
        case .week:
            return self.dayOfWeek(atTimeZone: timeZone)
        case .month:
            return self.month(atTimeZone: timeZone)
        case .quarter:
            return self.quarter(atTimeZone: timeZone)
        case .year:
            return self.year(atTimeZone: timeZone)
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

    /// Returns the amount of years from another date
    public func years(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.year], from: date, to: self).year
    }

    /// Returns the amount of quarters from another date
    public func quarters(from date: Date) -> Int? {
        // bug in quarter on ios12 and macOS 10.14 mojave 
        //return Calendar.current.dateComponents([.quarter], from: date, to: self).quarter
        let formatter = DateFormatter()
        formatter.dateFormat = "Q"
        return Int(formatter.string(from: date))
    }

    /// Returns the amount of months from another date
    public func months(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.month], from: date, to: self).month
    }

    /// Returns the amount of weeks from another date
    public func weeks(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth
    }

    /// Returns the amount of days from another date
    public func days(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.day], from: date, to: self).day
    }

    /// Returns the amount of hours from another date
    public func hours(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour
    }

    /// Returns the amount of minutes from another date
    public func minutes(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute
    }

    /// Returns the amount of seconds from another date
    public func seconds(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.second], from: date, to: self).second
    }

    public func dateByIncrementing(calendarComponent: Calendar.Component) -> Date? {
        return Calendar.current.date(byAdding: calendarComponent, value: 1, to: self)
    }

    public func dateByIncrementing(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> Date? {
        let calendarComponent = resolveCalendarComponent(for: ruleTimeUnit)
        return dateByIncrementing(calendarComponent: calendarComponent)
    }

    public func dateOfNextQuarter() -> Date? {
        return Calendar.current.date(byAdding: .quarter, value: 1, to: self)
    }

    public func nextDate(where ruleTimeUnit: RecurrenceRuleTimeUnit, is nextValue: Int, atTimeZone timeZone: TimeZone? = nil) throws -> Date? {
        guard let currentValue = self.dateComponentValue(for: ruleTimeUnit) else {
            throw DateExtensionError.couldNotFindNextDate
        }
        let dateComponent = resolveCalendarComponent(for: ruleTimeUnit)
        let dateWithDefaultValues = setDateComponentValuesToDefault(lowerThan: ruleTimeUnit, date: self, atTimeZone: timeZone)

        let unitsToAdd = try resolveUnitsToAdd(ruleTimeUnit: ruleTimeUnit, currentValue: currentValue, nextValue: nextValue)
        return Calendar.current.date(byAdding: dateComponent, value: unitsToAdd, to: dateWithDefaultValues)
    }

    private func setDateComponentValuesToDefault(lowerThan ruleTimeUnit: RecurrenceRuleTimeUnit, date: Date, atTimeZone timeZone: TimeZone? = nil) -> Date {
        var lowerCadenceLevelUnits = [RecurrenceRuleTimeUnit]()
        switch ruleTimeUnit {
        case .second:
            lowerCadenceLevelUnits = []
        case .minute:
            lowerCadenceLevelUnits = [.second]
        case .hour:
            lowerCadenceLevelUnits = [.second, .minute]
        case .dayOfMonth, .dayOfWeek, .weekOfMonth, .weekOfYear:
            lowerCadenceLevelUnits = [.second, .minute, .hour]
        case .month:
            lowerCadenceLevelUnits = [.second, .minute, .hour, .dayOfMonth]
        case .quarter, .year:
            lowerCadenceLevelUnits = [.second, .minute, .hour, .dayOfMonth, .month]
        }

        var newDate = date
        for unit in lowerCadenceLevelUnits {
            do {
                newDate = try setDateComponentValueToDefault(unit, date: newDate, atTimeZone: timeZone)
            } catch {
                // do nothing
            }
        }

        return newDate
    }

    private func setDateComponentValueToDefault(_ ruleTimeUnit: RecurrenceRuleTimeUnit, date: Date, atTimeZone timeZone: TimeZone? = nil) throws -> Date {
        guard let defaultValue = try Calendar.current.lowerBound(for: ruleTimeUnit) else {
            return date
        }
        guard let currentValue = self.dateComponentValue(for: ruleTimeUnit, atTimeZone: timeZone) else {
            throw DateExtensionError.couldNotValidateDateComponentValue
        }

        let dateComponent = resolveCalendarComponent(for: ruleTimeUnit)
        let unitsToSubtract = currentValue - defaultValue

        guard let dateWithDefaultComponentValue = Calendar.current.date(byAdding: dateComponent, value: -unitsToSubtract, to: date) else {
            throw DateExtensionError.couldNotSetDateComponentToDefaultValue
        }
        return dateWithDefaultComponentValue
    }

    private func resolveUnitsToAdd(ruleTimeUnit: RecurrenceRuleTimeUnit, currentValue: Int, nextValue: Int) throws -> Int {
        let isCurrentValueValid = try Calendar.current.validate(ruleTimeUnit: ruleTimeUnit, value: currentValue)
        let isNextValueValid = try Calendar.current.validate(ruleTimeUnit: ruleTimeUnit, value: nextValue)
        if isCurrentValueValid == false || isNextValueValid == false {
            throw DateExtensionError.couldNotValidateDateComponentValue
        }

        var unitsToAdd = nextValue - currentValue
        if unitsToAdd <= 0 {
            if let rangeOfValidBounds = try Calendar.current.rangeOfValidBounds(ruleTimeUnit) {
                unitsToAdd = unitsToAdd + rangeOfValidBounds
            }
        }

        return unitsToAdd
    }
}
