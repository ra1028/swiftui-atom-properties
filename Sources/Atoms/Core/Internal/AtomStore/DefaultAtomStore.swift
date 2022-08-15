internal struct DefaultAtomStore: AtomStore {
    private let temporaryStore: Store

    nonisolated init() {
        temporaryStore = Store()
    }

    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        store.read(atom)
    }

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node) {
        store.set(value, for: atom)
    }

    func watch<Node: Atom, Dependent: Atom>(_ atom: Node, dependent: Dependent) -> Node.Loader.Value {
        store.watch(atom, dependent: dependent)
    }

    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value {
        store.watch(atom, container: container, notifyUpdate: notifyUpdate)
    }

    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        await store.refresh(atom)
    }

    func reset<Node: Atom>(_ atom: Node) {
        store.reset(atom)
    }

    func relay(observers: [AtomObserver]) -> AtomStore {
        store.relay(observers: observers)
    }
}

private extension DefaultAtomStore {
    @MainActor
    var store: AtomStore {
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
            """
        )
        return RootAtomStore(store: temporaryStore)
    }
}
