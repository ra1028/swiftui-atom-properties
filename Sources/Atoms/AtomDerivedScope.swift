import SwiftUI

/// A view that derive the parent context.
///
/// Sometimes SwiftUI can fail to pass environment values in the view-tree for some reason,
/// which is critical problem for this library because the whole design of this library depends
/// on environment values.
/// The typical example is that, in case you use SwiftUI view inside UIKit view, it could fail as
/// SwiftUI can't pass environment values to UIKit across boundaries.
/// In that case, you can wrap the view with ``AtomDerivedScope`` and pass a view context to it so that
/// the descendant views can explicitly inherit the store.
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
    private let context: AtomViewContext
    private let content: Content

    /// Creates a derived scope with the specified content that will be allowed to use atoms by
    /// passing a view context to explicitly make the descendant views inherit the atom store.
    ///
    /// - Parameters:
    ///   - context: The parent view context that for deriving the atom store.
    ///   - content: The descendant view content that provides scoped context for atoms.
    public init(
        _ context: AtomViewContext,
        @ViewBuilder content: () -> Content
    ) {
        self.context = context
        self.content = content()
    }

    /// The content and behavior of the view.
    public var body: some View {
        content.environment(\.store, context._store)
    }
}
