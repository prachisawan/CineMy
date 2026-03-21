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
    
    if let httpResponse = response as? HTTPURLResponse {
         print("Status \(httpResponse.statusCode)")
    }
}.resume()

group.wait()
