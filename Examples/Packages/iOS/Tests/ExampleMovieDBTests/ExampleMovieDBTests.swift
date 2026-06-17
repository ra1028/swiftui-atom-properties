import Atoms
import Testing
import UIKit

@testable import ExampleMovieDB

struct ExampleMovieDBTests {
    @MainActor
    @Test
    func testImageAtom() async {
        let apiClient = MockAPIClient()
        let atom = ImageAtom(path: "", size: .original)
        let context = AtomTestContext()

        context.override(APIClientAtom()) { _ in apiClient }

        let image = UIImage()
        apiClient.imageResponse = .success(image)

        let successPhase = await AsyncPhase(context.watch(atom).result)

        #expect(successPhase.value == image)

        context.reset(atom)

        let error = URLError(.badURL)
        apiClient.imageResponse = .failure(error)

        let failurePhase = await AsyncPhase(context.watch(atom).result)

        #expect(failurePhase.error as? URLError == error)
    }

    @MainActor
    @Test
    func testMovieLoader() async {
        let apiClient = MockAPIClient()
        let atom = MovieLoaderAtom()
        let context = AtomTestContext()

        context.override(APIClientAtom()) { _ in apiClient }

        for filter in Filter.allCases {
            context[FilterAtom()] = filter

            let expected = PagedResponse.stub()
            let error = URLError(.badURL)

            apiClient.filteredMovieResponse = .success(expected)

            await context.watch(atom).refresh()

            #expect(context.watch(atom).pages.value == [expected])

            await context.watch(atom).loadNext()

            #expect(context.watch(atom).pages.value == [expected, expected])

            context.reset(atom)
            apiClient.filteredMovieResponse = .failure(error)

            await context.watch(atom).refresh()

            #expect(context.watch(atom).pages.error as? URLError == error)
        }
    }

    @MainActor
    @Test
    func testMyListAtom() {
        let atom = MyListAtom()
        let context = AtomTestContext()

        #expect(context.watch(atom).movies == [])

        context.watch(atom).insert(movie: .stub(id: 0))

        #expect(context.watch(atom).movies == [.stub(id: 0)])

        context.watch(atom).insert(movie: .stub(id: 1))

        #expect(context.watch(atom).movies == [.stub(id: 0), .stub(id: 1)])

        context.watch(atom).insert(movie: .stub(id: 0))

        #expect(context.watch(atom).movies == [.stub(id: 1)])
    }

    @MainActor
    @Test
    func testIsInMyListAtom() {
        let context = AtomTestContext()

        context.watch(MyListAtom()).insert(movie: .stub(id: 0))

        #expect(context.watch(IsInMyListAtom(movie: .stub(id: 0))))
        #expect(!context.watch(IsInMyListAtom(movie: .stub(id: 1))))
    }

    @MainActor
    @Test
    func testCastsAtom() async {
        let apiClient = MockAPIClient()
        let atom = CastsAtom(movieID: 0)
        let context = AtomTestContext()
        let expected = [Credits.Person(id: 0, name: "test0", profilePath: nil)]
        let credits = Credits(id: 0, cast: expected)
        let error = URLError(.badURL)

        context.override(APIClientAtom()) { _ in apiClient }

        apiClient.creditsResponse = .success(credits)

        let successPhase = await AsyncPhase(context.watch(atom).result)

        #expect(successPhase.value == expected)

        apiClient.creditsResponse = .failure(error)
        context.reset(atom)

        let failurePhase = await AsyncPhase(context.watch(atom).result)

        #expect(failurePhase.error as? URLError == error)
    }

    @MainActor
    @Test
    func testSearchMoviesAtom() async {
        let apiClient = MockAPIClient()
        let atom = SearchMoviesAtom()
        let context = AtomTestContext()
        let expected = PagedResponse.stub()
        let expectedError = URLError(.badURL)

        context.override(APIClientAtom()) { _ in apiClient }
        apiClient.searchMoviesResponse = .success(expected)

        context.watch(SearchQueryAtom())

        let empty = await context.refresh(atom)

        #expect(empty.value == [])

        context[SearchQueryAtom()] = "query"

        let success = await context.refresh(atom)

        #expect(success.value == expected.results)

        apiClient.searchMoviesResponse = .failure(expectedError)

        let failure = await context.refresh(atom)

        #expect(failure.error as? URLError == expectedError)
    }
}

private extension PagedResponse where T == Movie {
    static func stub() -> Self {
        PagedResponse(
            page: 0,
            totalPages: 100,
            results: [.stub()]
        )
    }
}

private extension Movie {
    static func stub(id: Int = 0) -> Self {
        Movie(
            id: id,
            title: "title",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0.2,
            releaseDate: Date(timeIntervalSince1970: 0)
        )
    }
}
