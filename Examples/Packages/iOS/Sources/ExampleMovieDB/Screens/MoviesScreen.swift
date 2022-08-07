import Atoms
import SwiftUI

struct MoviesScreen: View {
    @WatchStateObject(MoviePagesAtom())
    var pages

    @WatchState(SearchQueryAtom())
    var searchQuery

    @ViewContext
    var context

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

                switch pages.moviePages {
                    case .success(let movies):
                        ForEach(movies, id: \.page) { response in
                            pageIndex(current: response.page, total: response.totalPages)

                            ForEach(response.results, id: \.id) { movie in
                                movieRow(movie)
                            }
                        }

                        if let last = movies.last, last.hasNextPage {
                            ProgressRow().task {
                                await pages.loadNext()
                            }
                        }

                    case .failure:
                        CaveatRow(text: "Failed to get the data.")

                    case .suspending:
                        ProgressRow()
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
        .onSubmit(of: .search) { [$isShowingSearchScreen] in
            $isShowingSearchScreen.wrappedValue = true
        }
        .task(id: pages.filter) {
            await pages.refresh()
        }
        .refreshable { [pages] in
            await pages.refresh()
        }
        .background {
            NavigationLink(
                isActive: $isShowingSearchScreen,
                destination: SearchScreen.init,
                label: EmptyView.init
            )
        }
        .sheet(item: $selectedMovie) { movie in
            DetailScreen(movie: movie)
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

struct MoviesScreen_Preview: PreviewProvider {
    static var previews: some View {
        AtomRoot {
            NavigationView {
                MoviesScreen()
            }
        }
    }
}
