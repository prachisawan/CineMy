import Foundation

struct TMDBListResponse: Decodable {
    let results: [TMDBResult]
}

struct TMDBResult: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let release_date: String?
    let first_air_date: String?
    let vote_average: Double?
    let vote_count: Int?
    let poster_path: String?
    let original_language: String?
    var media_type: String?
    let genre_ids: [Int]?
}

let apiKey = "REDACTED_TMDB_KEY"
let query = "Batman"

var components = URLComponents(string: "https://api.themoviedb.org/3/search/movie")!
components.queryItems = [
    URLQueryItem(name: "api_key", value: apiKey),
    URLQueryItem(name: "query", value: query),
    URLQueryItem(name: "include_adult", value: "false"),
    URLQueryItem(name: "language", value: "en-US"),
    URLQueryItem(name: "page", value: "1")
]

guard let url = components.url else { fatalError() }

let semaphore = DispatchSemaphore(value: 0)
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    defer { semaphore.signal() }
    if let error = error {
        print("Error: \(error)")
        return
    }
    guard let data = data else { return }
    do {
        let decoded = try JSONDecoder().decode(TMDBListResponse.self, from: data)
        print("Success! \(decoded.results.count) results.")
    } catch {
        print("Decode error: \(error)")
        if let jsonString = String(data: data, encoding: .utf8) {
             print("JSON: \(jsonString)")
        }
    }
}
task.resume()
semaphore.wait()
