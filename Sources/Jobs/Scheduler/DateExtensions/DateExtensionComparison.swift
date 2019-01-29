import Foundation

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? nil
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? nil
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? nil
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? nil
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? nil
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? nil
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? nil
    }
}
