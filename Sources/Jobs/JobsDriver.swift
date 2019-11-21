public protocol JobsDriver {
    func makeQueue(with context: JobContext) -> JobsQueue
    func shutdown()
}
