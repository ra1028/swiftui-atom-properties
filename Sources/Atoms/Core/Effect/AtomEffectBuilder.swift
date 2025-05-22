// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
@MainActor
@resultBuilder
public enum AtomEffectBuilder {
    public static func buildExpression<Effect: AtomEffect>(_ effect: Effect) -> Effect {
        effect
    }

    public static func buildBlock<Effect: AtomEffect>(_ effect: Effect) -> Effect {
        effect
    }

    public static func buildBlock<each Effect: AtomEffect>(_ effect: repeat each Effect) -> some AtomEffect {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            return BlockEffect(repeat each effect)
        }
        else {
            return BlockBCEffect(repeat each effect)
        }
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
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    struct BlockEffect<each Effect: AtomEffect>: AtomEffect {
        private let effect: (repeat each Effect)

        init(_ effect: repeat each Effect) {
            self.effect = (repeat each effect)
        }

        func initializing(context: Context) {
            repeat (each effect).initializing(context: context)
        }

        func initialized(context: Context) {
            repeat (each effect).initialized(context: context)
        }

        func updated(context: Context) {
            repeat (each effect).updated(context: context)
        }

        func released(context: Context) {
            repeat (each effect).released(context: context)
        }
    }

    struct BlockBCEffect: AtomEffect {
        private let _initializing: @MainActor (Context) -> Void
        private let _initialized: @MainActor (Context) -> Void
        private let _updated: @MainActor (Context) -> Void
        private let _released: @MainActor (Context) -> Void

        init<each Effect: AtomEffect>(_ effect: repeat each Effect) {
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

        func initializing(context: Context) {
            _initializing(context)
        }

        func initialized(context: Context) {
            _initialized(context)
        }

        func updated(context: Context) {
            _updated(context)
        }

        func released(context: Context) {
            _released(context)
        }
    }

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
