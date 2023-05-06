import AVFoundation
import Atoms
import Combine
import Foundation

struct ValueGenerator {
    var date: () -> Date
    var uuid: () -> UUID
    var temporaryDirectory: () -> String
}

struct ValueGeneratorAtom: ValueAtom, Hashable {
    func value(context: Context) -> ValueGenerator {
        ValueGenerator(
            date: Date.init,
            uuid: UUID.init,
            temporaryDirectory: NSTemporaryDirectory
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
        .eraseToAnyPublisher()
    }
}
