import Atoms
import ExampleCounter
import ExampleMap
import ExampleMovieDB
import ExampleTimeTravel
import ExampleTodo
import ExampleVoiceMemo
import SwiftUI

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
public struct iOSApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            AtomRoot {
                NavigationView {
                    List {
                        NavigationLink("🔢 Counter") {
                            ExampleCounter()
                        }

                        NavigationLink("📋 Todo") {
                            ExampleTodo()
                        }

                        NavigationLink("🎞 The Movie Database") {
                            ExampleMovieDB()
                        }

                        NavigationLink("🗺 Map") {
                            ExampleMap()
                        }

                        NavigationLink("🎙️ Voice Memo") {
                            ExampleVoiceMemo()
                        }

                        NavigationLink("⏳ Time Travel") {
                            ExampleTimeTravel()
                        }
                    }
                    .navigationTitle("Examples")
                    .listStyle(.insetGrouped)
                }
                .navigationViewStyle(.stack)
            }
            .observe { snapshot in
                print(snapshot)
            }
        }
    }
}
