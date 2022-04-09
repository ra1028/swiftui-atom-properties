@propertyWrapper
struct Failable<T: Decodable>: Decodable {
    var wrappedValue: T?

    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let wrappedValue = try? container.decode(T.self)
        self.init(wrappedValue: wrappedValue)
    }
}

extension Failable: Encodable where T: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension Failable: Equatable where T: Equatable {}
extension Failable: Hashable where T: Hashable {}
