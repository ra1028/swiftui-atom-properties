import AVFoundation
import Atoms
import Combine
import Foundation

struct Generator {
    var date: () -> Date
    var uuid: () -> UUID
    var temporaryDirectory: () -> String
}

struct GeneratorAtom: ValueAtom, Hashable {
    func value(context: Context) -> Generator {
        Generator(
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
