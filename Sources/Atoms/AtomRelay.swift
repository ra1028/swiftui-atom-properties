import SwiftUI

/// A view that relays an internal store from the passed view context or from environment values.
///
/// For some reasons, sometimes SwiftUI can fail to pass environment values in the view-tree.
/// The typical example is that, if you use SwiftUI view inside UIKit view, it could fail as
/// SwiftUI can't pass environment values across UIKit.
/// In that case, you can wrap the view with ``AtomRelay`` and pass a view context to it so that
/// the descendant views can explicitly inherit an internal store.
///
/// ```swift
/// @ViewContext
/// var context
///
/// var body: some View {
///     MyUIViewWrappingView {
///         AtomRelay(context) {
///             MySwiftUIView()
///         }
///     }
/// }
/// ```
///
/// Also, ``AtomRelay`` can be created without passing a view context, and in this case, it relays
/// an internal store from environment values.
/// Relaying from environment values means that does actually nothing and just inherits an internal
/// store from ``AtomRoot`` as same as usual views, but ``AtomRelay`` provides the modifier
/// ``AtomRelay/observe(_:)`` to monitor all changes in atoms used in descendant views.
///
/// ```swift
/// AtomRelay {
///     MyView()
/// }
/// .observe { snapshot in
///     if let count = snapshot.lookup(CounterAtom()) {
///         print(count)
///     }
/// }
/// ```
///
@MainActor
public struct AtomRelay<Content: View>: View {
    private let context: AtomViewContext?
    private var observers = [Observer]()
    private let content: Content

    @Environment(\.store)
    private var inheritedStore

    /// Creates an atom relay with the specified content that will be allowed to use atoms by
    /// passing a view context to explicitly make the descendant views inherit an internal store.
    ///
    /// - Parameters:
    ///   - context: The parent view context that for inheriting an internal store explicitly.
    ///              Default is nil.
    ///   - content: The view content that inheriting from the parent.
    public init(
        _ context: AtomViewContext? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.context = context
        self.content = content()
    }

    /// The content and behavior of the view.
    public var body: some View {
        content.environment(
            \.store,
            (context?._store ?? inheritedStore).relay(observers: observers)
        )
    }

    /// Observes updates with a snapshot that captures a specific set of values of atoms.
    ///
    /// Use this to monitor and debugging the atoms or for producing side effects.
    ///
    /// - Parameter onUpdate: A closure to handle a snapshot of recent updates.
    ///
    /// - Returns: The self instance.
    public func observe(_ onUpdate: @escaping @MainActor (Snapshot) -> Void) -> Self {
        mutating { $0.observers.append(Observer(onUpdate: onUpdate)) }
    }
}

private extension AtomRelay {
    func `mutating`(_ mutation: (inout Self) -> Void) -> Self {
        var view = self
        mutation(&view)
        return view
    }
}
