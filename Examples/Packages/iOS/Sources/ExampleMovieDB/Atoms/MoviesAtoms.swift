import Atoms
import Foundation

struct FirstPageAtom: ThrowingTaskAtom, Hashable {
    func value(context: Context) async throws -> PagedResponse<Movie> {
        let api = context.watch(APIClientAtom())
        let filter = context.watch(FilterAtom())

        return try await api.getMovies(filter: filter, page: 1)
    }
}

struct NextPagesAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> [PagedResponse<Movie>] {
        // Purges when the first page is updated.
        context.watch(FirstPageAtom())
        return []
    }
}

struct LoadNextAtom: ValueAtom, Hashable {
    @MainActor
    struct Action {
        let context: AtomContext

        func callAsFunction() async {
            let api = context.read(APIClientAtom())
            let filter = context.read(FilterAtom())
            let currentPage = context.read(NextPagesAtom()).last?.page ?? 1
            let nextPage = try? await api.getMovies(filter: filter, page: currentPage + 1)

            if let nextPage = nextPage {
                context[NextPagesAtom()].append(nextPage)
            }
        }
    }

    func value(context: Context) -> Action {
        Action(context: context)
    }
}

struct FilterAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> Filter {
        .nowPlaying
    }
}

struct MyListAtom: StateAtom, Hashable, KeepAlive {
    func defaultValue(context: Context) -> [Movie] {
        []
    }
}

struct MyListInsertAtom: ValueAtom, Hashable {
    @MainActor
    struct Action {
        let context: AtomContext

        func callAsFunction(movie: Movie) {
            let myList = MyListAtom()

            if let index = context[myList].firstIndex(of: movie) {
                context[myList].remove(at: index)
            }
            else {
                context[myList].append(movie)
            }
        }
    }

    func value(context: Context) -> Action {
        Action(context: context)
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
