#!/usr/bin/swift

var base = """
import XCTest

@testable import Atoms


"""

base.append(
"""
struct BenchmarkTestAtom1: StateAtom, Hashable {
    func defaultValue(context: Context) -> Int {
        0
    }
}


"""
)

for i in 2...100 {
    base.append(
"""
struct BenchmarkTestAtom\(i): ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom\(i - 1)())
    }
}


"""
    )
}

base.append(
"""
struct BenchmarkTestAtom101: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom50())
    }
}


"""
)

for i in 102...200 {
    base.append(
"""
struct BenchmarkTestAtom\(i): ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom\(i - 1)())
    }
}


"""
    )
}

base.append(
"""
struct BenchmarkTestAtom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        let value1 = context.watch(BenchmarkTestAtom1())
        let value2 = context.watch(BenchmarkTestAtom50())
        let value3 = context.watch(BenchmarkTestAtom150())
        let value4 = context.watch(BenchmarkTestAtom200())
        return value1 + value2 + value3 + value4
    }
}


"""
)

base.append(
"""
final class BenchmarkTests: XCTestCase {
    @MainActor
    func testBenchmark() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let context = AtomTestContext()

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 0)

"""
)

for i in 1...1000 {
    base.append(
"""

            context[BenchmarkTestAtom1()] = \(i)

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), \(i * 4))

"""
    )
}

base.append(
"""
        }
    }
}
"""
)

print(base)
