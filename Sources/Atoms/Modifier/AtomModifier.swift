public extension Atom {
    func modifier<T: AtomModifier>(_ modifier: T) -> ModifiedAtom<Self, T> {
        ModifiedAtom(atom: self, modifier: modifier)
    }
}

public protocol AtomModifier {
    associatedtype Key: Hashable
    associatedtype Coordinator
    associatedtype Value
    associatedtype ModifiedValue

    typealias Context = AtomHookContext<Coordinator>

    var key: Key { get }

    @MainActor
    func shouldNotifyUpdate(newValue: ModifiedValue, oldValue: ModifiedValue) -> Bool

    @MainActor
    func makeCoordinator() -> Coordinator

    @MainActor
    func get(context: Context) -> ModifiedValue?

    @MainActor
    func set(value: ModifiedValue, context: Context)

    @MainActor
    func update(context: Context, with value: Value)
}
