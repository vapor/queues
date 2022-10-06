@testable import CoreMetrics
import NIOConcurrencyHelpers
import Vapor

final class CapturingMetricsSystem: MetricsFactory {
    private let lock = NIOLock()
    var counters = [String: any CounterHandler]()
    var recorders = [String: any RecorderHandler]()
    var timers = [String: any TimerHandler]()

    public func makeCounter(label: String, dimensions: [(String, String)]) -> any CounterHandler {
        return self.make(label: label, dimensions: dimensions, registry: &self.counters, maker: TestCounter.init)
    }

    public func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> any RecorderHandler {
        let maker = { (label: String, dimensions: [(String, String)]) in
            TestRecorder(label: label, dimensions: dimensions, aggregate: aggregate)
        }
        return self.make(label: label, dimensions: dimensions, registry: &self.recorders, maker: maker)
    }

    public func makeTimer(label: String, dimensions: [(String, String)]) -> any TimerHandler {
        return self.make(label: label, dimensions: dimensions, registry: &self.timers, maker: TestTimer.init)
    }

    private func make<Item>(label: String, dimensions: [(String, String)], registry: inout [String: Item], maker: (String, [(String, String)]) -> Item) -> Item {
        return self.lock.withLock {
            let item = maker(label, dimensions)
            registry[label] = item
            return item
        }
    }

    func destroyCounter(_ handler: any CounterHandler) {
        if let testCounter = handler as? TestCounter {
            self.counters.removeValue(forKey: testCounter.label)
        }
    }

    func destroyRecorder(_ handler: any RecorderHandler) {
        if let testRecorder = handler as? TestRecorder {
            self.recorders.removeValue(forKey: testRecorder.label)
        }
    }

    func destroyTimer(_ handler: any TimerHandler) {
        if let testTimer = handler as? TestTimer {
            self.timers.removeValue(forKey: testTimer.label)
        }
    }
}

final class TestCounter: CounterHandler, Equatable {
    let id: String
    let label: String
    let dimensions: [(String, String)]

    let lock = NIOLock()
    var values = [(Date, Int64)]()

    init(label: String, dimensions: [(String, String)]) {
        self.id = UUID().uuidString
        self.label = label
        self.dimensions = dimensions
    }

    func increment(by amount: Int64) {
        self.lock.withLock {
            self.values.append((Date(), amount))
        }
        print("adding \(amount) to \(self.label)")
    }

    func reset() {
        self.lock.withLock {
            self.values = []
        }
        print("resetting \(self.label)")
    }

    public static func == (lhs: TestCounter, rhs: TestCounter) -> Bool {
        return lhs.id == rhs.id
    }
}

final class TestRecorder: RecorderHandler, Equatable {
    let id: String
    let label: String
    let dimensions: [(String, String)]
    let aggregate: Bool

    let lock = NIOLock()
    var values = [(Date, Double)]()

    init(label: String, dimensions: [(String, String)], aggregate: Bool) {
        self.id = UUID().uuidString
        self.label = label
        self.dimensions = dimensions
        self.aggregate = aggregate
    }

    func record(_ value: Int64) {
        self.record(Double(value))
    }

    func record(_ value: Double) {
        self.lock.withLock {
            self.values.append((Date(), value))
        }
        print("recording \(value) in \(self.label)")
    }

    public static func == (lhs: TestRecorder, rhs: TestRecorder) -> Bool {
        return lhs.id == rhs.id
    }
}

final class TestTimer: TimerHandler, Equatable {
    let id: String
    let label: String
    var displayUnit: TimeUnit?
    let dimensions: [(String, String)]

    let lock = NIOLock()
    var values = [(Date, Int64)]()

    init(label: String, dimensions: [(String, String)]) {
        self.id = UUID().uuidString
        self.label = label
        self.displayUnit = nil
        self.dimensions = dimensions
    }

    func preferDisplayUnit(_ unit: TimeUnit) {
        self.lock.withLock {
            self.displayUnit = unit
        }
    }

    func retrieveValueInPreferredUnit(atIndex i: Int) -> Double {
        return self.lock.withLock {
            let value = self.values[i].1
            guard let displayUnit = self.displayUnit else {
                return Double(value)
            }
            return Double(value) / Double(displayUnit.scaleFromNanoseconds)
        }
    }

    func recordNanoseconds(_ duration: Int64) {
        self.lock.withLock {
            self.values.append((Date(), duration))
        }
        print("recording \(duration) \(self.label)")
    }

    public static func == (lhs: TestTimer, rhs: TestTimer) -> Bool {
        return lhs.id == rhs.id
    }
}
