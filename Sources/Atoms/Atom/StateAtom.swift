/// An atom type that provides a read-write state value.
///
/// This atom provides a mutable state value that can be accessed from anywhere, and it notifies changes
/// to downstream atoms and views.
/// In addition, there are `willSet`/`didSet` functions to generate side effects in response before and
/// after state changes.
///
/// ## Output Value
///
/// Self.Value
///
/// ## Example
///
/// ```swift
/// struct CounterAtom: StateAtom, Hashable {
///     func defaultValue(context: Context) -> Int {
///         0
///     }
///
///     func willSet(newValue: Int, oldValue: Int, , context: Context) {
///         print("Will change - newValue: \(newValue), oldValue: \(oldValue)")
///     }
///
///     func didSet(newValue: Int, oldValue: Int, context: Context) {
///         print("Did change - newValue: \(newValue), oldValue: \(oldValue)")
///     }
/// }
///
/// struct CounterView: View {
///     @WatchState(CounterAtom())
///     var count
///
///     var body: some View {
///         Stepper("Count: \(count)", value: $count)
///     }
/// }
/// ```
///
public protocol StateAtom: Atom where State == StateAtomState<Value> {
    /// The type of state value that this atom produces.
    associatedtype Value

    /// Creates a default value of the state that to be provided via this atom.
    ///
    /// The value returned from this method will be the default state value. When this atom is reset,
    /// the state will revert to this value.
    ///
    /// - Parameter context: A context structure that to read, watch, and otherwise
    ///                      interacting with other atoms.
    ///
    /// - Returns: A default value of state.
    @MainActor
    func defaultValue(context: Context) -> Value

    /// Observes and responds to changes in the state value which is called just before
    /// the state is changed.
    ///
    /// - Parameters
    ///   - newValue: A new value after update.
    ///   - oldValue: A old value before update.
    ///   - context: A context structure that to read, watch, and otherwise
    ///              interacting with other atoms.
    @MainActor
    func willSet(newValue: Value, oldValue: Value, context: Context)

    /// Observes and responds to changes in the state value which is called just after
    /// the state is changed.
    ///
    /// - Parameters
    ///   - newValue: A new value after update.
    ///   - oldValue: A old value before update.
    ///   - context: A context structure that to read, watch, and otherwise
    ///              interacting with other atoms.
    @MainActor
    func didSet(newValue: Value, oldValue: Value, context: Context)
}

public extension StateAtom {
    @MainActor
    func makeState() -> State {
        State(getDefaultValue: defaultValue)
    }

    @MainActor
    func willSet(newValue: Value, oldValue: Value, context: Context) {}

    @MainActor
    func didSet(newValue: Value, oldValue: Value, context: Context) {}
}
