import Atoms
import SwiftUI

struct Test0Atom: StateAtom, Hashable {
    func defaultValue(context: Context) -> Int {
        0
    }
}

struct Test1Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test0Atom())
    }
}

struct Test2Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test1Atom())
    }
}

struct Test3Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test2Atom())
    }
}

struct Test4Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test3Atom())
    }
}

struct Test5Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test4Atom())
    }
}

struct Test6Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test5Atom())
    }
}

struct Test7Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test6Atom())
    }
}

struct Test8Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test7Atom())
    }
}

struct Test9Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test8Atom())
    }
}

struct Test10Atom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(Test9Atom())
    }
}

struct TestRowAtom: ValueAtom, Hashable {
    let key: Int

    func value(context: Context) -> Int {
        context.watch(Test10Atom())
    }
}

struct TestRow: View {
    @Watch<TestRowAtom>
    var value: Int

    init(key: Int) {
        _value = Watch(TestRowAtom(key: key))
    }

    var body: some View {
        Text(value.description)
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .background(.yellow)
    }
}

struct TestView: View {
    @WatchState(Test0Atom())
    var value

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    ForEach(0..<200) { i in
                        TestRow(key: i)
                    }
                }
            }

            Button {
                value += 1
            } label: {
                Text("Increment")
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(.red)
            }
        }
    }
}
