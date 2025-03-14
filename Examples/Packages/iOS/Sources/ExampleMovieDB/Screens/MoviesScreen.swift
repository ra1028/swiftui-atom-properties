import Atoms
import SwiftUI

struct MoviesScreen: View {
    @WatchStateObject(MovieLoaderAtom())
    var loader

    @WatchState(SearchQueryAtom())
    var searchQuery

    @State
    var isShowingSearchScreen = false

    @State
    var selectedMovie: Movie?

    var body: some View {
        List {
            Section("My List") {
                MyMovieList { movie in
                    selectedMovie = movie
                }
            }

            Section {
                FilterPicker()

                switch loader.pages {
                case .suspending:
                    ProgressRow().id(loader.filter)

                case .failure:
                    CaveatRow(text: "Failed to get the data.")

                case .success(let pages):
                    ForEach(pages, id: \.page) { response in
                        pageIndex(current: response.page, total: response.totalPages)

                        ForEach(response.results, id: \.id) { movie in
                            movieRow(movie)
                        }
                    }

                    if let last = pages.last, last.hasNextPage {
                        ProgressRow()
                            // NB: Since ProgressView placed in the List will not redisplay its indicator once it's hidden, here adds a random ID so that it's always regenerated.
                            .id(UUID())
                            .task {
                                await loader.loadNext()
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Movies")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(Image(systemName: "film")) + Text("TMDB")
            }
        }
        .searchable(
            text: $searchQuery,
            placement: .navigationBarDrawer(displayMode: .always)
        )
        .onSubmit(of: .search) {
            isShowingSearchScreen = true
        }
        .task(id: loader.filter) {
            await loader.refresh()
        }
        .refreshable {
            await loader.refresh()
        }
        .sheet(item: $selectedMovie) { movie in
            DetailScreen(movie: movie)
        }
        .navigationDestination(isPresented: $isShowingSearchScreen) {
            SearchScreen()
        }
    }

    func movieRow(_ movie: Movie) -> some View {
        Button {
            selectedMovie = movie
        } label: {
            MovieRow(movie: movie)
        }
    }

    func pageIndex(current: Int, total: Int) -> some View {
        Text("Page: \(current) / \(total)")
            .font(.subheadline)
            .foregroundColor(.accentColor)
    }
}

#Preview {
    AtomRoot {
        NavigationStack {
            MoviesScreen()
        }
    }
}
