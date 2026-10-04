import Foundation

/// 공유 요청은 계속 실행하되, 화면이 사라지거나 대기 시간이 끝나면 호출자는 바로 빠져나온다.
/// Task.value를 task group 안에서 직접 기다리면 취소 후에도 그룹이 해당 요청의 종료를 기다린다.
nonisolated enum AsyncTaskWait {
    static func value<Value: Sendable, Failure: Error>(
        of task: Task<Value, Failure>,
        timeout: Duration? = nil,
        cancelsTaskOnInterruption: Bool = false
    ) async throws -> Value {
        let stream = AsyncThrowingStream<Value, Error> { continuation in
            let observer = Task {
                do {
                    continuation.yield(try await task.value)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            let timer: Task<Void, Never>? = timeout.map { duration in
                Task {
                    do {
                        try await Task.sleep(for: duration)
                        continuation.finish(throwing: URLError(.timedOut))
                    } catch {}
                }
            }
            continuation.onTermination = { termination in
                observer.cancel()
                timer?.cancel()
                if cancelsTaskOnInterruption {
                    switch termination {
                    case .cancelled, .finished(.some): task.cancel()
                    case .finished(.none): break
                    @unknown default: task.cancel()
                    }
                }
            }
        }
        var iterator = stream.makeAsyncIterator()
        guard let value = try await iterator.next() else { throw CancellationError() }
        try Task.checkCancellation()
        return value
    }
}
