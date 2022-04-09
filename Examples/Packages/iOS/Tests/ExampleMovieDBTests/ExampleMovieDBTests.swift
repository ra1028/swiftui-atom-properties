import Atoms
import XCTest

@testable import ExampleMovieDB

@MainActor
final class ExampleMovieDBTests: XCTestCase {
    func testImageAtom() async {
        let apiClient = MockAPIClient()
        let atom = ImageAtom(path: "", size: .original)
        let context = AtomTestContext()

        context.override(APIClientAtom()) { _ in apiClient }

        let image = UIImage()
        apiClient.imageResponse = .success(image)

        let successPhase = await AsyncPhase(context.watch(atom).result)

        XCTAssertEqual(successPhase.value, image)

        context.reset(atom)

        let error = URLError(.badURL)
        apiClient.imageResponse = .failure(error)

        let failurePhase = await AsyncPhase(context.watch(atom).result)

        XCTAssertEqual(failurePhase.error as? URLError, error)
    }

    func testFirstPageAtom() async {
        let apiClient = MockAPIClient()
        let atom = FirstPageAtom()
        let context = AtomTestContext()

        context.override(APIClientAtom()) { _ in apiClient }

        for filter in Filter.allCases {
            context[FilterAtom()] = filter

            let expected = PagedResponse.stub()
            let error = URLError(.badURL)

            apiClient.filteredMovieResponse = .success(expected)

            let successPhase = await AsyncPhase(context.watch(atom).result)

            XCTAssertEqual(successPhase.value, expected)

            context.reset(atom)
            apiClient.filteredMovieResponse = .failure(error)

            let failurePhase = await AsyncPhase(context.watch(atom).result)

            XCTAssertEqual(failurePhase.error as? URLError, error)
        }
    }

    func testNextPagesAtom() {
        let atom = NextPagesAtom()
        let context = AtomTestContext()
        let pages = [
            PagedResponse<Movie>(page: 1, totalPages: 100, results: [])
        ]

        XCTAssertEqual(context.watch(atom), [])

        context[atom] = pages

        XCTAssertEqual(context.watch(atom), pages)

        context.reset(FirstPageAtom())

        XCTAssertEqual(context.watch(atom), [])
    }

    func testLoadNextAtom() async {
        let apiClient = MockAPIClient()
        let atom = LoadNextAtom()
        let context = AtomTestContext()

        context.override(APIClientAtom()) { _ in apiClient }

        apiClient.filteredMovieResponse = .success(.stub())

        let loadNext = context.watch(atom)

        XCTAssertEqual(context.watch(NextPagesAtom()), [])

        await loadNext()

        XCTAssertEqual(context.watch(NextPagesAtom()), [.stub()])

        await loadNext()

        XCTAssertEqual(context.watch(NextPagesAtom()), [.stub(), .stub()])
    }

    func testMyListInsertAtom() {
        let atom = MyListInsertAtom()
        let context = AtomTestContext()
        let action = context.watch(atom)

        XCTAssertEqual(context.watch(MyListAtom()), [])

        action(movie: .stub(id: 0))

        XCTAssertEqual(context.watch(MyListAtom()), [.stub(id: 0)])

        action(movie: .stub(id: 1))

        XCTAssertEqual(context.watch(MyListAtom()), [.stub(id: 0), .stub(id: 1)])

        action(movie: .stub(id: 0))

        XCTAssertEqual(context.watch(MyListAtom()), [.stub(id: 1)])
    }

    func testIsInMyListAtom() {
        let context = AtomTestContext()

        XCTAssertFalse(context.watch(IsInMyListAtom(movie: .stub(id: 0))))

        context[MyListAtom()].append(.stub(id: 0))

        XCTAssertTrue(context.watch(IsInMyListAtom(movie: .stub(id: 0))))
        XCTAssertFalse(context.watch(IsInMyListAtom(movie: .stub(id: 1))))
    }

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

        XCTAssertEqual(successPhase.value, expected)

        apiClient.creditsResponse = .failure(error)
        context.reset(atom)

        let failurePhase = await AsyncPhase(context.watch(atom).result)

        XCTAssertEqual(failurePhase.error as? URLError, error)
    }

    func testSearchMoviesAtom() async {
        let apiClient = MockAPIClient()
        let atom = SearchMoviesAtom()
        let context = AtomTestContext()
        let expected = PagedResponse.stub()
        let error = URLError(.badURL)

        context.override(APIClientAtom()) { _ in apiClient }
        apiClient.searchMoviesResponse = .success(expected)

        context.watch(SearchQueryAtom())

        let emptyQueryPhase = await context.refresh(atom)

        XCTAssertEqual(emptyQueryPhase.value, [])

        context[SearchQueryAtom()] = "query"

        let successPhase = await context.refresh(atom)

        XCTAssertEqual(successPhase.value, expected.results)

        apiClient.searchMoviesResponse = .failure(error)

        let failurePhase = await context.refresh(atom)

        XCTAssertEqual(failurePhase.error as? URLError, error)
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
