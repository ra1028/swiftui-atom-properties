import AVFoundation
import Atoms
import Combine
import Foundation

struct ValueGenerator: Sendable {
    var date: @Sendable () -> Date
    var uuid: @Sendable () -> UUID
    var temporaryDirectory: @Sendable () -> String
}

struct ValueGeneratorAtom: ValueAtom, Hashable {
    func value(context: Context) -> ValueGenerator {
        ValueGenerator(
            date: { Date.now },
            uuid: { UUID() },
            temporaryDirectory: { NSTemporaryDirectory() }
        )
    }
}

struct TimerAtom: ValueAtom, Hashable {
    var startDate: Date
    var timeInterval: TimeInterval

    func value(context: Context) -> AnyPublisher<TimeInterval, Never> {
        Timer.publish(
            every: timeInterval,
            tolerance: 0,
            on: .main,
            in: .common
        )
        .autoconnect()
        .map { $0.timeIntervalSince(startDate) }
        .prepend(.zero)
        .eraseToAnyPublisher()
    }
}
