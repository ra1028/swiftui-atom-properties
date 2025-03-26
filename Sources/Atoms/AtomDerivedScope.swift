import SwiftUI

/// A view that derives the parent context.
///
/// Sometimes SwiftUI fails to propagate environment values in the view tree for some reason.
/// This is a critical problem because the centralized state store of atoms is propagated through
/// a view hierarchy via environment values.
/// The typical example is that, in case you use SwiftUI view inside UIKit view, it could fail as
/// SwiftUI can't pass environment values to UIKit across boundaries.
/// In that case, you can wrap the view with ``AtomDerivedScope`` and pass a view context to it so that
/// the descendant views can explicitly propagate the atom store.
///
/// ```swift
/// @ViewContext
/// var context
///
/// var body: some View {
///     MyUIViewWrappingView {
///         AtomDerivedScope(context) {
///             MySwiftUIView()
///         }
///     }
/// }
/// ```
///
public struct AtomDerivedScope<Content: View>: View {
    private let store: StoreContext
    private let content: Content

    /// Creates a derived scope with the specified content that will be allowed to use atoms by
    /// passing a view context to explicitly make the descendant views propagate the atom store.
    ///
    /// - Parameters:
    ///   - context: The parent view context that provides the atom store.
    ///   - content: The descendant view content.
    public init(
        _ context: AtomViewContext,
        @ViewBuilder content: () -> Content
    ) {
        self.store = context._store
        self.content = content()
    }

    /// The content and behavior of the view.
    public var body: some View {
        content.environment(\.store, store)
    }
}
