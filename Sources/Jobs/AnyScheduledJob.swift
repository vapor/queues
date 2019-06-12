//
//  AnyScheduledJob.swift
//  
//
//  Created by Jimmy McDermott on 6/11/19.
//

import Foundation
import Vapor

struct AnyScheduledJob {
    let job: ScheduledJob
    let scheduler: ScheduleBuilder
}
