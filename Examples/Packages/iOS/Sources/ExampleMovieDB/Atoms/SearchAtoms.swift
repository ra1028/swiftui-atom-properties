import Atoms
import Combine

struct SearchQueryAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> String {
        ""
    }
}

struct SearchMoviesAtom: PublisherAtom, Hashable {
    func publisher(context: Context) -> AnyPublisher<[Movie], Error> {
        let api = context.watch(APIClientAtom())
        let query = context.watch(SearchQueryAtom())

        if query.isEmpty {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return api.getSearchMovies(query: query)
            .map(\.results)
            .eraseToAnyPublisher()
    }
}
