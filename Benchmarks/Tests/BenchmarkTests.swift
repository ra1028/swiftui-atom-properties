import Atoms
import XCTest

final class RenderingPerformanceTests: XCTestCase {
    func testPerformance() {
        let test = ViewTest {
            AtomRoot {
                TestView()
            }
        }

        let size = test.initSize()

        test.perform {
            measure {
                for _ in 0..<100 {
                    test.sendTouchSequence(
                        Array(
                            repeating: (location: CGPoint(x: size.width / 2, y: size.height - 30), globalLocation: nil, timestamp: Date()),
                            count: 2
                        )
                    )
                    test.turnRunloop(times: 1)
                }
            }
        }
    }
}
