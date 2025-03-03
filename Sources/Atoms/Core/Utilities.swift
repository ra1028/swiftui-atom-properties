import Foundation

@inlinable
internal func `mutating`<T>(_ value: T, _ mutation: (inout T) -> Void) -> T {
    var value = value
    mutation(&value)
    return value
}

internal extension Task where Success == Never, Failure == Never {
    @inlinable
    static func sleep(seconds duration: Double) async throws {
        try await sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
}

internal extension MainActor {
    static func performIsolated(
        _ operation: @MainActor @escaping () -> Void,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(operation, file: file, line: line)
        }
        else {
            Task { @MainActor in
                operation()
            }
        }
    }
}
