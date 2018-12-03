import Foundation
import NIO

public protocol PersistenceLayer {
    func get(key: String) throws -> EventLoopFuture<[Job]>
    func set(key: String, jobs: [Job]) throws -> EventLoopFuture<Void>
}
