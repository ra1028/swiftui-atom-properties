import Atoms
import Foundation

@MainActor
final class MovieLoader: ObservableObject {
    @Published
    private(set) var pages = AsyncPhase<[PagedResponse<Movie>], Error>.suspending
    private let api: APIClientProtocol
    let filter: Filter

    init(api: APIClientProtocol, filter: Filter) {
        self.api = api
        self.filter = filter
    }

    func refresh() async {
        pages = await AsyncPhase {
            try await [api.getMovies(filter: filter, page: 1)]
        }
    }

    func loadNext() async {
        guard let currentPages = pages.value, let lastPage = currentPages.last?.page else {
            return
        }

        let nextPage = try? await api.getMovies(filter: filter, page: lastPage + 1)

        guard let nextPage = nextPage else {
            return
        }

        pages = .success(currentPages + [nextPage])
    }
}

@MainActor
final class MyList: ObservableObject {
    @Published
    private(set) var movies = [Movie]()

    func insert(movie: Movie) {
        if let index = movies.firstIndex(of: movie) {
            movies.remove(at: index)
        }
        else {
            movies.append(movie)
        }
    }
}

struct MovieLoaderAtom: ObservableObjectAtom, Hashable {
    func object(context: Context) -> MovieLoader {
        let api = context.watch(APIClientAtom())
        let filter = context.watch(FilterAtom())
        return MovieLoader(api: api, filter: filter)
    }
}

struct MyListAtom: ObservableObjectAtom, Hashable, KeepAlive {
    func object(context: Context) -> MyList {
        MyList()
    }
}

struct FilterAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> Filter {
        .nowPlaying
    }
}

private extension APIClientProtocol {
    func getMovies(filter: Filter, page: Int) async throws -> PagedResponse<Movie> {
        switch filter {
        case .nowPlaying:
            return try await getNowPlaying(page: page)

        case .popular:
            return try await getPopular(page: page)

        case .topRated:
            return try await getTopRated(page: page)

        case .upcoming:
            return try await getUpcoming(page: page)
        }
    }
}
