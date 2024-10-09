import Atoms
import Combine

struct SearchQueryAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> String {
        ""
    }
}

struct SearchMoviesAtom: AsyncPhaseAtom, Hashable {
    func value(context: Context) async throws -> [Movie] {
        let api = context.watch(APIClientAtom())
        let query = context.watch(SearchQueryAtom())

        guard !query.isEmpty else {
            return []
        }

        return try await api.getSearchMovies(query: query).results
    }
}
