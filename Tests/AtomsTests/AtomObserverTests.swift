import XCTest

@testable import Atoms

@MainActor
final class AtomObserverTests: XCTestCase {
    struct TestEmptyObserver: AtomObserver {}

    func testEmpty() {
        let observer = TestEmptyObserver()
        let atom = TestValueAtom(value: 0)
        let snapshot = Snapshot(atom: atom, value: 0, store: DefaultStore())

        observer.atomAssigned(atom: atom)
        observer.atomUnassigned(atom: atom)
        observer.atomChanged(snapshot: snapshot)
    }
}
