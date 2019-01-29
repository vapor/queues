//
//  ScheduledJob.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation

public struct ScheduledJob {
    let job: Job
    let recurrenceRule: RecurrenceRule

    public init(job: Job, at recurrenceRule: RecurrenceRule) {
        self.job = job
        self.recurrenceRule = recurrenceRule
    }
}
