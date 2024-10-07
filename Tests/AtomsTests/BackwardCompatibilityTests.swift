#if !compiler(>=6) && !hasFeature(StrictConcurrency)
    import XCTest
    import SwiftUI

    @testable import Atoms

    final class BackwardCompatibilityTests: XCTestCase {
        func testAtomRootNotIsolatedToMainActor() {
            func nonisolatedContext() {
                _ = AtomRoot {}
            }

            nonisolatedContext()
        }

        func testAtomScopeNotIsolatedToMainActor() {
            func nonisolatedContext() {
                _ = AtomScope {}
            }

            nonisolatedContext()
        }

        func testViewsIndirectlyDependOnViewContextNotIsolatedToMainActor() {
            struct TestView: View {
                @Watch(TestAtom(value: 0))
                var value
                @ViewContext
                var context

                var body: some View {
                    EmptyView()
                }
            }

            func nonisolatedContext() {
                _ = TestView()
            }

            nonisolatedContext()
        }
    }
#endif
