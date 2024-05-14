struct PagedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let totalPages: Int
    let results: [T]

    var hasNextPage: Bool {
        page < totalPages
    }
}

extension PagedResponse: Equatable where T: Equatable {}
