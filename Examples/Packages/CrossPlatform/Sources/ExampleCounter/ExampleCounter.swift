import Atoms
import SwiftUI

struct CounterAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> Int {
        0
    }
}

struct CounterScreen: View {
    @Watch(CounterAtom())
    var count

    var body: some View {
        VStack {
            Text("Count: \(count)").font(.largeTitle)
            CountStepper()
        }
        .fixedSize()
        .navigationTitle("Counter")
    }
}

struct CountStepper: View {
    @WatchState(CounterAtom())
    var count

    var body: some View {
        #if os(tvOS) || os(watchOS)
            HStack {
                Button("-") { count -= 1 }
                Button("+") { count += 1 }
            }
        #else
            Stepper(value: $count) {}
                .labelsHidden()
        #endif
    }
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
public struct ExampleCounter: View {
    public init() {}

    public var body: some View {
        CounterScreen()
    }
}

struct CounterScreen_Preview: PreviewProvider {
    static var previews: some View {
        AtomRoot {
            CounterScreen()
        }
    }
}
