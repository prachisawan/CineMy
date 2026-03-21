import Foundation

// Paste TMDBResponses
let content = try! String(contentsOfFile: "CineMy/Services/TMDBResponses.swift")

let code = """
\(content)

func getDomainItems(from response: TMDBListResponse, query: String) -> [TMDBResult] {
    let sortedResults: [TMDBResult]
    let uniqueResults = Array(Dictionary(grouping: response.results, by: { $0.id }).values.compactMap { $0.first })
    
    let exactMatches = uniqueResults.filter { item in
        let title = (item.title ?? item.name ?? "").lowercased()
        let rating = item.vote_average ?? 0.0
        return title == query && rating > 0 && rating != 10.0
    }
    
    if !exactMatches.isEmpty {
        let hasHighQuality = exactMatches.contains { ($0.vote_average ?? 0) > 7.0 }
        let finalExactMatches: [TMDBResult]
        if hasHighQuality {
            finalExactMatches = exactMatches.filter { ($0.vote_average ?? 0) >= 6.0 }
        } else {
            finalExactMatches = exactMatches
        }
        sortedResults = finalExactMatches.sorted { ($0.vote_count ?? 0) > ($1.vote_count ?? 0) }
    } else {
        let qualityResults = uniqueResults.filter { item in 
            let rating = item.vote_average ?? 0
            let votes = item.vote_count ?? 0
            return rating > 0 && rating != 10.0 && votes >= 50
        }
        
        sortedResults = qualityResults.sorted { first, second in
            let title1 = (first.title ?? first.name ?? "").lowercased()
            let title2 = (second.title ?? second.name ?? "").lowercased()
            let votes1 = first.vote_count ?? 0
            let votes2 = second.vote_count ?? 0
            let starts1 = title1.hasPrefix(query)
            let starts2 = title2.hasPrefix(query)
            if starts1 && !starts2 { return true }
            if starts2 && !starts1 { return false }
            if votes1 != votes2 { return votes1 > votes2 }
            return (first.vote_average ?? 0) > (second.vote_average ?? 0)
        }
    }

    return sortedResults.compactMap { dto -> TMDBResult? in
        if dto.media_type == "person" { return nil }
        
        // **This is where it is failing, searchQuery is NOT nil in your app so it goes here**
        if query != "" {
            // **Society of Snow has 3414 votes, BUT wait! What if overview is empty or something? No it has 3414.**
            if (dto.vote_count ?? 0) < 50 && (dto.overview ?? "").isEmpty { 
                print("TRASH REMOVED: \\(dto.title ?? "") V = \\(dto.vote_count ?? 0)")
                return nil 
            }
        }
        return dto
    }
}

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
            let filtered = getDomainItems(from: response, query: "society snow")
             for r in filtered {
                 print("DOMAIN YES: \\(r.title ?? "") V: \\(r.vote_count ?? 0)")
             }
        } catch {
            print("DECODE ERR: \\(error)")
        }
    }
}.resume()
group.wait()
"""

try! code.write(toFile: "test_snow32.swift", atomically: true, encoding: .utf8)

