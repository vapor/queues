import Foundation

protocol QuarterBuilder {
    func atQuarter(_ quarter: Int) -> Scheduler.ScheduledQuarter
    func atQuarters(_ quarters: Set<Int>) -> Scheduler.ScheduledQuarter
    func atQuartersInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledQuarter
}

protocol MonthBuilder {
    func atMonth(_ month: Int) -> Scheduler.ScheduledMonth
    func atMonths(_ months: Set<Int>) -> Scheduler.ScheduledMonth
    func atMonthsInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledMonth
}

protocol DayOfMonthAndWeekBuilder {
    func at(DayOfWeek: Int, AndDayOfMonth: Int) -> Scheduler.ScheduledDayOfMonth
    func atDaysOfMonth(_ daysOfMonth: Set<Int>) -> Scheduler.ScheduledDayOfMonth
    func atDaysOfMonthInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledDayOfMonth
}

protocol DayOfMonthBuilder {
    func atDayOfMonth(_ dayOfMonth: Int) -> Scheduler.ScheduledDayOfMonth
    func atDaysOfMonth(_ daysOfMonth: Set<Int>) -> Scheduler.ScheduledDayOfMonth
    func atDaysOfMonthInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledDayOfMonth
}

protocol DayOfWeekBuilder {
    func atDayOfWeek(_ dayOfWeek: Int) -> Scheduler.ScheduledDayOfWeek
    func atDaysOfWeek(_ daysOfWeek: Set<Int>) -> Scheduler.ScheduledDayOfWeek
    func atDaysOfWeekInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledDayOfWeek

    func weekdays() -> Scheduler.ScheduledDayOfWeek
    func weekends() -> Scheduler.ScheduledDayOfWeek
}

protocol HourBuilder {
    func atHour(_ hour: Int) -> Scheduler.ScheduledHour
    func atHours(_ hours: Set<Int>) -> Scheduler.ScheduledHour
    func atHoursInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledHour
}

protocol MinuteBuilder {
    func atMinute(_ minute: Int) -> Scheduler.ScheduledMinute
    func atMinutes(_ minutes: Set<Int>) -> Scheduler.ScheduledMinute
    func atMinutesInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledMinute
}

protocol SecondBuilder {
    func atSecond(_ second: Int) -> Scheduler.ScheduledSecond
    func atSeconds(_ seconds: Set<Int>) -> Scheduler.ScheduledSecond
    func atSecondsInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledSecond
}

protocol SingularBuilder {
    var scheduler: Scheduler {get}
}

protocol MonthBuilderSingular: SingularBuilder {
    /// Specifies the month of the year to run the job
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    func atMonth(_ month: Int) throws -> Scheduler.ScheduledMonth.Singular

    /// Specifies the month of the year to run the job
    ///
    /// - Parameter month: Month of the year to run the job
    /// - Parameter day: Day of the month to run the job on. Lower bound: 1, Upper bound: 31
    func on(_ month: Scheduler.MonthOfYear, _ day: Int) throws -> Scheduler.ScheduledDayOfMonth.Singular
}

protocol DayOfMonthBuilderSingular: SingularBuilder {
    /// Specifies the day of the month to run the job
    ///
    /// - Parameter dayOfMonth: Day of the month to run the job on. Lower bound: 1, Upper bound: 31
    func atDayOfMonth(_ dayOfMonth: Int) throws -> Scheduler.ScheduledDayOfMonth.Singular
}

protocol DayOfWeekBuilderSingular: SingularBuilder {
    /// Specifies the day of the week to run the job
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    func atDayOfWeek(_ dayOfWeek: Int) throws -> Scheduler.ScheduledDayOfWeek.Singular
}

protocol HourBuilderSingular: SingularBuilder {
    /// Specifies the hour to run the job
    ///
    /// - Note: Uses the 24 hour clock
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    func atHour(_ hour: Int) throws -> Scheduler.ScheduledHour.Singular

    /// Specifies the hour to run the job
    ///
    /// - Note: Uses the 24 hour clock
    /// - Parameter hhmm: hour and minute string. e.x: 0:14, 8:54, 15:02
    func at(_ hhmm: String) throws -> Scheduler.ScheduledMinute.Singular

    /// Specifies the time of day to run the job
    ///
    /// - Note: Midnight will run the job at 23:59:59
    /// - Parameter timeOfDay: Time of day to run the job
    func at(_ timeOfDay: Scheduler.TimeOfDay) throws -> Scheduler.ScheduledSecond.Singular
}

protocol MinuteBuilderSingular: SingularBuilder {
    /// Specifies the minute to run the job
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    func atMinute(_ minute: Int) throws -> Scheduler.ScheduledMinute.Singular
}

protocol SecondBuilderSingular: SingularBuilder {
    /// Specifies the second to run the job
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    func atSecond(_ second: Int) throws -> Scheduler.ScheduledSecond.Singular
}

func schedule(_ job: Job) -> Scheduler {
    return Scheduler()
}

final class Scheduler {
    private(set) var recurrenceRule = RecurrenceRule()

    enum MonthOfYear: Int {
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

    enum DayOfWeek: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }

    enum TimeOfDay {
        case midnight
        case noon
    }

    struct Yearly: MonthBuilderSingular {
        let scheduler: Scheduler
        init() throws {
            scheduler = Scheduler.init()
            scheduler.recurrenceRule.setYearConstraint(try YearRecurrenceRuleConstraint.yearStep(1))
        }

        func atMonth(_ month: Int) throws -> Scheduler.ScheduledMonth.Singular {
            return try .init(scheduler: self.scheduler, month: month)
        }
        func on(_ month: Scheduler.MonthOfYear, _ dayOfMonth: Int) throws -> Scheduler.ScheduledDayOfMonth.Singular {
            return try .init(scheduler: self.scheduler, month: month, dayOfMonth: dayOfMonth)
        }

    }

    struct Monthly: DayOfMonthBuilderSingular {
        let scheduler: Scheduler

        init() throws {
            self.scheduler = Scheduler()
            scheduler.recurrenceRule.setMonthConstraint(try MonthRecurrenceRuleConstraint.monthStep(1))
        }

        func atDayOfMonth(_ dayOfMonth: Int) throws -> Scheduler.ScheduledDayOfMonth.Singular {
            return try .init(scheduler: self.scheduler, dayOfMonth: dayOfMonth)
        }
    }

    struct Weekly: HourBuilderSingular {
        let scheduler: Scheduler

        init(onDayOfWeek dayOfWeek: Int) throws {
            self.scheduler = Scheduler()
            scheduler.recurrenceRule.setDayOfWeekConstraint(try .atDayOfWeek(dayOfWeek))
        }

        init(on dayOfWeek: Scheduler.DayOfWeek) throws {
            self.scheduler = Scheduler()
            scheduler.recurrenceRule.setDayOfWeekConstraint(try .atDayOfWeek(dayOfWeek.rawValue))
        }

        func atHour(_ hour: Int) throws -> Scheduler.ScheduledHour.Singular {
            return try .init(scheduler: self.scheduler, hour: hour)
        }

        func at(_ hhmm: String) throws -> Scheduler.ScheduledMinute.Singular {
            return try .init(scheduler: self.scheduler, hhmm: hhmm)
        }

        @discardableResult func at(_ timeOfDay: Scheduler.TimeOfDay) throws -> Scheduler.ScheduledSecond.Singular {
            return try .init(scheduler: self.scheduler, timeOfDay: timeOfDay)
        }
    }

    struct Daily: HourBuilderSingular {
        let scheduler: Scheduler

        init() throws {
            self.scheduler = Scheduler()
            scheduler.recurrenceRule.setDayOfWeekConstraint(try .dayOfWeekStep(1))
        }

        init(onDaysOfWeek daysOfWeek: Set<Int>) throws {
            self.scheduler = Scheduler()
            scheduler.recurrenceRule.setDayOfWeekConstraint(try .atDaysOfWeek(daysOfWeek))
        }

        init(onDayOfWeek dayOfWeek: Int) throws {
            self.scheduler = Scheduler()
            scheduler.recurrenceRule.setDayOfWeekConstraint(try .atDayOfWeek(dayOfWeek))
        }

        func atHour(_ hour: Int) throws -> Scheduler.ScheduledHour.Singular {
            return try .init(scheduler: self.scheduler, hour: hour)
        }

        func at(_ hhmm: String) throws -> Scheduler.ScheduledMinute.Singular {
            return try .init(scheduler: self.scheduler, hhmm: hhmm)
        }

        @discardableResult func at(_ timeOfDay: Scheduler.TimeOfDay) throws -> Scheduler.ScheduledSecond.Singular {
            return try .init(scheduler: self.scheduler, timeOfDay: timeOfDay)
        }
    }

    struct Hourly: MinuteBuilderSingular {
        let scheduler: Scheduler

        init() throws {
            self.scheduler = Scheduler()
            scheduler.recurrenceRule.setHourConstraint(try .hourStep(1))
        }

        func atMinute(_ minute: Int) throws -> Scheduler.ScheduledMinute.Singular {
            return try .init(scheduler: scheduler, minute: minute)
        }
    }

    struct EveryXMinutes: SecondBuilderSingular {
        let scheduler: Scheduler

        init(_ minutes: Int) throws {
            self.scheduler = Scheduler()
            scheduler.recurrenceRule.setMinuteConstraint(try .minuteStep(minutes))
        }

        @discardableResult func atSecond(_ second: Int) throws -> Scheduler.ScheduledSecond.Singular {
            return try .init(scheduler: self.scheduler, second: second)
        }
    }

    struct ScheduledQuarter: MonthBuilder {
        init(_ quarter: Int) {

        }

        init(_ quarters: Set<Int>) {

        }

        init(lowerBound: Int, upperBound: Int) {

        }

        // month
        func atMonth(_ month: Int) -> Scheduler.ScheduledMonth { return ScheduledMonth(month) }
        func atMonths(_ months: Set<Int>) -> Scheduler.ScheduledMonth { return ScheduledMonth(months) }
        func atMonthsInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledMonth { return ScheduledMonth(lowerBound: lowerBound, upperBound: upperBound)}

    }

    struct ScheduledMonth: DayOfMonthBuilder, DayOfWeekBuilder {
        //let scheduler: Scheduler

        init(_ month: Int) {

        }

        init(_ months: Set<Int>) {

        }

        init(lowerBound: Int, upperBound: Int) {

        }

        init(scheduler: Scheduler, stepValue: Int) throws {
            //self.scheduler = scheduler
            //try scheduler.recurrenceRule.every(.months(stepValue))
        }

        // dayOfMonth
        func atDayOfMonth(_ dayOfMonth: Int) -> Scheduler.ScheduledDayOfMonth { return ScheduledDayOfMonth(dayOfMonth) }
        func atDaysOfMonth(_ daysOfMonth: Set<Int>) -> Scheduler.ScheduledDayOfMonth { return ScheduledDayOfMonth(daysOfMonth) }
        func atDaysOfMonthInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledDayOfMonth { return ScheduledDayOfMonth(lowerBound: lowerBound, upperBound: upperBound) }

        // dayOfWeek
        func atDayOfWeek(_ dayOfWeek: Int) -> Scheduler.ScheduledDayOfWeek {  return ScheduledDayOfWeek(dayOfWeek) }
        func atDaysOfWeek(_ daysOfWeek: Set<Int>) -> Scheduler.ScheduledDayOfWeek { return ScheduledDayOfWeek(daysOfWeek) }
        func atDaysOfWeekInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledDayOfWeek { return ScheduledDayOfWeek(lowerBound: lowerBound, upperBound: upperBound) }
        func weekdays() -> Scheduler.ScheduledDayOfWeek { return ScheduledDayOfWeek([2, 3, 4, 5, 6]) }
        func weekends() -> Scheduler.ScheduledDayOfWeek { return ScheduledDayOfWeek([1, 7]) }

        struct Singular: DayOfMonthBuilderSingular {
            let scheduler: Scheduler

            init(scheduler: Scheduler, month: Int) throws {
                self.scheduler = scheduler
                scheduler.recurrenceRule.setMonthConstraint(try MonthRecurrenceRuleConstraint.atMonth(month))
            }

            func atDayOfMonth(_ dayOfMonth: Int) throws -> Scheduler.ScheduledDayOfMonth.Singular {
                return try ScheduledDayOfMonth.Singular(scheduler: self.scheduler, dayOfMonth: dayOfMonth)
            }
        }
    }

    struct ScheduledDayOfMonth: HourBuilder, DayOfWeekBuilder {
        init(_ dayOfMonth: Int) {

        }

        init(_ dayOfMonths: Set<Int>) {

        }

        init(lowerBound: Int, upperBound: Int) {

        }

        // dayOfWeek
        func atDayOfWeek(_ dayOfWeek: Int) -> Scheduler.ScheduledDayOfWeek {  return ScheduledDayOfWeek(dayOfWeek) }
        func atDaysOfWeek(_ daysOfWeek: Set<Int>) -> Scheduler.ScheduledDayOfWeek { return ScheduledDayOfWeek(daysOfWeek) }
        func atDaysOfWeekInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledDayOfWeek { return ScheduledDayOfWeek(lowerBound: lowerBound, upperBound: upperBound) }
        func weekdays() -> Scheduler.ScheduledDayOfWeek { return ScheduledDayOfWeek([2, 3, 4, 5, 6]) }
        func weekends() -> Scheduler.ScheduledDayOfWeek { return ScheduledDayOfWeek([1, 7]) }

        // Hour
        func atHour(_ hour: Int) -> Scheduler.ScheduledHour { return ScheduledHour(hour) }
        func atHours(_ hours: Set<Int>) -> Scheduler.ScheduledHour { return ScheduledHour(hours) }
        func atHoursInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledHour { return ScheduledHour(lowerBound: lowerBound, upperBound: upperBound) }

        struct Singular: HourBuilderSingular {
            let scheduler: Scheduler

            init(scheduler: Scheduler, dayOfMonth: Int) throws {
                self.scheduler = scheduler
                self.scheduler.recurrenceRule.setDayOfMonthConstraint(try .atDayOfMonth(dayOfMonth))
            }

            init(scheduler: Scheduler, month: MonthOfYear, dayOfMonth: Int) throws {
                self.scheduler = scheduler
                self.scheduler.recurrenceRule.setMonthConstraint(try .atMonth(month.rawValue))
                self.scheduler.recurrenceRule.setDayOfMonthConstraint(try .atDayOfMonth(dayOfMonth))
            }

            func atHour(_ hour: Int) throws -> Scheduler.ScheduledHour.Singular {
                return try .init(scheduler: self.scheduler, hour: hour)
            }
            func at(_ hhmm: String) throws -> Scheduler.ScheduledMinute.Singular {
                return try .init(scheduler: self.scheduler, hhmm: hhmm)
            }
            @discardableResult func at(_ timeOfDay: Scheduler.TimeOfDay) throws -> Scheduler.ScheduledSecond.Singular {
                return try .init(scheduler: self.scheduler, timeOfDay: timeOfDay)
            }
        }
    }

    struct ScheduledDayOfWeek: HourBuilder, DayOfMonthBuilder {
        init(_ dayOfWeek: Int) {

        }

        init(_ dayOfWeeks: Set<Int>) {

        }

        init(lowerBound: Int, upperBound: Int) {

        }

        init(dayOfWeekStep: Int) {

        }

        // Day Of Month
        func atDayOfMonth(_ dayOfMonth: Int) -> Scheduler.ScheduledDayOfMonth { return ScheduledDayOfMonth(dayOfMonth) }
        func atDaysOfMonth(_ daysOfMonth: Set<Int>) -> Scheduler.ScheduledDayOfMonth { return ScheduledDayOfMonth(daysOfMonth) }
        func atDaysOfMonthInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledDayOfMonth { return ScheduledDayOfMonth(lowerBound: lowerBound, upperBound: upperBound) }

        // Hour
        func atHour(_ hour: Int) -> Scheduler.ScheduledHour { return ScheduledHour(hour) }
        func atHours(_ hours: Set<Int>) -> Scheduler.ScheduledHour { return ScheduledHour(hours) }
        func atHoursInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledHour { return ScheduledHour(lowerBound: lowerBound, upperBound: upperBound) }

        struct Singular: HourBuilderSingular {
            let scheduler: Scheduler

            init(scheduler: Scheduler, dayOfWeek: Int) throws {
                self.scheduler = scheduler
                self.scheduler.recurrenceRule.setDayOfWeekConstraint(try .atDayOfWeek(dayOfWeek))
            }

            func atHour(_ hour: Int) throws -> Scheduler.ScheduledHour.Singular {
                return try .init(scheduler: self.scheduler, hour: hour)
            }

            func at(_ hhmm: String) throws -> Scheduler.ScheduledMinute.Singular {
                return try .init(scheduler: self.scheduler, hhmm: hhmm)
            }

            @discardableResult func at(_ timeOfDay: Scheduler.TimeOfDay) throws -> Scheduler.ScheduledSecond.Singular {
                return try .init(scheduler: self.scheduler, timeOfDay: timeOfDay)
            }
        }
    }

    struct ScheduledHour: MinuteBuilder {
        init(_ dayOfWeek: Int) {

        }

        init(_ dayOfWeeks: Set<Int>) {

        }

        init(lowerBound: Int, upperBound: Int) {

        }

        init(hourStep: Int) {

        }

        // minute
        func atMinute(_ minute: Int) -> Scheduler.ScheduledMinute { return ScheduledMinute(minute) }
        func atMinutes(_ minutes: Set<Int>) -> Scheduler.ScheduledMinute { return ScheduledMinute(minutes) }
        func atMinutesInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledMinute { return ScheduledMinute(lowerBound: lowerBound, upperBound: upperBound) }

        struct Singular: MinuteBuilderSingular {
            let scheduler: Scheduler

            init(scheduler: Scheduler, hour: Int) throws {
                self.scheduler = scheduler
                self.scheduler.recurrenceRule.setHourConstraint(try .atHour(hour))
            }

            func atMinute(_ minute: Int) throws -> Scheduler.ScheduledMinute.Singular {
                return try .init(scheduler: self.scheduler, minute: minute)
            }
        }
    }

    struct ScheduledMinute: SecondBuilder {
        init(_ minute: Int) {

        }

        init(_ minutes: Set<Int>) {

        }

        init(lowerBound: Int, upperBound: Int) {

        }

        // second
        func atSecond(_ second: Int) -> Scheduler.ScheduledSecond { return ScheduledSecond(second) }
        func atSeconds(_ seconds: Set<Int>) -> Scheduler.ScheduledSecond { return ScheduledSecond(seconds) }
        func atSecondsInRange(lowerBound: Int, upperBound: Int) -> Scheduler.ScheduledSecond { return ScheduledSecond(lowerBound: lowerBound, upperBound: upperBound) }

        struct Singular: SecondBuilderSingular {
            let scheduler: Scheduler

            init(scheduler: Scheduler, minute: Int) throws {
                self.scheduler = scheduler
                self.scheduler.recurrenceRule.setMinuteConstraint(try .atMinute(minute))
            }

            init(scheduler: Scheduler, hhmm: String) throws {
                self.scheduler = scheduler
                let hourMinuteTouple = try resolveHourAndMinute(from: hhmm)
                self.scheduler.recurrenceRule.setHourConstraint(try .atHour(hourMinuteTouple.hour))
                self.scheduler.recurrenceRule.setMinuteConstraint(try .atMinute(hourMinuteTouple.minute))
            }

            @discardableResult func atSecond(_ second: Int) throws -> Scheduler.ScheduledSecond.Singular {
                return try .init(scheduler: self.scheduler, second: second)
            }

            private func resolveHourAndMinute(from hhmm: String) throws -> (hour: Int, minute: Int) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "H:mm"
                guard let formattedDate = dateFormatter.date(from: hhmm) else {
                    throw RecurrenceRuleError.couldNotParseHourAndMinuteFromString
                }
                guard let hour = formattedDate.hour() else {
                    throw RecurrenceRuleError.couldNotParseHourAndMinuteFromString
                }
                guard let minute = formattedDate.hour() else {
                    throw RecurrenceRuleError.couldNotParseHourAndMinuteFromString
                }

                return (hour, minute)
            }
        }

    }

    struct ScheduledSecond {
        init(_ second: Int) {

        }

        init(_ seconds: Set<Int>) {

        }

        init(lowerBound: Int, upperBound: Int) {

        }

        struct Singular {
            let scheduler: Scheduler

            init(scheduler: Scheduler, second: Int) throws {
                self.scheduler = scheduler
                self.scheduler.recurrenceRule.setSecondConstraint(try .atSecond(second))
            }

            init(scheduler: Scheduler, timeOfDay: TimeOfDay) throws {
                self.scheduler = scheduler

                switch timeOfDay {
                case .midnight:
                    self.scheduler.recurrenceRule.setHourConstraint(try .atHour(23))
                    self.scheduler.recurrenceRule.setMinuteConstraint(try .atMinute(59))
                    self.scheduler.recurrenceRule.setSecondConstraint(try .atSecond(59))
                case .noon:
                    self.scheduler.recurrenceRule.setHourConstraint(try .atHour(12))
                    self.scheduler.recurrenceRule.setMinuteConstraint(try .atMinute(0))
                    self.scheduler.recurrenceRule.setSecondConstraint(try .atSecond(0))
                }
            }

        }
    }

    struct CronSchedule {
        let scheduler: Scheduler

        init(_ cronString: String) throws {
            let recurrenceRule = try CronParser.parse(cronString)
            scheduler = Scheduler.init()
            scheduler.recurrenceRule = recurrenceRule
        }
    }

    // yearly
    /// Schedules the job to run once a year. Further specification required.
    func yearly() throws -> Yearly { return try Yearly() }

    // monthly
    /// Schedules the job to run once a Month. Further specification required.
    func monthly() throws -> Monthly { return try Monthly() }

    // weekly
    /// Schedules the job to run once a week on the specified day of the week. Further specification is required.
    /// - Parameter dayOfWeek: the day of the week to run
    func weekly(on dayOfWeek: Scheduler.DayOfWeek) throws -> Weekly { return try Weekly(on: dayOfWeek) }
    /// Schedules the job to run once a week on the specified day of the week. Further specification is required.
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    func weekly(onDayOfWeek dayOfWeek: Int) throws -> Weekly { return try Weekly(onDayOfWeek: dayOfWeek) }

    // daily
    /// Schedules the job to run once a day. Further specification is required.
    func daily() throws -> Daily { return try Daily() }

    // daily - convenience
    /// Schedules the job to run every Monday, Tuesday, Wednesday, Thursday, and Friday. Further specification is required.
    func weekdays() throws -> Daily { return try Daily(onDaysOfWeek: [2, 3, 4, 5, 6]) }
    /// Schedules the job to run every Saturday and Sunday. Further specification is required.
    func weekends() throws -> Daily { return try Daily(onDaysOfWeek: [1, 7]) }
    /// Schedules the job to run every Sunday. Further specification is required.
    func sundays() throws -> Daily { return try Daily(onDayOfWeek: 1) }
    /// Schedules the job to run every Monday. Further specification is required.
    func mondays() throws -> Daily { return try Daily(onDayOfWeek: 2) }
    /// Schedules the job to run every Tuesday. Further specification is required.
    func tuesdays() throws -> Daily { return try Daily(onDayOfWeek: 3) }
    /// Schedules the job to run every Wednesday. Further specification is required.
    func wednesdays() throws -> Daily { return try Daily(onDayOfWeek: 4) }
    /// Schedules the job to run every Thursday. Further specification is required.
    func thursdays() throws -> Daily { return try Daily(onDayOfWeek: 5) }
    /// Schedules the job to run every Friday. Further specification is required.
    func fridays() throws -> Daily { return try Daily(onDayOfWeek: 6) }
    /// Schedules the job to run every Saturday. Further specification is required.
    func saturdays() throws -> Daily { return try Daily(onDayOfWeek: 7) }

    // hourly
    /// Schedules the job to run every Hour. Further specification is required.
    func hourly() throws -> Hourly { return try Hourly() }

    // everyXMintues
    /// Schedules the job to run every minute. Further specification is required.
    func everyMinute() throws -> EveryXMinutes { return try EveryXMinutes(1) }
    /// Schedules the job to run every 5 minute. Further specification is required.
    func everyFiveMinutes() throws -> EveryXMinutes { return try EveryXMinutes(5) }
    /// Schedules the job to run every 10 minute. Further specification is required.
    func everyTenMinutes() throws -> EveryXMinutes { return try EveryXMinutes(10) }
    /// Schedules the job to run every 20 minute. Further specification is required.
    func everyFifteenMinutes() throws -> EveryXMinutes { return try EveryXMinutes(15) }
    /// Schedules the job to run every 30 minute. Further specification is required.
    func everyThirtyMinutes() throws -> EveryXMinutes { return try EveryXMinutes(30) }

    /// Schedules a job given a cron string
    ///
    /// - Note: single, list, range, and step values accepted using standard cron rules
    /// - Note: allowed values:
    /// - minute: 0-59
    /// - hour: 0-23
    /// - day (of month): 1-31
    /// - month: 1-12 (i.e 1 - January, 6 - December)
    /// - day (of year): 0-6 (i.e 0 - Sunday, 6 - Saturday)
    ///
    /// - Parameter cronString: a standard cron string
    /// - Throws: throws an error if the cron string is invalid
    func cron(_ cronString: String) throws -> CronSchedule { return try CronSchedule(cronString) }

    /// Runs the job given the specific constraints.
    /// - Note: Use this method for advanced scheduling
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    func whenConstraintsSatisfied(yearConstraint: YearRecurrenceRuleConstraint? = nil,
                                  monthConstraint: MonthRecurrenceRuleConstraint? = nil,
                                  dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint? = nil,
                                  dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint? = nil,
                                  hourConstraint: HourRecurrenceRuleConstraint? = nil,
                                  minuteConstraint: MinuteRecurrenceRuleConstraint? = nil,
                                  secondConstraint: SecondRecurrenceRuleConstraint? = nil) -> RecurrenceRule {
        return RecurrenceRule.init(yearConstraint: yearConstraint,
                                   monthConstraint: monthConstraint,
                                   dayOfMonthConstraint: dayOfMonthConstraint,
                                   dayOfWeekConstraint: dayOfWeekConstraint,
                                   hourConstraint: hourConstraint,
                                   minuteConstraint: minuteConstraint,
                                   secondConstraint: secondConstraint)
    }

}
