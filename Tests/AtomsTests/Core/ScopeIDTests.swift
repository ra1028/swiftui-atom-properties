import Testing

@testable import Atoms

struct ScopeIDTests {
    @Test
    func testHashable() {
        let id0 = ScopeID(0)
        let id1 = id0
        let id2 = ScopeID(1)

        #expect(id0 == id1)
        #expect(id1 != id2)
        #expect(id0.hashValue == id1.hashValue)
        #expect(id1.hashValue != id2.hashValue)
    }
}
