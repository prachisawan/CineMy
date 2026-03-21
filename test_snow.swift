import Foundation

let apiKey = "REDACTED_TMDB_KEY"
let query = "Society of Snow"

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
    guard let data = data else { return }
    do {
        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let results = jsonObject["results"] as? [[String: Any]] {
            print("Total entries: \(results.count)")
            for item in results.prefix(5) {
                let title = item["title"] as? String ?? "Unknown"
                let originalTitle = item["original_title"] as? String ?? ""
                let voteCount = item["vote_count"] as? Int ?? 0
                let voteAverage = item["vote_average"] as? Double ?? 0.0
                print("- \(title) (\(originalTitle)) | Votes: \(voteCount) | Rating: \(voteAverage)")
            }
        }
    } catch {
        print("Decode error: \(error)")
    }
}
task.resume()
semaphore.wait()
