import Atoms
import SwiftUI

struct DetailScreen: View {
    let movie: Movie

    @Watch(MyListInsertAtom())
    var myListInsert

    @ViewContext
    var context

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.calendar)
    var calendar

    var dateComponents: DateComponents? {
        movie.releaseDate.map { calendar.dateComponents([.year], from: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                coverImage
                title

                Group {
                    GroupBox("Cast") {
                        CastList(movieID: movie.id)
                    }

                    GroupBox("Overview") {
                        MovieRow(movie: movie, truncatesOverview: false)
                    }
                }
                .padding([.bottom, .horizontal])
            }
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .topLeading) {
            closeButton
        }
    }

    var coverImage: some View {
        Color(.systemGroupedBackground)
            .aspectRatio(
                CGSize(width: 1, height: 0.6),
                contentMode: .fit
            )
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay {
                if let path = movie.backdropPath {
                    NetworkImage(path: path, size: .original)
                }
            }
    }

    var title: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.title3.bold())
                    .foregroundColor(.primary)

                if let year = dateComponents?.year {
                    Text(verbatim: "(\(year))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            myListButton
        }
        .padding()
    }

    @ViewBuilder
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color(.systemGray))
        }
        .padding()
        .shadow(radius: 2)
    }

    @ViewBuilder
    var myListButton: some View {
        let isOn = context.watch(IsInMyListAtom(movie: movie))

        Button {
            myListInsert(movie: movie)
        } label: {
            MyListButtonLabel(isOn: isOn)
        }
    }
}

struct DetailScreen_Preview: PreviewProvider {
    static let movie = Movie(
        id: 680,
        title: "Pulp Fiction",
        overview: """
            A burger-loving hit man, his philosophical partner, a drug-addled gangster\'s moll and a washed-up boxer converge in this sprawling, comedic crime caper. Their adventures unfurl in three stories that ingeniously trip back and forth in time.
            """,
        posterPath: "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg",
        backdropPath: "/suaEOtk1N1sgg2MTM7oZd2cfVp3.jpg",
        voteAverage: 8.5,
        releaseDate: Date(timeIntervalSinceReferenceDate: -199184400.0)
    )

    static var previews: some View {
        AtomRoot {
            DetailScreen(movie: movie)
        }
    }
}
