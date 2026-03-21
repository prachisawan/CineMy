import Foundation

let apiKey = "REDACTED_TMDB_KEY"
var components = URLComponents(string: "https://api.themoviedb.org/3/search/multi")!
components.queryItems = [
    URLQueryItem(name: "api_key", value: apiKey),
    URLQueryItem(name: "query", value: "Society snow"),
    URLQueryItem(name: "include_adult", value: "false"),
    URLQueryItem(name: "language", value: "en-US"),
    URLQueryItem(name: "page", value: "1")
]

guard let url = components.url else { fatalError() }

let group = DispatchGroup()
group.enter()

let req = URLRequest(url: url)
URLSession.shared.dataTask(with: req) { data, response, error in
    defer { group.leave() }
    
    if let data = data {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]] {
                for r in results {
                     print("Title: \(r["title"] ?? r["name"] ?? "")")
                     print("Vote count: \(r["vote_count"] ?? 0)")
                     print("Vote avg: \(r["vote_average"] ?? 0.0)")
                }
            }
        } catch {
            print(error)
        }
    }
}.resume()

group.wait()
