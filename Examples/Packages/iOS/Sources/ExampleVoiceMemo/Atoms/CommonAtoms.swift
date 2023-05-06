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
