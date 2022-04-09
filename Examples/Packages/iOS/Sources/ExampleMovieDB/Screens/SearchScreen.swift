import Atoms
import SwiftUI

struct SearchScreen: View {
    @Watch(SearchMoviesAtom())
    var movies

    @ViewContext
    var context

    @State
    var selectedMovie: Movie?

    var body: some View {
        List {
            switch movies {
            case .suspending:
                ProgressRow()

            case .failure:
                CaveatRow(text: "Failed to get the search results.")

            case .success(let movies) where movies.isEmpty:
                CaveatRow(text: "There are no movies that matched your query.")

            case .success(let movies):
                ForEach(movies, id: \.id) { movie in
                    Button {
                        selectedMovie = movie
                    } label: {
                        MovieRow(movie: movie)
                    }
                }
            }
        }
        .navigationTitle("Search Results")
        .listStyle(.insetGrouped)
        .sheet(item: $selectedMovie) { movie in
            DetailScreen(movie: movie)
        }
        .refreshable { [context] in
            await context.refresh(SearchMoviesAtom())
        }
    }
}

struct SearchScreen_Preview: PreviewProvider {
    static var previews: some View {
        AtomRoot {
            NavigationView {
                SearchScreen()
            }
        }
        .override(SearchQueryAtom()) { _ in
            "Léon"
        }
    }
}
