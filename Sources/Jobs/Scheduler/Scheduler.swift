import Foundation

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

/// 'Singular Builders' are structs that can only be scheduled at one point in time
/// ex MonthBuilderSingular is schedules a single point in time in one day at a single month

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

extension JobsConfig {
    mutating public func schedule<J: Job>(_ job: J) -> Scheduler {
        self.add(job)
        return scheduler
    }
}

public final class Scheduler {
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
        case startOfDay
        case endOfDay
        case noon
    }

    struct Yearly: MonthBuilderSingular {
        let scheduler: Scheduler

        init(_ scheduler: Scheduler) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
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

        init(_ scheduler: Scheduler) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
            scheduler.recurrenceRule.setMonthConstraint(try MonthRecurrenceRuleConstraint.monthStep(1))
        }

        func atDayOfMonth(_ dayOfMonth: Int) throws -> Scheduler.ScheduledDayOfMonth.Singular {
            return try .init(scheduler: self.scheduler, dayOfMonth: dayOfMonth)
        }
    }

    struct Weekly: HourBuilderSingular {
        let scheduler: Scheduler

        init(_ scheduler: Scheduler, onDayOfWeek dayOfWeek: Int) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
            scheduler.recurrenceRule.setDayOfWeekConstraint(try .atDayOfWeek(dayOfWeek))
        }

        init(_ scheduler: Scheduler, on dayOfWeek: Scheduler.DayOfWeek) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
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

        init(_ scheduler: Scheduler) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
            scheduler.recurrenceRule.setDayOfWeekConstraint(try .dayOfWeekStep(1))
        }

        init(_ scheduler: Scheduler, onDaysOfWeek daysOfWeek: Set<Int>) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
            scheduler.recurrenceRule.setDayOfWeekConstraint(try .atDaysOfWeek(daysOfWeek))
        }

        init(_ scheduler: Scheduler, onDayOfWeek dayOfWeek: Int) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
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

        init(_ scheduler: Scheduler) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
            scheduler.recurrenceRule.setHourConstraint(try .hourStep(1))
        }

        func atMinute(_ minute: Int) throws -> Scheduler.ScheduledMinute.Singular {
            return try .init(scheduler: scheduler, minute: minute)
        }
    }

    struct EveryXMinutes: SecondBuilderSingular {
        let scheduler: Scheduler

        init(_ scheduler: Scheduler, minutes: Int) throws {
            self.scheduler = scheduler
            scheduler.recurrenceRule = RecurrenceRule()
            scheduler.recurrenceRule.setMinuteConstraint(try .minuteStep(minutes))
        }

        @discardableResult func atSecond(_ second: Int) throws -> Scheduler.ScheduledSecond.Singular {
            return try .init(scheduler: self.scheduler, second: second)
        }
    }

    struct ScheduledMonth {
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

    struct ScheduledDayOfMonth {
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

    struct ScheduledDayOfWeek {
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

    struct ScheduledHour {
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

    struct ScheduledMinute {
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
                guard let minute = formattedDate.minute() else {
                    throw RecurrenceRuleError.couldNotParseHourAndMinuteFromString
                }
                return (hour, minute)
            }
        }

    }

    struct ScheduledSecond {
        struct Singular {
            let scheduler: Scheduler

            init(scheduler: Scheduler, second: Int) throws {
                self.scheduler = scheduler
                self.scheduler.recurrenceRule.setSecondConstraint(try .atSecond(second))
            }

            init(scheduler: Scheduler, timeOfDay: TimeOfDay) throws {
                self.scheduler = scheduler

                switch timeOfDay {
                case .startOfDay:
                    self.scheduler.recurrenceRule.setHourConstraint(try .atHour(0))
                    self.scheduler.recurrenceRule.setMinuteConstraint(try .atMinute(0))
                    self.scheduler.recurrenceRule.setSecondConstraint(try .atSecond(0))
                case .endOfDay:
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


    // yearly
    /// Schedules the job to run once a year. Further specification required.
    func yearly() throws -> Yearly { return try Yearly(self) }

    // monthly
    /// Schedules the job to run once a Month. Further specification required.
    func monthly() throws -> Monthly { return try Monthly(self) }

    // weekly
    /// Schedules the job to run once a week on the specified day of the week. Further specification is required.
    /// - Parameter dayOfWeek: the day of the week to run
    func weekly(on dayOfWeek: Scheduler.DayOfWeek) throws -> Weekly { return try Weekly(self, on: dayOfWeek) }

    /// Schedules the job to run once a week on the specified day of the week. Further specification is required.
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    func weekly(onDayOfWeek dayOfWeek: Int) throws -> Weekly { return try Weekly(self, onDayOfWeek: dayOfWeek) }

    // daily
    /// Schedules the job to run once a day. Further specification is required.
    func daily() throws -> Daily { return try Daily(self) }

    // daily - convenience
    /// Schedules the job to run every Monday, Tuesday, Wednesday, Thursday, and Friday. Further specification is required.
    func weekdays() throws -> Daily { return try Daily(self, onDaysOfWeek: [2, 3, 4, 5, 6]) }
    /// Schedules the job to run every Saturday and Sunday. Further specification is required.
    func weekends() throws -> Daily { return try Daily(self, onDaysOfWeek: [1, 7]) }
    /// Schedules the job to run every Sunday. Further specification is required.
    func sundays() throws -> Daily { return try Daily(self, onDayOfWeek: 1) }
    /// Schedules the job to run every Monday. Further specification is required.
    func mondays() throws -> Daily { return try Daily(self, onDayOfWeek: 2) }
    /// Schedules the job to run every Tuesday. Further specification is required.
    func tuesdays() throws -> Daily { return try Daily(self, onDayOfWeek: 3) }
    /// Schedules the job to run every Wednesday. Further specification is required.
    func wednesdays() throws -> Daily { return try Daily(self, onDayOfWeek: 4) }
    /// Schedules the job to run every Thursday. Further specification is required.
    func thursdays() throws -> Daily { return try Daily(self, onDayOfWeek: 5) }
    /// Schedules the job to run every Friday. Further specification is required.
    func fridays() throws -> Daily { return try Daily(self, onDayOfWeek: 6) }
    /// Schedules the job to run every Saturday. Further specification is required.
    func saturdays() throws -> Daily { return try Daily(self, onDayOfWeek: 7) }

    // hourly
    /// Schedules the job to run every Hour. Further specification is required.
    func hourly() throws -> Hourly { return try Hourly(self) }

    // everyXMintues
    // a method for minutes divisible by 60

    /// Schedules the job to run every minute. Further specification is required.
    func everyMinute() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 1) }
    /// Schedules the job to run every 2 minutes. Further specification is required.
    func everyTwoMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 2) }
    /// Schedules the job to run every 3 minutes. Further specification is required.
    func everyThreeMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 3) }
    /// Schedules the job to run every 4 minutes. Further specification is required.
    func everyFourMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 4) }
    /// Schedules the job to run every 5 minutew. Further specification is required.
    func everyFiveMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 5) }
    /// Schedules the job to run every 6 minutes. Further specification is required.
    func everySixMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 6) }
    /// Schedules the job to run every 10 minutes. Further specification is required.
    func everyTenMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 10) }
    /// Schedules the job to run every 12 minutes. Further specification is required.
    func everyTwelveMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 12) }
    /// Schedules the job to run every 20 minutes. Further specification is required.
    func everyFifteenMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 15) }
    /// Schedules the job to run every 20 minutes. Further specification is required.
    func everyTwentyMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 20) }
    /// Schedules the job to run every 30 minutes. Further specification is required.
    func everyThirtyMinutes() throws -> EveryXMinutes { return try EveryXMinutes(self, minutes: 30) }

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
    func cron(_ cronString: String) throws {
        let recurrenceRule = try CronParser.parse(cronString)
        self.recurrenceRule = recurrenceRule
    }

    /// Runs the job given the specific constraints.
    /// - Note: Use this method for advanced scheduling
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    func whenConstraintsSatisfied(yearConstraint: YearRecurrenceRuleConstraint? = nil,
                                  monthConstraint: MonthRecurrenceRuleConstraint? = nil,
                                  dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint? = nil,
                                  dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint? = nil,
                                  hourConstraint: HourRecurrenceRuleConstraint? = nil,
                                  minuteConstraint: MinuteRecurrenceRuleConstraint? = nil,
                                  secondConstraint: SecondRecurrenceRuleConstraint? = nil) {
        self.recurrenceRule = RecurrenceRule.init(yearConstraint: yearConstraint,
                             monthConstraint: monthConstraint,
                             dayOfMonthConstraint: dayOfMonthConstraint,
                             dayOfWeekConstraint: dayOfWeekConstraint,
                             hourConstraint: hourConstraint,
                             minuteConstraint: minuteConstraint,
                             secondConstraint: secondConstraint)
    }

}
