import Foundation

// Copy TMDBResponses
let content = try! String(contentsOfFile: "CineMy/Services/TMDBResponses.swift")

let decoderCode = """
import Foundation

\(content)

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
            let response = try JSONDecoder().decode(TMDBListResponse.self, from: data)
            for r in response.results {
                print("Parsed: \\(r.title ?? r.name ?? "")")
            }
        } catch {
            print("DECODE ERR: \\(error)")
        }
    }
}.resume()

group.wait()
"""
try! decoderCode.write(toFile: "test_snow24.swift", atomically: true, encoding: .utf8)
