// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
/// A result builder for composing multiple atom effects into a single effect.
///
/// ## Example
/// ```swift
/// @AtomEffectBuilder
/// func effect(context: CurrentContext) -> some AtomEffect {
///     UpdateEffect {
///         print("Updated")
///     }
///
///     ReleaseEffect {
///         print("Released")
///     }
///
///     CustomEffect()
/// }
/// ```
@MainActor
@resultBuilder
public enum AtomEffectBuilder {
    public static func buildBlock() -> some AtomEffect {
        EmptyEffect()
    }

    public static func buildBlock<Effect: AtomEffect>(_ effect: Effect) -> Effect {
        effect
    }

    // NB: The combination of variadic type and opaque return type in iOS 16 fails to demangle
    // the witness for the return type, which causes a runtime crash.
    // Once iOS 16 support is dropped, this function will be changed to return an opaque type.
    public static func buildBlock<each Effect: AtomEffect>(_ effect: repeat each Effect) -> BlockEffect {
        BlockEffect(repeat each effect)
    }

    public static func buildIf<Effect: AtomEffect>(_ effect: Effect?) -> some AtomEffect {
        IfEffect(effect)
    }

    public static func buildEither<TrueEffect: AtomEffect, FalseEffect: AtomEffect>(
        first: TrueEffect
    ) -> ConditionalEffect<TrueEffect, FalseEffect> {
        ConditionalEffect(storage: .trueEffect(first))
    }

    public static func buildEither<TrueEffect: AtomEffect, FalseEffect: AtomEffect>(
        second: FalseEffect
    ) -> ConditionalEffect<TrueEffect, FalseEffect> {
        ConditionalEffect(storage: .falseEffect(second))
    }

    public static func buildLimitedAvailability(_ effect: any AtomEffect) -> some AtomEffect {
        LimitedAvailabilityEffect(effect)
    }
}

public extension AtomEffectBuilder {
    // Use type pack once it is available in iOS 17 or newer.
    // struct BlockEffect<each Effect: AtomEffect>: AtomEffect
    struct BlockEffect: AtomEffect {
        private let _initializing: @MainActor (Context) -> Void
        private let _initialized: @MainActor (Context) -> Void
        private let _updated: @MainActor (Context) -> Void
        private let _released: @MainActor (Context) -> Void

        internal init<each Effect: AtomEffect>(_ effect: repeat each Effect) {
            _initializing = { context in
                repeat (each effect).initializing(context: context)
            }
            _initialized = { context in
                repeat (each effect).initialized(context: context)
            }
            _updated = { context in
                repeat (each effect).updated(context: context)
            }
            _released = { context in
                repeat (each effect).released(context: context)
            }
        }

        public func initializing(context: Context) {
            _initializing(context)
        }

        public func initialized(context: Context) {
            _initialized(context)
        }

        public func updated(context: Context) {
            _updated(context)
        }

        public func released(context: Context) {
            _released(context)
        }
    }

    struct ConditionalEffect<TrueEffect: AtomEffect, FalseEffect: AtomEffect>: AtomEffect {
        internal enum Storage {
            case trueEffect(TrueEffect)
            case falseEffect(FalseEffect)
        }

        private let storage: Storage

        internal init(storage: Storage) {
            self.storage = storage
        }

        public func initializing(context: Context) {
            switch storage {
            case .trueEffect(let trueEffect):
                trueEffect.initializing(context: context)

            case .falseEffect(let falseEffect):
                falseEffect.initializing(context: context)
            }
        }

        public func initialized(context: Context) {
            switch storage {
            case .trueEffect(let trueEffect):
                trueEffect.initialized(context: context)

            case .falseEffect(let falseEffect):
                falseEffect.initialized(context: context)
            }
        }

        public func updated(context: Context) {
            switch storage {
            case .trueEffect(let trueEffect):
                trueEffect.updated(context: context)

            case .falseEffect(let falseEffect):
                falseEffect.updated(context: context)
            }
        }

        public func released(context: Context) {
            switch storage {
            case .trueEffect(let trueEffect):
                trueEffect.released(context: context)
            case .falseEffect(let falseEffect):
                falseEffect.released(context: context)
            }
        }
    }
}

private extension AtomEffectBuilder {
    struct EmptyEffect: AtomEffect {}

    struct IfEffect<Effect: AtomEffect>: AtomEffect {
        private let effect: Effect?

        init(_ effect: Effect?) {
            self.effect = effect
        }

        func initializing(context: Context) {
            effect?.initializing(context: context)
        }

        func initialized(context: Context) {
            effect?.initialized(context: context)
        }

        func updated(context: Context) {
            effect?.updated(context: context)
        }

        func released(context: Context) {
            effect?.released(context: context)
        }
    }

    struct LimitedAvailabilityEffect: AtomEffect {
        private let effect: any AtomEffect

        init(_ effect: any AtomEffect) {
            self.effect = effect
        }

        func initializing(context: Context) {
            effect.initializing(context: context)
        }

        func initialized(context: Context) {
            effect.initialized(context: context)
        }

        func updated(context: Context) {
            effect.updated(context: context)
        }

        func released(context: Context) {
            effect.released(context: context)
        }
    }
}
