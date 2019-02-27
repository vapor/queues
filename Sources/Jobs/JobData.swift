//
//  JobData.swift
//  Jobs
//
//  Created by Jimmy McDermott on 2/5/19.
//

import Foundation

/// Context that can be stored with a `Job`
public protocol JobData: Codable {
    
    /// The name of the `Job`
    static var jobName: String { get }
}

public extension JobData {
    
    /// See `JobData.jobName`
    static var jobName: String {
        return "\(Self.self)"
    }
}
