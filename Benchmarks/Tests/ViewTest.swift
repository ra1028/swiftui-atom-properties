import SwiftUI

struct ViewTest<Content: View>: _ViewTest {
    let rootView: @MainActor () -> Content

    func initRootView() -> some View {
        MainActor.assumeIsolated {
            rootView()
        }
    }

    func initSize() -> CGSize {
        MainActor.assumeIsolated {
            UIScreen.main.bounds.size
        }
    }

    func perform(_ body: () -> Void) {
        setUpTest()
        body()
        tearDownTest()
    }
}
