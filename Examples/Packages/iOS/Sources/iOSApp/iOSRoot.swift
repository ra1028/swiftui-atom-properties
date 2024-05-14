import Atoms
import ExampleCounter
import ExampleMap
import ExampleMovieDB
import ExampleTimeTravel
import ExampleTodo
import ExampleVoiceMemo
import SwiftUI

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
public struct iOSRoot: View {
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
        }
        .observe { snapshot in
            print(snapshot.graphDescription())
        }
    }
}
