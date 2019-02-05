//
//  JobData.swift
//  Jobs
//
//  Created by Jimmy McDermott on 2/5/19.
//

import Foundation

public protocol JobData: Codable {
    static var jobName: String { get }
}

extension JobData {
    static var key: String {
        return "\(Self.self)"
    }
}
