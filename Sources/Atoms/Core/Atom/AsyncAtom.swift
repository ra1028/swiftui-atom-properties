/// Declares that a type can produce a refreshable value that can be accessed from everywhere.
///
/// Atoms compliant with this protocol are refreshable and can wait until the atom produces
/// its final value.
public protocol AsyncAtom<Produced>: Atom {
    /// A producer that produces the refreshable value of this atom.
    var refreshProducer: AtomRefreshProducer<Produced, Coordinator> { get }
}
