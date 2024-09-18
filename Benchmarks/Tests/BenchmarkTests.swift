import Atoms
import XCTest

final class RenderingPerformanceTests: XCTestCase {
    func testPerformance() {
        let test = ViewTest {
            AtomRoot {
                TestView()
            }
        }

        test.perform {
            measure {
                for y in stride(from: 100, through: 500, by: 100) {
                    for shift in stride(from: 20, through: 100, by: 20) {
                        for _ in 0..<10 {
                            test.sendTouchSequence([
                                (location: CGPoint(x: 0, y: y + shift), globalLocation: nil, timestamp: Date())
                            ])
                            test.turnRunloop(times: 1)
                        }
                    }
                }
            }
        }
    }
}
