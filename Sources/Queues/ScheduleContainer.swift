import struct Foundation.DateComponents
import struct Foundation.Calendar
import struct Foundation.UUID
import typealias Foundation.TimeInterval

/// An object that can be used to build a scheduled job
public final class ScheduleContainer {
    /// Months of the year
    public enum Month: Int {
        case january = 1
        case february = 2
        case march = 3
        case april = 4
        case may = 5
        case june = 6
        case july = 7
        case august = 8
        case september = 9
        case october = 10
        case november = 11
        case december = 12
    }
    
    /// Describes a day
    public enum Day: ExpressibleByIntegerLiteral {
        case first
        case last
        case exact(Int)
        
        public init(integerLiteral value: Int) {
            self = .exact(value)
        }
    }
    
    /// Describes a day of the week
    public enum Weekday: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }
    
    /// Describes a time of day
    public struct Time: ExpressibleByStringLiteral, CustomStringConvertible {
        var hour: Hour24
        var minute: Minute
        
        /// Returns a `Time` object at midnight (12:00 AM)
        public static var midnight: Time {
            return .init(12, 00, .am)
        }
        
        /// Returns a `Time` object at noon (12:00 PM)
        public static var noon: Time {
            return .init(12, 00, .pm)
        }
        
        /// The readable description of the time
        public var description: String {
            return "\(self.hour):\(self.minute)"
        }
        
        init(_ hour: Hour24, _ minute: Minute) {
            self.hour = hour
            self.minute = minute
        }
        
        init(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod) {
            switch period {
            case .am:
                if hour.number == 12 && minute.number == 0 {
                    self.hour = .init(0)
                } else {
                    self.hour = .init(hour.number)
                }
            case .pm:
                if hour.number == 12 {
                    self.hour = .init(12)
                } else {
                    self.hour = .init(hour.number + 12)
                }
            }
            self.minute = minute
        }
        
        /// Takes a stringLiteral and returns a `TimeObject`. Must be in the format `00:00am/pm`
        public init(stringLiteral value: String) {
            let parts = value.split(separator: ":")
            switch parts.count {
            case 1:
                guard let hour = Int(parts[0]) else {
                    fatalError("Could not convert hour to Int")
                }
                self.init(Hour24(hour), 0)
            case 2:
                guard let hour = Int(parts[0]) else {
                    fatalError("Could not convert hour to Int")
                }
                switch parts[1].count {
                case 2:
                    guard let minute = Int(parts[1]) else {
                        fatalError("Could not convert minute to Int")
                    }
                    self.init(Hour24(hour), Minute(minute))
                case 4:
                    let s = parts[1]
                    guard let minute = Int(s[s.startIndex..<s.index(s.startIndex, offsetBy: 2)]) else {
                        fatalError("Could not convert minute to Int")
                    }
                    let period = String(s[s.index(s.startIndex, offsetBy: 2)..<s.endIndex])
                    self.init(Hour12(hour), Minute(minute), HourPeriod(period))
                default:
                    fatalError("Invalid minute format: \(parts[1]), expected 00am/pm")
                }
            default:
                fatalError("Invalid time format: \(value), expected 00:00am/pm")
            }
        }
    }
    
    /// Represents an hour numeral that must be in 12 hour format
    public struct Hour12: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int
        
        /// The readable description of the hour
        public var description: String {
            return self.number.description
        }
        
        init(_ number: Int) {
            precondition(number > 0, "12-hour clock cannot preceed 1")
            precondition(number <= 12, "12-hour clock cannot exceed 12")
            self.number = number
        }
        
        /// Takes an integerLiteral and creates a `Hour12`. Must be `> 0 && <= 12`
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }
    
    /// Represents an hour numeral that must be in 24 hour format
    public struct Hour24: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int
        
        /// The readable description of the hour, zero padding included
        public var description: String {
            switch self.number {
            case 0..<10:
                return "0" + self.number.description
            default:
                return self.number.description
            }
        }
        
        init(_ number: Int) {
            precondition(number >= 0, "24-hour clock cannot preceed 0")
            precondition(number < 24, "24-hour clock cannot exceed 24")
            self.number = number
        }
        
        /// Takes an integerLiteral and creates a `Hour24`. Must be `>= 0 && < 24`
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }
    
    /// A period of hours - either `am` or `pm`
    public enum HourPeriod: ExpressibleByStringLiteral, CustomStringConvertible {
        case am
        case pm
        
        /// The readable string
        public var description: String {
            switch self {
            case .am:
                return "am"
            case .pm:
                return "pm"
            }
        }
        
        init(_ string: String) {
            switch string.lowercased() {
            case "am":
                self = .am
            case "pm":
                self = .pm
            default:
                fatalError("Unknown hour period: \(string), must be am or pm")
            }
        }
        
        /// Takes a stringLiteral and creates a `HourPeriod.` Must be `am` or `pm`
        public init(stringLiteral value: String) {
            self.init(value)
        }
    }
    
    /// Describes a minute numeral
    public struct Minute: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int
        
        /// The readable minute, zero padded.
        public var description: String {
            switch self.number {
            case 0..<10:
                return "0" + self.number.description
            default:
                return self.number.description
            }
        }
        
        init(_ number: Int) {
            assert(number >= 0, "Minute cannot preceed 0")
            assert(number < 60, "Minute cannot exceed 60")
            self.number = number
        }
        
        /// Takes an integerLiteral and creates a `Minute`. Must be `>= 0 && < 60`
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }
    
    /// Describes a second numeral
    public struct Second: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int
        
        /// The readable second, zero padded.
        public var description: String {
            switch self.number {
            case 0..<10:
                return "0" + self.number.description
            default:
                return self.number.description
            }
        }
        
        init(_ number: Int) {
            assert(number >= 0, "Second cannot preceed 0")
            assert(number < 60, "Second cannot exceed 60")
            self.number = number
        }
        
        /// Takes an integerLiteral and creates a `Second`. Must be `>= 0 && < 60`
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }
    
    public let job: ScheduledJob
    public var builders: [Builder] = []
    
    public init(job: ScheduledJob) {
        self.job = job
    }
    
    // MARK: Helpers
    
    /// Schedules a job at the specified dates
    public func at(_ dates: Date...) -> Void {
        Builder(container: self).at(dates)
    }
    
    /// Schedules a job at the specified dates
    public func at(_ dates: [Date]) -> Void {
        Builder(container: self).at(dates)
    }
    
    /// Creates a yearly scheduled job for further building
    public func yearly() -> Builder.Yearly {
        return Builder.Yearly(builder: Builder(container: self))
    }
    
    /// Creates a monthly scheduled job for further building
    public func monthly() -> Builder.Monthly {
        return Builder.Monthly(builder: Builder(container: self))
    }
    
    /// Creates a weekly scheduled job for further building
    public func weekly() -> Builder.Weekly {
        return Builder.Weekly(builder: Builder(container: self))
    }
    
    /// Creates a daily scheduled job for further building
    public func daily() -> Builder.Daily {
        return Builder.Daily(builder: Builder(container: self))
    }
    
    /// Creates a hourly scheduled job for further building
    public func hourly() -> Builder.Hourly {
        return Builder.Hourly(builder: Builder(container: self))
    }
    
    /// Creates a minutely scheduled job for further building
    public func minutely() -> Builder.Minutely {
        return Builder.Minutely(builder: Builder(container: self))
    }
    
    /// Runs a job every second
    public func everySecond() {
        Builder(container: self).everySecond()
    }
    
    /// Runs a job every `amount` in the `interval`
    ///
    /// `underestimatedCount` Explanation:
    /// underestimatedCount is only useful in some cases when
    /// interval.nanoseconds % amount.nanoseconds is non-zero.
    /// It will decide whether the function should use the most possible
    /// number of jobs possible using the provided `amount` and `interval`
    /// or it should use the lower count of jobs.
    ///
    /// By example, imagine `amount` is equal to _5 hours_ and `interval` is
    /// equal to _22 hours_.
    ///
    /// when `underestimatedCount` is `true`, the number of jobs created
    /// will be 22 / 5 = 4, which will be done on hours 0, 5, 10 and 15.
    /// In this case, it __will not__ schedule a job for the hour _20_ because
    /// the period between the hour _20_ and the next hour _0_ is only 3 hours
    /// and preceeds the value of `amount` which is _5_ hours.
    /// But, when `underestimatedCount` is set to `false`, the function
    /// __will__ include the hour _20_ although the interval between
    /// the hour _20_ and the next _0_ hour is only _3_ and preceeds
    /// the `amount` _5_.
    ///
    /// - Parameter amount: A `TimeAmount` after which the job will be repeated.
    /// - Parameter interval: A `TimeAmount` period in which the job will be repeated.
    /// - Parameter underestimatedCount: Decides whether the function should underestimate
    /// count of the created jobs or overestimate.
    public func every(
        _ amount: TimeAmount,
        in interval: TimeAmount,
        initialDelay: TimeAmount = .seconds(1),
        underestimatedCount: Bool = true
    ) {
        Builder(container: self).every(
            amount,
            in: interval,
            initialDelay: initialDelay,
            underestimatedCount: underestimatedCount
        )
    }

    /// Schedules a task to be done again right-away, every time it is finished.
    /// - Parameter initialDelay: A `TimeAmount` as the initial delay.
    public func continuously(initialDelay: TimeAmount = .seconds(1)) {
        Builder(container: self).continuously(initialDelay: initialDelay)
    }
    
}

//MARK: - Builder

extension ScheduleContainer {
    public final class Builder {
        
        /// An object to build a `Yearly` scheduled job
        public struct Yearly {
            let builder: Builder
            
            /// The month to run the job in
            /// - Parameter month: A `Month` to run the job in
            public func `in`(_ month: Month) -> Monthly {
                self.builder.timeValue = .componentBased(month: month)
                return self.builder.monthly()
            }
        }
        
        /// An object to build a `Monthly` scheduled job
        public struct Monthly {
            let builder: Builder
            
            /// The day to run the job on
            /// - Parameter day: A `Day` to run the job on
            public func on(_ day: Day) -> Daily {
                self.builder.timeValue = .componentBased(day: day)
                return self.builder.daily()
            }
        }
        
        /// An object to build a `Weekly` scheduled job
        public struct Weekly {
            let builder: Builder
            
            /// The day of week to run the job on
            /// - Parameter dayOfWeek: A `DayOfWeek` to run the job on
            public func on(_ weekday: Weekday) -> Daily {
                self.builder.timeValue = .componentBased(weekday: weekday)
                return self.builder.daily()
            }
        }
        
        /// An object to build a `Daily` scheduled job
        public struct Daily {
            let builder: Builder
            
            /// The time to run the job at
            /// - Parameter time: A `Time` object to run the job on
            public func at(_ time: Time) {
                self.builder.timeValue = .componentBased(time: time)
            }
            
            /// The 24 hour time to run the job at
            /// - Parameter hour: A `Hour24` to run the job at
            /// - Parameter minute: A `Minute` to run the job at
            public func at(_ hour: Hour24, _ minute: Minute) {
                self.at(.init(hour, minute))
            }
            
            /// The 12 hour time to run the job at
            /// - Parameter hour: A `Hour12` to run the job at
            /// - Parameter minute: A `Minute` to run the job at
            /// - Parameter period: A `HourPeriod` to run the job at (`am` or `pm`)
            public func at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod) {
                self.at(.init(hour, minute, period))
            }
        }
        
        /// An object to build a `Hourly` scheduled job
        public struct Hourly {
            let builder: Builder
            
            /// Runs the job multiple times
            /// - Parameter amount: A period after which the job will be repeated as
            /// many times as an hour allows.
            public func every(_ amount: TimeAmount) {
                self.builder.every(amount, in: .hours(1))
            }
            
            /// The minute to run the job at
            /// - Parameter minute: A `Minute` to run the job at
            public func at(_ minute: Minute) {
                self.builder.timeValue = .componentBased(minute: minute)
            }
        }
        
        /// An object to build a `EveryMinute` scheduled job
        public struct Minutely {
            let builder: Builder
            
            /// Runs the job multiple times
            /// - Parameter amount: A period after which the job will be repeated as
            /// many times as a minute allows.
            public func every(_ amount: TimeAmount) {
                self.builder.every(amount, in: .minutes(1))
            }
            
            /// The second to run the job at
            /// - Parameter second: A `Second` to run the job at
            public func at(_ second: Second) {
                self.builder.timeValue = .componentBased(second: second)
            }
        }
        
        /// Describes the date at which the container's job is meant to be executed
        public enum TimeValue {
            case exact(date: Date)
            /// isFirstLifecycle explanation:
            /// This __must__ only be set to `false` by the app or the `_nextDate(current:)`
            /// function output can turn wrong. `_nextDate(current:)` will
            /// set this to `false` after the first time.
            case intervalBased(offset: TimeInterval,
                               interval: TimeInterval,
                               isFirstLifecycle: Bool = true)
            case componentBased(month: Month? = nil,
                                day: Day? = nil,
                                weekday: Weekday? = nil,
                                time: Time? = nil,
                                minute: Minute? = nil,
                                second: Second? = nil,
                                nanosecond: Int? = nil)
        }
        
        public let id = UUID()
        public var container: ScheduleContainer
        private var _timeValue: TimeValue? = nil
        public var timeValue: TimeValue? {
            get { _timeValue }
            set {
                /// Adds newValue to _timeValue if both are `.componentBased`,
                /// sets _timeValue to newValue otherwise
                switch newValue {
                case let .componentBased(month, day, weekday, time,
                                         minute, second, nanosecond):
                    switch _timeValue {
                    case let .componentBased(monthP, dayP, weekdayP,
                                             timeP, minuteP, secondP, nanosecondP):
                        _timeValue = TimeValue.componentBased(
                            month: month ?? monthP, day: day ?? dayP,
                            weekday: weekday ?? weekdayP, time: time ?? timeP,
                            minute: minute ?? minuteP, second: second ?? secondP,
                            nanosecond: nanosecond ?? nanosecondP)
                    default: _timeValue = newValue
                    }
                default: _timeValue = newValue
                }
            }
        }
        
        /// Creates a new builder and adds it to the container if it isn't there
        public init(container: ScheduleContainer) {
            self.container = container
            let isBuilderInContainer = container.builders.contains(where: { $0.id == self.id })
            if !isBuilderInContainer {
                container.builders.append(self)
            }
        }
        
        // MARK: Helpers

        /// Schedules a job at the specified dates
        public func at(_ dates: Date...) -> Void {
            self.at(dates)
        }
        
        /// Schedules a job at the specified dates
        public func at(_ dates: [Date]) -> Void {
            dates.enumerated().forEach { index, date in
                if index == 0 {
                    self.timeValue = .exact(date: date)
                } else {
                    let builder = Builder(container: self.container)
                    builder.timeValue = .exact(date: date)
                }
            }
        }
        
        /// Creates a yearly scheduled job for further building
        public func yearly() -> Yearly {
            return Yearly(builder: self)
        }
        
        /// Creates a monthly scheduled job for further building
        public func monthly() -> Monthly {
            return Monthly(builder: self)
        }
        
        /// Creates a weekly scheduled job for further building
        public func weekly() -> Weekly {
            return Weekly(builder: self)
        }
        
        /// Creates a daily scheduled job for further building
        public func daily() -> Daily {
            return Daily(builder: self)
        }
        
        /// Creates a hourly scheduled job for further building
        public func hourly() -> Hourly {
            return Hourly(builder: self)
        }
        
        /// Creates a minutely scheduled job for further building
        public func minutely() -> Minutely {
            return Minutely(builder: self)
        }
        
        /// Runs a job every second
        public func everySecond() {
            self.every(.seconds(1), in: .seconds(1))
        }

        /// Runs a job every `amount` in the `interval`
        ///
        /// `underestimatedCount` Explanation:
        /// underestimatedCount is only useful in some cases when
        /// interval.nanoseconds % amount.nanoseconds is non-zero.
        /// It will decide whether the function should use the most possible
        /// number of jobs possible using the provided `amount` and `interval`
        /// or it should use the lower count of jobs.
        ///
        /// By example, imagine `amount` is equal to _5 hours_ and `interval` is
        /// equal to _22 hours_.
        ///
        /// when `underestimatedCount` is `true`, the number of jobs created
        /// will be 22 / 5 = 4, which will be done on hours 0, 5, 10 and 15.
        /// In this case, it __will not__ schedule a job for the hour _20_ because
        /// the period between the hour _20_ and the next hour _0_ is only 3 hours
        /// and preceeds the value of `amount` which is _5_ hours.
        /// But, when `underestimatedCount` is set to `false`, the function
        /// __will__ include the hour _20_ although the interval between
        /// the hour _20_ and the next _0_ hour is only _3_ and preceeds
        /// the `amount` _5_.
        ///
        /// - Parameter amount: A `TimeAmount` after which the job will be repeated.
        /// - Parameter interval: A `TimeAmount` period in which the job will be repeated.
        /// - Parameter initialDelay: A `TimeAmount` as the initial delay.
        /// - Parameter underestimatedCount: Decides whether the function should underestimate
        /// count of the created jobs or overestimate.
        public func every(
            _ amount: TimeAmount,
            in interval: TimeAmount,
            initialDelay: TimeAmount = .seconds(1),
            underestimatedCount: Bool = true
        ) {
            let nanoInterval = interval.nanoseconds
            let nanoAmount = amount.nanoseconds
            let nanoDelay = initialDelay.nanoseconds
            precondition(nanoAmount > 0, "Amount \(amount.nanoseconds) is not positive.")
            precondition(nanoAmount <= nanoInterval, "Amount \(amount.nanoseconds) is greater than interval \(interval.nanoseconds).")
            let runCount: Int64
            if underestimatedCount {
                runCount = nanoInterval / nanoAmount
            } else {
                runCount = Int64((Double(nanoInterval) / Double(nanoAmount)).rounded(.up))
            }
            let timeAmounts = (0..<runCount).map { index in
                index * nanoAmount + nanoDelay
            }
            /// After using `.every` on top a `Builder`, the current builder
            /// is populated with the first schedule time, and the next schedule times
            /// will have a new builder created for them and added to the container.
            timeAmounts.enumerated().forEach { index, timeAmount in
                let builder: Builder
                switch index {
                case 0: builder = self
                default: builder = Builder(container: self.container)
                }
                let timeAmountSeconds = TimeInterval(timeAmount) / 1000 / 1000 / 1000
                let intervalSeconds = TimeInterval(nanoInterval) / 1000 / 1000 / 1000
                builder.timeValue = .intervalBased(
                    offset: timeAmountSeconds,
                    interval: intervalSeconds)
            }
        }

        /// Schedules a task to be done again right-away, every time it is finished.
        /// - Parameter initialDelay: A `TimeAmount` as the initial delay.
        public func continuously(initialDelay: TimeAmount = .seconds(1)) {
            let delaySeconds = TimeInterval(initialDelay.nanoseconds) / 1000 / 1000 / 1000
            self.timeValue = .intervalBased(offset: delaySeconds, interval: 0)
        }
        
        /// Retrieves the next date
        ///
        /// Caution:
        /// If the current builder is built using `.every` functions, using
        /// `_nextDate()` will start its lifecycle. Use the public
        /// `nextDate()` function to not start the lifecycle.
        /// Read `TimeValue.intervalBased.isFirstLifecycle` comments for more.
        ///
        /// - Parameter current: The current date
        /// - Parameter startLifecycle: Whether or not calling this function should
        /// start the builder's lifecycle. Internality of this function
        /// is to prevent users from setting `TimeValue.intervalBased.isFirstLifecycle`
        /// to `false` and start the lifecycle by accident
        /// - Returns: The next date
        internal func _nextDate(current: Date = .init(), startLifecycle: Bool = true) -> Date? {
            guard let value = timeValue else { return nil }
            switch value {
            case .exact(let date):
                switch date > current {
                case true: return date
                case false: return nil
                }
            case let .intervalBased(offset, interval, isFirstLifecycle):
                switch isFirstLifecycle {
                case false:
                    return current.addingTimeInterval(interval)
                case true:
                    if startLifecycle {
                        self.timeValue = .intervalBased(
                            offset: offset,
                            interval: interval,
                            isFirstLifecycle: false)
                    }
                    return current.addingTimeInterval(offset)
                }
            case let .componentBased(month, day, weekday, time, minute, second, nanosecond):
                var components = DateComponents()
                if let nanosecond = nanosecond {
                    components.nanosecond = nanosecond
                }
                if let second = second {
                    components.second = second.number
                }
                if let minute = minute {
                    components.minute = minute.number
                }
                if let time = time {
                    components.minute = time.minute.number
                    components.hour = time.hour.number
                }
                if let weekday = weekday {
                    components.weekday = weekday.rawValue
                }
                if let day = day {
                    switch day {
                    case .first:
                        components.day = 1
                    case .last:
                        fatalError("Last day of the month is not yet supported.")
                    case .exact(let exact):
                        components.day = exact
                    }
                }
                if let month = month {
                    components.month = month.rawValue
                }
                return Calendar.current.nextDate(
                    after: current,
                    matching: components,
                    matchingPolicy: .strict
                )
            }
        }
        
        /// Retrieves the next date
        /// - Parameter current: The current date
        /// - Returns: The next date
        public func nextDate(current: Date = Date()) -> Date? {
            self._nextDate(current: current, startLifecycle: false)
        }
        
    }
}
