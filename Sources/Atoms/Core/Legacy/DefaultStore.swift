internal struct DefaultStore: AtomStore {
    private let fallbackContainer = StoreContainer()

    var container: StoreContainer? {
        fallbackContainer
    }

    var overrides: AtomOverrides? {
        nil
    }

    var observers: [AtomObserver] {
        []
    }

    func read<Node: Atom>(_ atom: Node) -> Node.State.Value {
        assertionFailureStoreNotProvided()
        return fallbackStore.read(atom)
    }

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node) {
        assertionFailureStoreNotProvided()
        fallbackStore.set(value, for: atom)
    }

    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomState {
        assertionFailureStoreNotProvided()
        return await fallbackStore.refresh(atom)
    }

    func reset<Node: Atom>(_ atom: Node) {
        assertionFailureStoreNotProvided()
        fallbackStore.reset(atom)
    }

    func watch<Node: Atom>(
        _ atom: Node,
        relationship: Relationship,
        shouldNotifyAfterUpdates: Bool,
        notifyUpdate: @escaping @MainActor () -> Void
    ) -> Node.State.Value {
        assertionFailureStoreNotProvided()
        return fallbackStore.watch(
            atom,
            relationship: relationship,
            shouldNotifyAfterUpdates: shouldNotifyAfterUpdates,
            notifyUpdate: notifyUpdate
        )
    }

    func watch<Node: Atom, Caller: Atom>(
        _ atom: Node,
        belongTo caller: Caller,
        shouldNotifyAfterUpdates: Bool
    ) -> Node.State.Value {
        assertionFailureStoreNotProvided()
        return fallbackStore.watch(
            atom,
            belongTo: caller,
            shouldNotifyAfterUpdates: shouldNotifyAfterUpdates
        )
    }

    func notifyUpdate<Node: Atom>(_ atom: Node) {
        assertionFailureStoreNotProvided()
        fallbackStore.notifyUpdate(atom)
    }

    func addTermination<Node: Atom>(_ atom: Node, termination: @MainActor @escaping () -> Void) {
        assertionFailureStoreNotProvided()
        fallbackStore.addTermination(atom, termination: termination)
    }
}

private extension DefaultStore {
    @MainActor
    var fallbackStore: Store {
        Store(container: fallbackContainer)
    }

    func assertionFailureStoreNotProvided(file: StaticString = #file, line: UInt = #line) {
        assertionFailure(
            """
            [Atoms]
            There is no `Store` provided to hold the Atom on this view tree.
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
            consider using `AtomRelay` to pass it.
            That happens when using SwiftUI view wrapped with `UIHostingController`.

            ```
            struct ExampleView: View {
                @ViewContext
                var context

                var body: some View {
                    UIViewWrappingView {
                        AtomRelay(context) {
                            WrappedView()
                        }
                    }
                }
            }
            ```

            The modal screen presented by the `.sheet` modifier or etc, inherits from the environment values,
            but only in iOS14, there is a bug where the environment values will be dismantled during it is
            dismissing. This also can be avoided by using `AtomRelay` to explicitly inherit from it.

            ```
            .sheet(isPresented: ...) {
                AtomRelay(context) {
                    ExampleView()
                }
            }
            ```
            """,
            file: file,
            line: line
        )
    }
}
