import os

internal struct UnsafeUncheckedSendable<Value>: @unchecked Sendable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}
