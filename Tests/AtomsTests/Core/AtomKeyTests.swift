import Testing

@testable import Atoms

struct AtomKeyTests {
    @Test
    func testKeyHashableForSameAtoms() {
        let atom = TestAtom(value: 0)
        let key0 = AtomKey(atom)
        let key1 = AtomKey(atom)

        #expect(key0 == key1)
        #expect(key0.hashValue == key1.hashValue)
    }

    @Test
    func testKeyHashableForDifferentAtoms() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)

        #expect(key0 != key1)
        #expect(key0.hashValue != key1.hashValue)
    }

    @Test
    func testDictionaryKey() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let key2 = AtomKey(atom1)
        var dictionary = [AtomKey: Int]()

        dictionary[key0] = 100
        dictionary[key1] = 200
        dictionary[key2] = 300

        #expect(dictionary[key0] == 100)
        #expect(dictionary[key1] == 300)
        #expect(dictionary[key2] == 300)
    }

    @MainActor
    @Test
    func testDescription() {
        let atom = TestAtom(value: 0)
        let scopeToken = ScopeKey.Token()
        let key0 = AtomKey(atom)
        let key1 = AtomKey(atom, scopeKey: scopeToken.key)

        #expect(key0.description == "TestAtom<Int>")
        #expect(key1.description == "TestAtom<Int> scope:\(scopeToken.key.description)")
    }
}
