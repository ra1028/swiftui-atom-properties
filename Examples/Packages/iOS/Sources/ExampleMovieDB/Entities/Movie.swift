import Foundation

struct Movie: Codable, Hashable, Identifiable {
    var id: Int
    var title: String
    var overview: String?
    var posterPath: String?
    var backdropPath: String?
    var voteAverage: Float
    @Failable
    var releaseDate: Date?
}
