import SwiftUI
import XCTest

struct ViewTest<Content: View>: _ViewTest {
    let rootView: () -> Content

    func initRootView() -> some View {
        rootView()
    }

    func initSize() -> CGSize {
        UIScreen.main.bounds.size
    }

    func perform(_ body: () -> Void) {
        setUpTest()
        body()
        tearDownTest()
    }
}
