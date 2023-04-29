import XCTest

@testable import Atoms

final class AsyncPhaseTests: XCTestCase {
    struct TestError: Error, Equatable {
        let value: Int
    }

    let phases: [AsyncPhase<Int, TestError>] = [
        .suspending,
        .success(0),
        .failure(TestError(value: 0)),
    ]

    func testIsSuspending() {
        let expected = [
            true,
            false,
            false,
        ]

        XCTAssertEqual(phases.map(\.isSuspending), expected)
    }

    func testIsSuccess() {
        let expected = [
            false,
            true,
            false,
        ]

        XCTAssertEqual(phases.map(\.isSuccess), expected)
    }

    func testIsFailure() {
        let expected = [
            false,
            false,
            true,
        ]

        XCTAssertEqual(phases.map(\.isFailure), expected)
    }

    func testValue() {
        let expected = [
            nil,
            0,
            nil,
        ]

        XCTAssertEqual(phases.map(\.value), expected)
    }

    func testError() {
        let expected = [
            nil,
            nil,
            TestError(value: 0),
        ]

        XCTAssertEqual(phases.map(\.error), expected)
    }

    func testInitWithResult() {
        let results: [Result<Int, TestError>] = [
            .success(0),
            .failure(TestError(value: 0)),
        ]

        let expected: [AsyncPhase<Int, TestError>] = [
            .success(0),
            .failure(TestError(value: 0)),
        ]

        XCTAssertEqual(results.map(AsyncPhase.init), expected)
    }

    func testAsyncInit() async {
        let success = await AsyncPhase { 100 }
        let failure = await AsyncPhase { throw URLError(.badURL) }

        XCTAssertEqual(success.value, 100)
        XCTAssertEqual(failure.error as? URLError, URLError(.badURL))
    }

    func testMap() {
        let phase = AsyncPhase<Int, Error>.success(0)
            .map(String.init)

        XCTAssertEqual(phase.value, "0")
    }

    func testMapError() {
        let phase = AsyncPhase<Int, TestError>.failure(TestError(value: 0))
            .mapError { _ in URLError(.badURL) }

        XCTAssertEqual(phase.error, URLError(.badURL))
    }

    func testFlatMap() {
        XCTContext.runActivity(named: "To suspending") { _ in
            let transformed = phases.map { phase in
                phase.flatMap { _ -> AsyncPhase<Int, TestError> in
                    .suspending
                }
            }

            let expected: [AsyncPhase<Int, TestError>] = [
                .suspending,
                .suspending,
                .failure(TestError(value: 0)),
            ]

            XCTAssertEqual(transformed, expected)
        }

        XCTContext.runActivity(named: "To success") { _ in
            let transformed = phases.map { phase in
                phase.flatMap { .success(String($0)) }
            }

            let expected: [AsyncPhase<String, TestError>] = [
                .suspending,
                .success("0"),
                .failure(TestError(value: 0)),
            ]

            XCTAssertEqual(transformed, expected)
        }

        XCTContext.runActivity(named: "To failure") { _ in
            let transformed = phases.map { phase in
                phase.flatMap { _ -> AsyncPhase<Int, TestError> in
                    .failure(TestError(value: 1))
                }
            }

            let expected: [AsyncPhase<Int, TestError>] = [
                .suspending,
                .failure(TestError(value: 1)),
                .failure(TestError(value: 0)),
            ]

            XCTAssertEqual(transformed, expected)
        }
    }

    func testFlatMapError() {
        XCTContext.runActivity(named: "To suspending") { _ in
            let transformed = phases.map { phase in
                phase.flatMapError { _ -> AsyncPhase<Int, TestError> in
                    .suspending
                }
            }

            let expected: [AsyncPhase<Int, TestError>] = [
                .suspending,
                .success(0),
                .suspending,
            ]

            XCTAssertEqual(transformed, expected)
        }

        XCTContext.runActivity(named: "To success") { _ in
            let transformed = phases.map { phase in
                phase.flatMapError { _ -> AsyncPhase<Int, TestError> in
                    .success(1)
                }
            }

            let expected: [AsyncPhase<Int, TestError>] = [
                .suspending,
                .success(0),
                .success(1),
            ]

            XCTAssertEqual(transformed, expected)
        }

        XCTContext.runActivity(named: "To failure") { _ in
            let transformed = phases.map { phase in
                phase.flatMapError { _ -> AsyncPhase<Int, URLError> in
                    .failure(URLError(.badURL))
                }
            }

            let expected: [AsyncPhase<Int, URLError>] = [
                .suspending,
                .success(0),
                .failure(URLError(.badURL)),
            ]

            XCTAssertEqual(transformed, expected)
        }
    }
}
