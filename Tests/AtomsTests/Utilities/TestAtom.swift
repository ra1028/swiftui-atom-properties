import Atoms

struct TestAtom<Key: Hashable, Hook: AtomHook>: Atom {
    var key: Key
    var hook: Hook
}

struct TestValueAtom<T: Hashable>: ValueAtom, Hashable {
    let value: T

    func value(context: Context) -> T {
        value
    }
}

struct TestStateAtom<T: Hashable>: StateAtom, Hashable {
    let defaultValue: T

    func defaultValue(context: Context) -> T {
        defaultValue
    }
}

struct TestTaskAtom<T: Hashable>: TaskAtom, Hashable {
    let value: T

    func value(context: Context) async -> T {
        value
    }
}
