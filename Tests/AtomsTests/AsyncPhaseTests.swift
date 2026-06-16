import Foundation
import Testing

@testable import Atoms

struct AsyncPhaseTests {
    struct TestError: Error, Equatable {
        let value: Int
    }

    @globalActor
    actor TestActor {
        static let shared = TestActor()
    }

    let phases: [AsyncPhase<Int, TestError>] = [
        .suspending,
        .success(0),
        .failure(TestError(value: 0)),
    ]

    @Test
    func testIsSuspending() {
        let expected = [
            true,
            false,
            false,
        ]

        #expect(phases.map(\.isSuspending) == expected)
    }

    @Test
    func testIsSuccess() {
        let expected = [
            false,
            true,
            false,
        ]

        #expect(phases.map(\.isSuccess) == expected)
    }

    @Test
    func testIsFailure() {
        let expected = [
            false,
            false,
            true,
        ]

        #expect(phases.map(\.isFailure) == expected)
    }

    @Test
    func testValue() {
        let expected = [
            nil,
            0,
            nil,
        ]

        #expect(phases.map(\.value) == expected)
    }

    @Test
    func testError() {
        let expected = [
            nil,
            nil,
            TestError(value: 0),
        ]

        #expect(phases.map(\.error) == expected)
    }

    @Test
    func testInitWithResult() {
        let results: [Result<Int, TestError>] = [
            .success(0),
            .failure(TestError(value: 0)),
        ]

        let expected: [AsyncPhase<Int, TestError>] = [
            .success(0),
            .failure(TestError(value: 0)),
        ]

        #expect(results.map(AsyncPhase.init) == expected)
    }

    @Test
    func testAsyncInit() async {
        let success = await AsyncPhase { 100 }
        let failure = await AsyncPhase { throw URLError(.badURL) }

        #expect(success.value == 100)
        #expect(failure.error as? URLError == URLError(.badURL))
    }

    @MainActor
    @Test
    func testInitBodyInheritsMainActorIsolation() async {
        // body should run on @MainActor when init is called from @MainActor context
        let phase = await AsyncPhase<Void, Never> {
            MainActor.assertIsolated()
        }

        #expect(phase.value != nil)
    }

    @Test
    nonisolated func testInitBodyFromNonisolatedContext() async {
        // body should run nonisolated when init is called from nonisolated context
        let phase = await AsyncPhase<Bool, Never> {
            #expect(#isolation == nil)
            return true
        }

        #expect(phase.value == true)
    }

    @TestActor
    @Test
    func testInitBodyInheritsCustomActorIsolation() async {
        let phase = await AsyncPhase<Void, Never> {
            // assertIsolated() precondition-fails if the current executor is not TestActor's
            TestActor.shared.assertIsolated()
        }

        #expect(phase.value != nil)
    }

    @Test
    func testMap() {
        let phase = AsyncPhase<Int, any Error>.success(0)
            .map(String.init)

        #expect(phase.value == "0")
    }

    @Test
    func testMapError() {
        let phase = AsyncPhase<Int, TestError>.failure(TestError(value: 0))
            .mapError { _ in URLError(.badURL) }

        #expect(phase.error == URLError(.badURL))
    }

    @Test
    func testFlatMapToSuspending() {
        let transformed = phases.map { phase in
            phase.flatMap { _ -> AsyncPhase<Int, _> in
                .suspending
            }
        }

        let expected: [AsyncPhase<Int, TestError>] = [
            .suspending,
            .suspending,
            .failure(TestError(value: 0)),
        ]

        #expect(transformed == expected)
    }

    @Test
    func testFlatMapToSuccess() {
        let transformed = phases.map { phase in
            phase.flatMap { .success(String($0)) }
        }

        let expected: [AsyncPhase<String, TestError>] = [
            .suspending,
            .success("0"),
            .failure(TestError(value: 0)),
        ]

        #expect(transformed == expected)
    }

    @Test
    func testFlatMapToFailure() {
        let transformed = phases.map { phase in
            phase.flatMap { _ -> AsyncPhase<Int, _> in
                .failure(TestError(value: 1))
            }
        }

        let expected: [AsyncPhase<Int, TestError>] = [
            .suspending,
            .failure(TestError(value: 1)),
            .failure(TestError(value: 0)),
        ]

        #expect(transformed == expected)
    }

    @Test
    func testFlatMapErrorToSuspending() {
        let transformed = phases.map { phase in
            phase.flatMapError { _ -> AsyncPhase<_, TestError> in
                .suspending
            }
        }

        let expected: [AsyncPhase<Int, TestError>] = [
            .suspending,
            .success(0),
            .suspending,
        ]

        #expect(transformed == expected)
    }

    @Test
    func testFlatMapErrorToSuccess() {
        let transformed = phases.map { phase in
            phase.flatMapError { _ -> AsyncPhase<_, TestError> in
                .success(1)
            }
        }

        let expected: [AsyncPhase<Int, TestError>] = [
            .suspending,
            .success(0),
            .success(1),
        ]

        #expect(transformed == expected)
    }

    @Test
    func testFlatMapErrorToFailure() {
        let transformed = phases.map { phase in
            phase.flatMapError { _ -> AsyncPhase<_, URLError> in
                .failure(URLError(.badURL))
            }
        }

        let expected: [AsyncPhase<Int, URLError>] = [
            .suspending,
            .success(0),
            .failure(URLError(.badURL)),
        ]

        #expect(transformed == expected)
    }
}
