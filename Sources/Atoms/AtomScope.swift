import SwiftUI

/// A view to override or monitor atoms in scope.
///
/// For some reasons, sometimes SwiftUI can fail to pass environment values in the view-tree.
/// The typical example is that, if you use SwiftUI view inside UIKit view, it could fail as
/// SwiftUI can't pass environment values across UIKit.
/// In that case, you can wrap the view with ``AtomScope`` and pass a view context to it so that
/// the descendant views can explicitly inherit the store.
///
/// ```swift
/// @ViewContext
/// var context
///
/// var body: some View {
///     MyUIViewWrappingView {
///         AtomScope(context) {
///             MySwiftUIView()
///         }
///     }
/// }
/// ```
///
/// ``AtomScope`` can be created without passing a view context, and in this case, it inherits
/// from an internal store through environment values from ``AtomRoot.
/// It allows you to monitor changes of atoms used in descendant views by``AtomScope/observe(_:)``.
///
/// ```swift
/// AtomScope {
///     MyView()
/// }
/// .observe { snapshot in
///     if let count = snapshot.lookup(CounterAtom()) {
///         print(count)
///     }
/// }
/// ```
///
public struct AtomScope<Content: View>: View {
    private let context: AtomViewContext?
    private var observers = [Observer]()
    private let content: Content

    @Environment(\.store)
    private var inheritedStore

    /// Creates an new scope with the specified content that will be allowed to use atoms by
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
            (context?._store ?? inheritedStore).scoped(observers: observers)
        )
    }

    /// For debugging, observes updates with a snapshot that captures a specific set of values of atoms.
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

private extension AtomScope {
    func `mutating`(_ mutation: (inout Self) -> Void) -> Self {
        var view = self
        mutation(&view)
        return view
    }
}
