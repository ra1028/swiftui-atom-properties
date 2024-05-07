// Use Parameter packs in generic types once it is available in iOS 17 or newer.
// MergedEffect<each Effect: AtomEffect>
public struct MergedEffect: AtomEffect {
    private let initialized: (Context) -> Void
    private let updated: (Context) -> Void
    private let released: (Context) -> Void

    public init<each Effect: AtomEffect>(_ effect: repeat each Effect) {
        initialized = { context in
            repeat (each effect).initialized(context: context)
        }
        updated = { context in
            repeat (each effect).updated(context: context)
        }
        released = { context in
            repeat (each effect).released(context: context)
        }
    }

    public func initialized(context: Context) {
        initialized(context)
    }

    public func updated(context: Context) {
        updated(context)
    }

    public func released(context: Context) {
        released(context)
    }
}
