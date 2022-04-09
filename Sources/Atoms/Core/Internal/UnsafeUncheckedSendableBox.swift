internal struct UnsafeUncheckedSendableBox<T>: @unchecked Sendable {
    let unboxed: T

    init(_ unboxed: T) {
        self.unboxed = unboxed
    }
}
