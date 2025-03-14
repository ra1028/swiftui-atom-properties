import Atoms
import SwiftUI

struct InputState: Equatable {
    var text: String = ""
    var latestInput: Int?

    mutating func input(number: Int) {
        text += String(number)
        latestInput = number
    }

    mutating func clear() {
        text = ""
        latestInput = nil
    }
}

struct InputStateAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> InputState {
        InputState()
    }
}

struct NumberInputScreen: View {
    let matrix = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
    ]

    @WatchState(InputStateAtom())
    var inputState

    var body: some View {
        VStack {
            TextField("Tap numbers", text: .constant(inputState.text))
                .disabled(true)
                .textFieldStyle(.roundedBorder)
                .padding()

            ForEach(matrix, id: \.first) { row in
                HStack {
                    ForEach(row, id: \.self) { number in
                        Button {
                            inputState.input(number: number)
                        } label: {
                            Text("\(number)")
                                .font(.largeTitle)
                                .frame(width: 80, height: 80)
                                .background(Color(inputState.latestInput == number ? .systemOrange : .secondarySystemBackground))
                                .clipShape(Circle())
                        }
                    }
                }
            }

            Button("Clear") {
                inputState.clear()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding()
        .navigationTitle("Time Travel")
    }
}

struct TimeTravelDebug<Content: View>: View {
    @ViewBuilder
    let content: () -> Content

    @State
    var snapshots = [Snapshot]()

    @State
    var position = 0

    @ViewContext
    var context

    var body: some View {
        AtomScope {
            ZStack(alignment: .bottom) {
                content()
                slider
            }
            .padding()
        }
        .scopedObserve { snapshot in
            Task {
                snapshots = Array(snapshots.prefix(position + 1))
                snapshots.append(snapshot)
                position = snapshots.endIndex - 1
            }
        }
    }

    var slider: some View {
        VStack(alignment: .leading) {
            Text("History (\(position + 1) / \(snapshots.count))")

            Slider(
                value: Binding(
                    get: { Double(position) },
                    set: { value in
                        Task { @MainActor in
                            position = Int(value)
                            context.restore(snapshots[position])
                        }
                    }
                ),
                in: 0...Double(max(0, snapshots.endIndex - 1))
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 5)
    }
}

// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
public struct ExampleTimeTravel: View {
    public init() {}

    public var body: some View {
        TimeTravelDebug {
            NumberInputScreen()
        }
    }
}

#Preview {
    AtomRoot {
        TimeTravelDebug {
            NumberInputScreen()
        }
    }
}
