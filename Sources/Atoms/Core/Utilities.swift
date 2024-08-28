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
