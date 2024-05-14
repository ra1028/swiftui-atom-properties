import Atoms
import ExampleCounter
import ExampleTodo
import SwiftUI

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
public struct CrossPlatformRoot: View {
    public init() {}

    public var body: some View {
        AtomRoot {
            NavigationStack {
                List {
                    NavigationLink("🔢 Counter") {
                        ExampleCounter()
                    }

                    NavigationLink("📋 Todo") {
                        ExampleTodo()
                    }
                }
                .navigationTitle("Examples")

                #if os(iOS)
                    .listStyle(.insetGrouped)
                #endif
            }
        }
    }
}
