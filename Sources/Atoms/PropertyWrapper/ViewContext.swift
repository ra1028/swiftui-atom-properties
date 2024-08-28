import SwiftUI

/// A property wrapper type that provides a context structure to read, watch, and otherwise
/// interact with atoms from views.
///
/// Through the provided context, the view can read, write, or perform other interactions with atoms.
/// If the view watches an atom through the context, the view invalidates its appearance and recompute
/// the body when the atom value updates.
///
/// - SeeAlso: ``AtomViewContext``
///
/// ## Example
///
/// ```swift
/// struct CounterView: View {
///     @ViewContext
///     var context
///
///     var body: some View {
///         VStack {
///             Text("Count: \(context.watch(CounterAtom()))")  // Read value, and start watching.
///             Button("Increment") {
///                 context[CounterAtom()] += 1                 // Mutation which means simultaneous read-write access.
///             }
///             Button("Reset") {
///                 context.reset(CounterAtom())                // Reset to default value.
///             }
///         }
///     }
/// }
/// ```
///
@propertyWrapper
public struct ViewContext: DynamicProperty {
    @StateObject
    private var state = State()

    @Environment(\.store)
    private var _store

    private let file: StaticString
    private let location: SourceLocation

    /// Creates a view context.
    public init(file: StaticString = #file, fileID: String = #fileID, line: UInt = #line) {
        self.file = file
        self.location = SourceLocation(fileID: fileID, line: line)
    }

    /// The underlying view context to interact with atoms.
    ///
    /// This property provides primary access to the view context. However you don't
    /// access ``wrappedValue`` directly.
    /// Instead, you use the property variable created with the `@ViewContext` attribute.
    public var wrappedValue: AtomViewContext {
        AtomViewContext(
            store: store,
            subscriber: Subscriber(state.subscriberState),
            subscription: Subscription(
                location: location,
                update: { [weak state] in
                    state?.objectWillChange.send()
                }
            )
        )
    }
}

private extension ViewContext {
    @MainActor
    final class State: ObservableObject {
        let subscriberState = SubscriberState()
    }

    var store: StoreContext {
        guard let _store else {
            assertionFailure(
                """
                [Atoms]
                There is no store provided on the current view tree.
                Make sure that this application has an `AtomRoot` as a root ancestor of any view.

                ```
                struct ExampleApp: App {
                    var body: some Scene {
                        WindowGroup {
                            AtomRoot {
                                ExampleView()
                            }
                        }
                    }
                }
                ```

                If for some reason the view tree is formed that does not inherit from `EnvironmentValues`,
                consider using `AtomScope` to pass it.
                That happens when using SwiftUI view wrapped with `UIHostingController`.

                ```
                struct ExampleView: View {
                    @ViewContext
                    var context

                    var body: some View {
                        UIViewWrappingView {
                            AtomScope(inheriting: context) {
                                WrappedView()
                            }
                        }
                    }
                }
                ```

                The modal screen presented by the `.sheet` modifier or etc, inherits from the environment values,
                but only in iOS14, there is a bug where the environment values will be dismantled during it is
                dismissing. This also can be avoided by using `AtomScope` to explicitly inherit from it.

                ```
                .sheet(isPresented: ...) {
                    AtomScope(inheriting: context) {
                        ExampleView()
                    }
                }
                ```
                """,
                file: file,
                line: location.line
            )

            // Returns an ephemeral instance just to not crash in `-O` builds.
            return StoreContext(
                store: AtomStore(),
                scopeKey: ScopeKey(token: ScopeKey.Token()),
                inheritedScopeKeys: [:],
                observers: [],
                scopedObservers: [],
                overrides: [:],
                scopedOverrides: [:]
            )
        }

        return _store
    }
}
