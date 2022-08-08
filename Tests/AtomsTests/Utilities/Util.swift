final class Object {
    var onDeinit: (() -> Void)?

    deinit {
        onDeinit?()
    }
}

struct UniqueKey: Hashable {}
