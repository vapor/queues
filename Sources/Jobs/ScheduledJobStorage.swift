//
//  ScheduledJobStorage.swift
//  
//
//  Created by Jimmy McDermott on 6/11/19.
//

import Foundation
import Vapor

struct ScheduledJobStorage {
    let scheduledJob: ScheduledJob
    let scheduler: Scheduler
}
