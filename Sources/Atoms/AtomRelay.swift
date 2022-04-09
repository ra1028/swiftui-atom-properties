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
/// .observe(Logger())
/// ```
///
public struct AtomRelay<Content: View>: View {
    private let context: AtomViewContext?
    private let content: Content
    private var observers = [AtomObserver]()

    @Environment(\.atomStore)
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
            \.atomStore,
            Store(
                parent: context?._store ?? inheritedStore,
                observers: observers
            )
        )
    }

    /// Observes changes in any atom values and lifecycles used in descendant views.
    ///
    /// This method registers the given observer to notify changes of any atom values.
    /// It would be useful for monitoring and debugging the atoms and for producing side effects in
    /// the changes of particular atom.
    ///
    /// - SeeAlso: ``AtomObserver``
    ///
    /// - Parameter observer: A observer value to observe atom changes.
    ///
    /// - Returns: The self instance.
    public func observe<Observer: AtomObserver>(_ observer: Observer) -> Self {
        mutating { $0.observers.append(observer) }
    }
}

private extension AtomRelay {
    func `mutating`(_ mutation: (inout Self) -> Void) -> Self {
        var view = self
        mutation(&view)
        return view
    }
}
