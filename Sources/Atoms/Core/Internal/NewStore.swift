@MainActor
internal final class NewStore {
    var graph = Graph()
    var state = StoreState()
}

@usableFromInline
@MainActor
internal struct StoreInteractor {
    private weak var store: NewStore?

    init(store: NewStore) {
        self.store = store
    }

    func read<Node: Atom>(_ atom: Node) -> Node.State.Value {
        getValue(of: atom, peekMode: true)
    }

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node) {
        fatalError()
    }

    func watch<Node: Atom, Upstream: Atom>(
        _ atom: Node,
        upstream: Upstream,
        shouldNotifyAfterUpdates: Bool
    ) -> Node.State.Value {
        fatalError()
    }

    func watch<Node: Atom>(
        _ key: Key,
        container: SubscriptionContainer,
        notifyUpdate: @escaping () -> Void
    ) -> String {
        fatalError()
    }

    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomState {
        fatalError()
    }

    func reset<Node: Atom>(_ atom: Node) {
        fatalError()
    }

    func notifyUpdate<Node: Atom>(of atom: Node) {
        fatalError()
    }

    func addTermination<Node: Atom>(for atom: Node, _ termination: @MainActor @escaping () -> Void) {
        fatalError()
    }

    func restore<Node: Atom>(snapshot: Snapshot<Node>) {
        fatalError()
    }
}

private extension StoreInteractor {
    func getValue<Node: Atom>(of atom: Node, peekMode: Bool) -> Node.State.Value {
        let key = AtomKey(atom)

        func getCachedValue<Node: Atom>(of atom: Node) -> Node.State.Value? {
            guard let anyValue = store?.state.values[key] else {
                return nil
            }

            guard let value = anyValue as? Node.State.Value else {
                assertionFailure(
                    """
                    The type of the given atom's value and the cached value did not match.
                    There might be duplicate keys, make sure that the keys for all atom types are unique.

                    Atom type: \(Node.self)
                    Key type: \(type(of: atom.key))
                    Expected value type: \(Node.State.Value.self)
                    Cached value type: \(type(of: anyValue))
                    """
                )

                // Remove the invalid value.
                store?.state.values.removeValue(forKey: key)
                return nil
            }
        }

        if let value = getCachedValue(of: atom) {
            return value
        }

        let context = AtomStateContext(atom: atom, store: self)
        let value = atom.makeState().value(context: context)

        if !peekMode {
            store?.state.values[key] = value
        }

        return value
    }
}
