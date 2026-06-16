import Testing

@testable import Atoms

struct ScopeKeyTests {
    @MainActor
    @Test
    func testDescription() {
        let token = ScopeKey.Token()
        let objectAddress = String(UInt(bitPattern: ObjectIdentifier(token)), radix: 16)

        #expect(token.key.description == "0x\(objectAddress)")
    }
}
