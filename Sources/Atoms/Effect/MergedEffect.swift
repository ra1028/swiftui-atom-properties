// Use type pack once it is available in iOS 17 or newer.
// MergedEffect<each Effect: AtomEffect>
/// An atom effect that merges multiple atom effects into one.
public struct MergedEffect: AtomEffect {
    private let initialized: @MainActor (Context) -> Void
    private let updated: @MainActor (Context) -> Void
    private let released: @MainActor (Context) -> Void

    /// Creates an atom effect that merges multiple atom effects into one.
    public init<each Effect: AtomEffect>(_ effect: repeat each Effect) {
        initialized = { @Sendable context in
            repeat (each effect).initialized(context: context)
        }
        updated = { @Sendable context in
            repeat (each effect).updated(context: context)
        }
        released = { @Sendable context in
            repeat (each effect).released(context: context)
        }
    }

    /// A lifecycle event that is triggered when the atom is first used and initialized,
    /// or once it is released and re-initialized again.
    public func initialized(context: Context) {
        initialized(context)
    }

    /// A lifecycle event that is triggered when the atom is updated.
    public func updated(context: Context) {
        updated(context)
    }

    /// A lifecycle event that is triggered when the atom is no longer watched and released.
    public func released(context: Context) {
        released(context)
    }
}
