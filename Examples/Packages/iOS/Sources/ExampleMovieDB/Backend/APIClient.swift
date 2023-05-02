import Combine
import UIKit

protocol APIClientProtocol {
    func getImage(path: String, size: ImageSize) async throws -> UIImage
    func getNowPlaying(page: Int) async throws -> PagedResponse<Movie>
    func getPopular(page: Int) async throws -> PagedResponse<Movie>
    func getTopRated(page: Int) async throws -> PagedResponse<Movie>
    func getUpcoming(page: Int) async throws -> PagedResponse<Movie>
    func getCredits(movieID: Int) async throws -> Credits
    func getSearchMovies(query: String) -> Future<PagedResponse<Movie>, Error>  // Use Publisher as an example.
}

struct APIClient: APIClientProtocol {
    private let session: URLSession = URLSession(configuration: .ephemeral)
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!
    private let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!
    private let apiKey = "3de15b0402484d3d089399ea0b8d98f1"
    private let jsonDecoder: JSONDecoder = {
        let dateFormatter = DateFormatter()
        let decoder = JSONDecoder()
        dateFormatter.dateFormat = "yyy-MM-dd"
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()

    func getImage(path: String, size: ImageSize) async throws -> UIImage {
        let url =
            imageBaseURL
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent(path)
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)
        let (data, _) = try await session.data(for: request)
        return UIImage(data: data) ?? UIImage()
    }

    func getNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        try await get(path: "movie/now_playing", parameters: ["page": String(page)])
    }

    func getPopular(page: Int) async throws -> PagedResponse<Movie> {
        try await get(path: "movie/popular", parameters: ["page": String(page)])
    }

    func getTopRated(page: Int) async throws -> PagedResponse<Movie> {
        try await get(path: "movie/top_rated", parameters: ["page": String(page)])
    }

    func getUpcoming(page: Int) async throws -> PagedResponse<Movie> {
        try await get(path: "movie/upcoming", parameters: ["page": String(page)])
    }

    func getCredits(movieID: Int) async throws -> Credits {
        try await get(path: "movie/\(movieID)/credits", parameters: [:])
    }

    func getSearchMovies(query: String) async throws -> PagedResponse<Movie> {
        try await get(path: "search/movie", parameters: ["query": query])
    }

    func getSearchMovies(query: String) -> Future<PagedResponse<Movie>, Error> {
        Future { fulfill in
            Task {
                do {
                    let response = try await get(
                        PagedResponse<Movie>.self,
                        path: "search/movie",
                        parameters: ["query": query]
                    )
                    fulfill(.success(response))
                }
                catch {
                    fulfill(.failure(error))
                }
            }
        }
    }
}

private extension APIClient {
    func get<Response: Decodable>(
        _ type: Response.Type = Response.self,
        path: String,
        parameters: [String: String]
    ) async throws -> Response {
        let url = baseURL.appendingPathComponent(path)
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]

        for (name, value) in parameters {
            queryItems.append(URLQueryItem(name: name, value: value))
        }

        urlComponents.queryItems = queryItems

        var urlRequest = URLRequest(url: urlComponents.url!, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 10)
        urlRequest.httpMethod = "GET"

        do {
            let start = Date()
            let (data, _) = try await session.data(for: urlRequest)
            let end = Date()
            let leeway = max(0.5 - start.distance(to: end), 0)
            try await Task.sleep(nanoseconds: UInt64(leeway * 1000_000_000))
            return try jsonDecoder.decode(Response.self, from: data)
        }
        catch {
            print(error)
            throw error
        }
    }
}

final class MockAPIClient: APIClientProtocol {
    var imageResponse = Result<UIImage, Error>.failure(URLError(.unknown))
    var filteredMovieResponse = Result<PagedResponse<Movie>, Error>.failure(URLError(.unknown))
    var creditsResponse = Result<Credits, Error>.failure(URLError(.unknown))
    var searchMoviesResponse = Result<PagedResponse<Movie>, Error>.failure(URLError(.unknown))

    func getImage(path: String, size: ImageSize) async throws -> UIImage {
        try imageResponse.get()
    }

    func getNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        try filteredMovieResponse.get()
    }

    func getPopular(page: Int) async throws -> PagedResponse<Movie> {
        try filteredMovieResponse.get()
    }

    func getTopRated(page: Int) async throws -> PagedResponse<Movie> {
        try filteredMovieResponse.get()
    }

    func getUpcoming(page: Int) async throws -> PagedResponse<Movie> {
        try filteredMovieResponse.get()
    }

    func getCredits(movieID: Int) async throws -> Credits {
        try creditsResponse.get()
    }

    func getSearchMovies(query: String) -> Future<PagedResponse<Movie>, Error> {
        Future { fulfill in
            fulfill(self.searchMoviesResponse)
        }
    }
}
