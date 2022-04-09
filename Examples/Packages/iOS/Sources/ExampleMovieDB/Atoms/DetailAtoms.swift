import Atoms

struct IsInMyListAtom: ValueAtom, Hashable {
    let movie: Movie

    func value(context: Context) -> Bool {
        let myList = context.watch(MyListAtom())
        return myList.contains(movie)
    }
}

struct CastsAtom: ThrowingTaskAtom, Hashable {
    let movieID: Int

    func value(context: Context) async throws -> [Credits.Person] {
        let api = context.watch(APIClientAtom())
        return try await api.getCredits(movieID: movieID).cast
    }
}
