import Combine

/// Internal use, a hook type that determines behavioral details of atoms.
@MainActor
public protocol AtomHook {
    associatedtype Coordinator
    associatedtype Value

    /// A type of the context structure that to interact with internal store.
    typealias Context = AtomHookContext<Coordinator>

    /// Creates a coordinator instance.
    func makeCoordinator() -> Coordinator

    /// Gets and returns the value with the given context.
    func value(context: Context) -> Value

    /// Updates and caches the value.
    func update(context: Context)

    /// Overrides with the given value.
    func updateOverride(context: Context, with value: Value)
}

/// Internal use, a hook type that determines behavioral details of atoms which provide `ObservableObject`.
@MainActor
public protocol AtomObservableObjectHook: AtomHook where Value: ObservableObject {}

/// Internal use, a hook type that determines behavioral details of read-write atoms.
@MainActor
public protocol AtomStateHook: AtomHook {
    /// Writes the given value.
    func set(value: Value, context: Context)

    /// Observes to changes in the state which is called just before the state is changed.
    func willSet(newValue: Value, oldValue: Value, context: Context)

    /// Observes to changes in the state which is called just after the state is changed.
    func didSet(newValue: Value, oldValue: Value, context: Context)
}

/// Internal use, a hook type that determines behavioral details of refreshable, asynchronous atoms.
@MainActor
public protocol AtomRefreshableHook: AtomHook {
    /// Refreshes and awaits until the asynchronous value to be updated.
    func refresh(context: Context) async -> Value

    /// Overrides with the given value and awaits until the value to be updated.
    func refreshOverride(context: Context, with value: Value) async -> Value
}

/// Internal use, a hook type that determines behavioral details of atoms which provide `Task`.
@MainActor
public protocol AtomTaskHook: AtomHook where Value == Task<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error

    /// Gets and returns the task with the given context.
    func value(context: Context) -> Task<Success, Failure>
}

internal extension AtomHook {
    func _assertingFallbackValue(context: Context, file: StaticString = #file, line: UInt = #line) -> Value {
        assertionFailure(
            "[Atoms] Internal Logic Failure: Call `AtomHook/update(context:)` before accessing value.",
            file: file,
            line: line
        )

        update(context: context)
        return value(context: context)
    }
}
