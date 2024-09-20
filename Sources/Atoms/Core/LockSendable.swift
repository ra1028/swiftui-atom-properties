import os

internal final class LockSendable<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = os_unfair_lock_t.allocate(capacity: 1)

    init(_ value: Value) {
        _value = value
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    var value: Value {
        _read {
            lock.lock()
            defer { lock.unlock() }
            yield _value
        }
        _modify {
            lock.lock()
            defer { lock.unlock() }
            yield &_value
        }
    }
}

private extension UnsafeMutablePointer where Pointee == os_unfair_lock_s {
    @inline(__always)
    func lock() {
        os_unfair_lock_lock(self)
    }

    @inline(__always)
    func unlock() {
        os_unfair_lock_unlock(self)
    }
}
