import Foundation

actor LogActor {
    private var configuration: LoggerConfiguration
    private let batcher: EventBatcher
    private var scheduledFlushTask: Task<Void, Never>?

    init(configuration: LoggerConfiguration) {
        self.configuration = configuration
        self.batcher = EventBatcher(configuration: configuration.batching)
    }

    func updateConfiguration(_ configuration: LoggerConfiguration) {
        self.configuration = configuration
    }

    func enqueue(_ event: LogEvent) async {
        if let batch = await batcher.add(event) {
            await dispatchToDestinations(batch)
        } else if configuration.batching.enabled {
            scheduleBatcherFlush()
        }
    }

    func flush() async {
        scheduledFlushTask?.cancel()
        scheduledFlushTask = nil

        let batch = await batcher.flush()
        if !batch.isEmpty {
            await dispatchToDestinations(batch)
        }

        for destination in configuration.destinations {
            try? await destination.flush()
        }
    }

    func shutdown() async {
        await flush()
    }

    private func scheduleBatcherFlush() {
        guard scheduledFlushTask == nil else { return }

        let waitInterval = configuration.batching.maxWaitInterval
        scheduledFlushTask = Task {
            try? await Task.sleep(for: .seconds(waitInterval))
            guard !Task.isCancelled else { return }
            await self.flushBatcherOnly()
        }
    }

    private func flushBatcherOnly() async {
        scheduledFlushTask = nil
        let batch = await batcher.flush()
        guard !batch.isEmpty else { return }
        await dispatchToDestinations(batch)
    }

    private func dispatchToDestinations(_ events: [LogEvent]) async {
        for destination in configuration.destinations {
            let filtered = events.filter { $0.level >= destination.minimumLevel }
            guard !filtered.isEmpty else { continue }

            do {
                try await destination.writeBatch(filtered)
            } catch {
                #if DEBUG
                print("LoggerSDK: destination '\(destination.identifier)' failed: \(error)")
                #endif
            }
        }
    }
}
