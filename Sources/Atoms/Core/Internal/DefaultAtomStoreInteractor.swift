internal struct DefaultAtomStoreInteractor: AtomStoreInteractor {
    private let temporaryStore: NewAtomStore

    nonisolated init() {
        temporaryStore = NewAtomStore()
    }

    func read<Node: Atom>(_ atom: Node) -> Node.State.Value {
        temporaryInteractor.read(atom)
    }

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node) {
        temporaryInteractor.set(value, for: atom)
    }

    func watch<Node: Atom, Downstream: Atom>(_ atom: Node, downstream: Downstream) -> Node.State.Value {
        temporaryInteractor.watch(atom, downstream: downstream)
    }

    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.State.Value {
        temporaryInteractor.watch(atom, container: container, notifyUpdate: notifyUpdate)
    }

    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomValue {
        await temporaryInteractor.refresh(atom)
    }

    func reset<Node: Atom>(_ atom: Node) {
        temporaryInteractor.reset(atom)
    }

    func notifyUpdate<Node: Atom>(of atom: Node) {
        temporaryInteractor.notifyUpdate(of: atom)
    }

    func addTermination<Node: Atom>(for atom: Node, _ termination: @MainActor @escaping () -> Void) {
        temporaryInteractor.addTermination(for: atom, termination)
    }

    func relay(observers: [AtomObserver]) -> AtomStoreInteractor {
        temporaryInteractor.relay(observers: observers)
    }
}

private extension DefaultAtomStoreInteractor {
    @MainActor
    var temporaryInteractor: AtomStoreInteractor {
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
        return RootAtomStoreInteractor(store: temporaryStore)
    }
}
