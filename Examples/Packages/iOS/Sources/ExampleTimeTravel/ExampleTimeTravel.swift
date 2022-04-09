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
                        Button("\(number)") {
                            inputState.input(number: number)
                        }
                        .font(.largeTitle)
                        .frame(width: 80, height: 80)
                        .background(Color(inputState.latestInput == number ? .systemOrange : .secondarySystemBackground))
                        .clipShape(Circle())
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

struct TimeTravelDebug<Content: View>: View, AtomObserver {
    @ViewBuilder
    let content: () -> Content

    @State
    var history = [AtomHistory]()

    @State
    var position = 0

    @State
    var isTimeTravelMode = false

    var body: some View {
        AtomRelay {
            ZStack(alignment: .bottom) {
                content().disabled(isTimeTravelMode)

                if isTimeTravelMode {
                    slider
                }
                else {
                    startButton
                }
            }
            .padding()
        }
        .observe(self)  // Observes atom changes by this view itself.
    }

    var slider: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("History (\(position + 1) / \(history.count))")
                Spacer()
                doneButton
            }

            Slider(
                value: Binding(
                    get: { Double(position) },
                    set: {
                        position = Int($0)

                        // Restores the snapshot in the history.
                        history[position].restore()
                    }
                ),
                in: 0...Double(max(0, history.endIndex - 1))
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 5)
    }

    var startButton: some View {
        Button("Go to Time Travel ⏳") {
            position = history.count - 1
            isTimeTravelMode = true
        }
        .buttonStyle(.borderedProminent)
    }

    var doneButton: some View {
        Button("Done") {
            // Erases the frame of history that never was.
            history = Array(history.prefix(through: position))
            isTimeTravelMode = false
        }
        .buttonStyle(.borderedProminent)
    }

    /// Method of `AtomObserver`, for receiving atom changes.
    func atomChanged<Node: Atom>(snapshot: Snapshot<Node>) {
        // Collects the snapshots only while `isTimeTravelMode` is off, because
        // the store emits change events even by `snapshot.restore()`.
        guard !isTimeTravelMode else {
            return
        }

        // Updates `history` asynchronously to prevent "attempting to update during view update" issue.
        Task {
            history.append(snapshot)
        }
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

struct TimeTravelScreen_Preview: PreviewProvider {
    static var previews: some View {
        AtomRoot {
            TimeTravelDebug {
                NumberInputScreen()
            }
        }
    }
}
