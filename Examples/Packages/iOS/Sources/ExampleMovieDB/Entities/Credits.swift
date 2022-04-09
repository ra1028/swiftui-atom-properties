struct Credits: Codable, Hashable, Identifiable {
    struct Person: Codable, Hashable, Identifiable {
        let id: Int
        let name: String
        let profilePath: String?
    }

    let id: Int
    let cast: [Person]
}
