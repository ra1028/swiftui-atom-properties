import Atoms
import SwiftUI

struct MovieRow: View {
    var movie: Movie
    var truncatesOverview = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                if let path = movie.posterPath {
                    NetworkImage(path: path, size: .medium)
                }
            }
            .frame(width: 100, height: 150)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(8)

            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    PopularityBadge(voteAverage: movie.voteAverage)

                    VStack(alignment: .leading) {
                        Text(movie.title)
                            .font(.headline.bold())
                            .foregroundColor(.accentColor)
                            .lineLimit(2)

                        if let releaseDate = movie.releaseDate {
                            Text(Self.formatter.string(from: releaseDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                if let overview = movie.overview {
                    Text(overview)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(truncatesOverview ? 4 : nil)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical)
    }
}

private extension MovieRow {
    static private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
