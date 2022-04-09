/// An interface you implement to observe changes in atoms.
///
/// The ``AtomObserver`` protocol provides a comprehensive way to observe changes in atoms
/// such as an atom is assigned, unassigned, or its value is changed.
///
/// The most typical use of this protocol would be logging. The following example creates
/// a custom logger class and prits messages when the assign, unassign, and value update of atoms.
///
/// ```swift
/// struct Logger: AtomObserver {
///     func atomAssigned<Node: Atom>(atom: Node) {
///         print("Assigned: \(atom)")
///     }
///
///     func atomUnassigned<Node: Atom>(atom: Node) {
///         print("Unassigned: \(atom)")
///     }
///
///     func atomChanged<Node: Atom>(snapshot: Snapshot<Node>) {
///         print("Updated: \(snapshot.atom) - value: \(snapshot.value)")
///     }
/// }
///
/// struct TodoApp: App {
///     var body: some Scene {
///         WindowGroup {
///             AtomRoot {
///                 TodoListView()
///             }
///             .observe(Logger())
///         }
///     }
/// }
/// ```
///
@MainActor
public protocol AtomObserver {
    /// Tells the observer an atom has been assigned to any of atoms or views.
    ///
    /// The default implementation does nothing.
    ///
    /// - Parameter atom: The newly assigned atom.
    func atomAssigned<Node: Atom>(atom: Node)

    /// Tells the observer an atom has been unassigned from all atoms or views.
    ///
    /// The default implementation does nothing.
    ///
    /// - Parameter atom: The unassigned atom.
    func atomUnassigned<Node: Atom>(atom: Node)

    /// Tells the observer the value of an atom has been updated.
    ///
    /// The default implementation does nothing.
    ///
    /// - Parameter snapshot: A snapshot structure that contains the updated atom
    ///                       instance and its value.
    func atomChanged<Node: Atom>(snapshot: Snapshot<Node>)
}

public extension AtomObserver {
    func atomAssigned<Node: Atom>(atom: Node) {}
    func atomUnassigned<Node: Atom>(atom: Node) {}
    func atomChanged<Node: Atom>(snapshot: Snapshot<Node>) {}
}
