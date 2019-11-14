import Foundation

internal extension Calendar {
    enum CalendarExtensionError: Error {
        case counldNotFindLowerBoundForRecurrenceRuleTimeUnit
        case counldNotFindUpperBoundForRecurrenceRuleTimeUnit
    }

    /// validates a value is within the bounds
    ///
    /// - Parameters:
    ///   - ruleTimeUnit: The TimeUnit to check value against
    ///   - value: the value to check
    /// - Returns:  true if value is valid, false if value is invalid
    func validate(ruleTimeUnit: RecurrenceRule.TimeUnit, value: Int) throws -> Bool {
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

    /// Finds the range amount (validUpperBound - validLowerBound) given a RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The RecurrenceRule.TimeUnit to reference
    /// - Returns: The range (validUpperBound - validLowerBound)
    /// - Throws: will throw if no lowerBound or upperBound is available for a given RecurrenceRule.TimeUnit
    func rangeOfValidBounds(_ ruleTimeUnit: RecurrenceRule.TimeUnit) throws -> Int? {
        guard let validLowerBound = try lowerBound(for: ruleTimeUnit) else {
            return nil
        }

        guard let validUpperBound = try upperBound(for: ruleTimeUnit) else {
            return nil
        }

        return validUpperBound - validLowerBound
    }

    ///  Resolves The lower bound (inclusive) of a given RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRule.TimeUnit
    /// - Returns: The lower bound(inclusive)
    func lowerBound(for ruleTimeUnit: RecurrenceRule.TimeUnit) throws -> Int? {
        switch self.identifier {
            case .gregorian, .iso8601:
                return Calendar.gregorianLowerBound(for: ruleTimeUnit)
            default:
                throw CalendarExtensionError.counldNotFindLowerBoundForRecurrenceRuleTimeUnit
        }
    }

    ///  Resolves The upper bound (inclusive) of a given RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRule.TimeUnit
    /// - Returns: The upper bound(inclusive)
    func upperBound(for ruleTimeUnit: RecurrenceRule.TimeUnit) throws -> Int? {
        switch self.identifier {
            case .gregorian, .iso8601:
                return Calendar.gregorianUpperBound(for: ruleTimeUnit)
            default:
                throw CalendarExtensionError.counldNotFindUpperBoundForRecurrenceRuleTimeUnit
        }
    }

    static func gregorianLowerBound(for ruleTimeUnit: RecurrenceRule.TimeUnit) -> Int? {
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
            case .month:
                return 1
            case .quarter:
                return 1
            case .year:
                return 1970
        }
    }

    static func gregorianUpperBound(for ruleTimeUnit: RecurrenceRule.TimeUnit) -> Int? {
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
            case .month:
                return 12
            case .quarter:
                return 4
            case .year:
                return nil
        }
    }
}

// Date extensions that assist with evaluating recurrence rules
extension Date {
    enum DateExtensionError: Error {
        case couldNotFindNextDate
        case couldNotIncrementDateByTimeUnit
        case couldNotValidateDateComponentValue
        case couldNotSetDateComponentToDefaultValue
    }

    /// returns the second component (Calendar.Component.second) of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The second component of the date (0-59)
    internal func second(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.second, from: self)
    }

    /// returns the minute component (Calendar.Component.minute) of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The minute component of the date (0-59)
    internal func minute(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.minute, from: self)
    }

    /// returns the hour component (Calendar.Component.hour) of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The hour component of the date (0-23)
    internal func hour(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.hour, from: self)
    }

    /// returns the dayOfWeek (Calendar.Component.weekday) component of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The dayOfWeek of the date (1 Sunday, 7 Saturday)
    internal func dayOfWeek(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.weekday, from: self)
    }

    /// returns the dayOfMonth (Calendar.Component.day) component of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The dayOfMonth of the date (1-31)
    internal func dayOfMonth(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.day, from: self)
    }

    /// returns the weekOfMonth (Calendar.Component.weekOfMonth) component of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The weekOfMonth of the date (1-31)
    internal func weekOfMonth(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.weekOfMonth, from: self)
    }

    /// returns the weekOfYear (Calendar.Component.weekOfYear) component of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The weekOfYear of the date (1-52)
    internal func weekOfYear(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.weekOfYear, from: self)
    }

    /// returns the month (Calendar.Component.month) component of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The month of the date (1 (january) - 12 (December))
    internal func month(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.month, from: self)
    }

    /// returns the quarter (Calendar.Component.quarter) component of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The quarter of the date (1-4)
    internal func quarter(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        // Bug: doesn't work in ios 12 and macOS Mojave 10.14
        // return Calendar.current.component(.quarter.component(.month, from: self), from: self)
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

    /// returns the year (Calendar.Component.year) component of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The year of the date
    internal func year(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.year, from: self)
    }

    /// returns the yearForWeekOfYear (Calendar.Component.yearForWeekOfYear) component of the date
    ///
    /// - Parameter timeZone: The TimeZone to base the date off of (defaults to current timeZone)
    /// - Returns: The yearForWeekOfYear of the datesss
    internal func yearForWeekOfYear(atTimeZone timeZone: TimeZone? = nil) -> Int? {
        return calendar(atTimeZone: timeZone).component(.yearForWeekOfYear, from: self)
    }

    /// finds the number of weeks the year (52 or 53)
    internal func weeksInYear() -> Int? {
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

    /// Resolves the Calendar Component for a given RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRule.TimeUnit
    /// - Returns: The associated Calendar.Component
    private func resolveCalendarComponent(for ruleTimeUnit: RecurrenceRule.TimeUnit) -> Calendar.Component {
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
            case .month:
                return .month
            case .quarter:
                return .quarter
            case .year:
                return .year
        }
    }

    /// resolve the Calendar Component for a given RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRule.TimeUnits
    /// - Returns: The associated Calendar Component
    internal func dateComponentValue(for ruleTimeUnit: RecurrenceRule.TimeUnit, atTimeZone timeZone: TimeZone? = nil) -> Int? {
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
            case .month:
                return self.month(atTimeZone: timeZone)
            case .quarter:
                return self.quarter(atTimeZone: timeZone)
            case .year:
                return self.year(atTimeZone: timeZone)
        }
    }

    /// Returns the amount of years from another date
    internal func years(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.year], from: date, to: self).year
    }

    /// Returns the amount of quarters from another date
    internal func quarters(from date: Date) -> Int? {
        // bug in quarter on ios12 and macOS 10.14 mojave
        //return Calendar.current.dateComponents([.quarter], from: date, to: self).quarter
        let formatter = DateFormatter()
        formatter.dateFormat = "Q"
        return Int(formatter.string(from: date))
    }

    /// Returns the amount of months from another date
    internal func months(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.month], from: date, to: self).month
    }

    /// Returns the amount of weeks from another date
    internal func weeks(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth
    }

    /// Returns the amount of days from another date
    internal func days(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.day], from: date, to: self).day
    }

    /// Returns the amount of hours from another date
    internal func hours(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour
    }

    /// Returns the amount of minutes from another date
    internal func minutes(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute
    }

    /// Returns the amount of seconds from another date
    internal func seconds(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.second], from: date, to: self).second
    }

    /// Produces a date by advancing a date component by a given value
    ///
    /// - Parameter calendarComponent: The compoent of the date to increment
    /// - Returns: a date with the specified component incremented
    internal func dateByIncrementing(calendarComponent: Calendar.Component) -> Date? {
        return Calendar.current.date(byAdding: calendarComponent, value: 1, to: self)
    }

    /// Produces a date by incrementing the date component associated with the RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The time unit to increment
    /// - Returns: a date the referenced component incrementeds
    internal func dateByIncrementing(_ ruleTimeUnit: RecurrenceRule.TimeUnit, atTimeZone timeZone: TimeZone? = nil) throws -> Date {
        let calendarComponent = resolveCalendarComponent(for: ruleTimeUnit)

        /// sets the date component values lower than ruleTimeUnit to 0
        let dateWithDefaultValues = try setDateComponentValuesToDefault(lowerThan: ruleTimeUnit, date: self, atTimeZone: timeZone)

        guard let incrementedDate = dateWithDefaultValues.dateByIncrementing(calendarComponent: calendarComponent) else {
            throw DateExtensionError.couldNotIncrementDateByTimeUnit
        }

        return incrementedDate
    }

    /// Finds the next possible date where the date component value associated with the `RecurrenceRule.TimeUnit` is
    /// equal to given value
    ///
    /// For example:  If ruleTimeUnit is .hour, nextValue is 4, and the self is `2019-02-16T14:42:20` then
    /// the date returned will be `2019-02-17T04:00:00`
    internal func nextDate(where ruleTimeUnit: RecurrenceRule.TimeUnit, is nextValue: Int, atTimeZone timeZone: TimeZone? = nil) throws -> Date {
        guard let currentValue = self.dateComponentValue(for: ruleTimeUnit) else {
            throw DateExtensionError.couldNotFindNextDate
        }
        let dateComponent = resolveCalendarComponent(for: ruleTimeUnit)

        /// sets the date component values lower than ruleTimeUnit to 0
        let dateWithDefaultValues = try setDateComponentValuesToDefault(lowerThan: ruleTimeUnit, date: self, atTimeZone: timeZone)

        /// Finds how many units to add to the date component to get to the next value
        let unitsToAdd = try resolveUnitsToAdd(ruleTimeUnit: ruleTimeUnit, currentValue: currentValue, nextValue: nextValue)

        /// Advances the date component by the given units
        guard let nextDate = Calendar.current.date(byAdding: dateComponent, value: unitsToAdd, to: dateWithDefaultValues) else {
            throw DateExtensionError.couldNotFindNextDate
        }
        return nextDate
    }

    /// Sets lower date components to their default values
    ///
    /// For Example: If ruleTimeUnit is .month then the date component value associated with .dayOfMonth will be is set to 1 and
    /// the date components associated with .hour,  .minute, and .second value will be set to 0
    private func setDateComponentValuesToDefault(lowerThan ruleTimeUnit: RecurrenceRule.TimeUnit, date: Date, atTimeZone timeZone: TimeZone? = nil) throws -> Date {
        var lowerCadenceLevelUnits = [RecurrenceRule.TimeUnit]()

        switch ruleTimeUnit {
            case .second:
                lowerCadenceLevelUnits = []
            case .minute:
                lowerCadenceLevelUnits = [.second]
            case .hour:
                lowerCadenceLevelUnits = [.second, .minute]
            case .dayOfMonth, .dayOfWeek:
                lowerCadenceLevelUnits = [.second, .minute, .hour]
            case .month:
                lowerCadenceLevelUnits = [.second, .minute, .hour, .dayOfMonth]
            case .quarter, .year:
                lowerCadenceLevelUnits = [.second, .minute, .hour, .dayOfMonth, .month]
        }

        var newDate = date
        for unit in lowerCadenceLevelUnits {
            newDate = try setDateComponentValueToDefault(unit, date: newDate, atTimeZone: timeZone)
        }

        return newDate
    }

    /// Sets the a date component to its default value (i.e second to 0,  hour to  0, dayOfMonth to 1, month to 1)
    private func setDateComponentValueToDefault(_ ruleTimeUnit: RecurrenceRule.TimeUnit, date: Date, atTimeZone timeZone: TimeZone? = nil) throws -> Date {
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

    /// Finds how many units to advance the value of the date component by to to get to the next value
    ///
    /// For Example: If ruleTimeUnit is .seconds, currentValue is 55, and nextValue is 5 then 9 would be returned
    private func resolveUnitsToAdd(ruleTimeUnit: RecurrenceRule.TimeUnit, currentValue: Int, nextValue: Int) throws -> Int {
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

        if unitsToAdd == 0 {
            unitsToAdd = 1
        }

        return unitsToAdd
    }

    /// Checks if the date lies on the last day of the month
    internal func isLastDayOfMonth() throws -> Bool {
        let tomorrow = try self.dateByIncrementing(.dayOfMonth)
        if tomorrow.dayOfMonth() == 1 {
            return true
        }

        return false
    }

    internal func numberOfDaysInMonth() -> Int? {
        guard let range = Calendar.current.range(of: .day, in: .month, for: self) else {
            return nil
        }
        return range.count
    }

    private func calendar(atTimeZone timeZone: TimeZone? = nil) -> Calendar {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        return calendar
    }

}
