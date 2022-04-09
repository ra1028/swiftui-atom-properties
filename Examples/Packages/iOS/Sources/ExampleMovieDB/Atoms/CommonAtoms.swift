import Atoms
import UIKit

struct APIClientAtom: ValueAtom, Hashable {
    func value(context: Context) -> APIClientProtocol {
        APIClient()
    }
}

struct ImageAtom: ThrowingTaskAtom, Hashable {
    let path: String
    let size: ImageSize

    func value(context: Context) async throws -> UIImage {
        let api = context.watch(APIClientAtom())
        return try await api.getImage(path: path, size: size)
    }
}
