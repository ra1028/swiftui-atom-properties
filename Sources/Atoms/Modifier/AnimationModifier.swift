import SwiftUI

public extension Atom {
    /// Animates the view watching the atom when the value updates.
    ///
    /// Note that this modifier does nothing when being watched by other atoms.
    ///
    /// ```swift
    /// struct TextAtom: ValueAtom, Hashable {
    ///     func value(context: Context) -> String {
    ///         ""
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(TextAtom().animation())
    ///     var text
    ///
    ///     var body: some View {
    ///         Text(text)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter animation: The animation to apply to the value.
    ///
    /// - Returns: An atom that animates the view watching the atom when the value updates.
    func animation(_ animation: Animation? = .default) -> ModifiedAtom<Self, AnimationModifier<Produced>> {
        modifier(AnimationModifier(animation: animation))
    }
}

/// A modifier that animates the view watching the atom when the value updates.
///
/// Use ``Atom/animation(_:)`` instead of using this modifier directly.
public struct AnimationModifier<T>: AtomModifier {
    /// A type of base value to be modified.
    public typealias BaseValue = T

    /// A type of modified value to provide.
    public typealias Value = T

    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable {
        private let animation: Animation?

        fileprivate init(animation: Animation?) {
            self.animation = animation
        }
    }

    private let animation: Animation?

    internal init(animation: Animation?) {
        self.animation = animation
    }

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key(animation: animation)
    }

    /// Returns a new value for the corresponding atom.
    public func modify(value: BaseValue, context: Context) -> Value {
        value
    }

    /// Manage given overridden value updates and cancellations.
    public func manageOverridden(value: Value, context: Context) -> Value {
        value
    }

    /// Performs transitive update for dependent atoms.
    public func performTransitiveUpdate(_ body: () -> Void) {
        withAnimation(animation, body)
    }
}
