public protocol AtomModifier: AtomHook {
    associatedtype Key: Hashable

    var key: Key { get }

    func shouldNotifyUpdate(newValue: Value, oldValue: Value) -> Bool
}
