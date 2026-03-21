import Foundation

// MARK: - API Response Models
// Defined in a separate file to ensure no MainActor inference leakage.

struct TMDBListResponse: Decodable, Sendable {
    let results: [TMDBResult]
}

// TMDBResult uses 'vote_average', NOT 'imdb_rating'
// TMDBResult uses 'vote_average', NOT 'imdb_rating'
struct TMDBResult: Decodable, Sendable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let release_date: String?
    let first_air_date: String?
    let vote_average: Double? // This is the correct field from TMDB
    let vote_count: Int?
    let poster_path: String?
    let original_language: String?
    var media_type: String? // Changed from 'let' to 'var' to allow manual override in Service
    let genre_ids: [Int]?
}

// MARK: - Extended Metadata Responses

struct TMDBDetailResponse: Decodable, Sendable {
    let genres: [TMDBGenre]?
    let status: String?
}

struct TMDBGenre: Decodable, Sendable {
    let id: Int
    let name: String
}

struct TMDBCreditsResponse: Decodable, Sendable {
    let cast: [TMDBCastMember]?
}

struct TMDBCastMember: Decodable, Sendable {
    let name: String
    let character: String?
    let profile_path: String?
    let order: Int?
}

struct TMDBProvidersResponse: Decodable, Sendable {
    let results: [String: TMDBRegionProviders]?
}

struct TMDBRegionProviders: Decodable, Sendable {
    let flatrate: [TMDBProvider]?
    let rent: [TMDBProvider]?
    let buy: [TMDBProvider]?
}

struct TMDBProvider: Decodable, Sendable {
    let provider_name: String
    let logo_path: String?
}

struct TMDBVideosResponse: Decodable, Sendable {
    let results: [TMDBVideoResult]?
}

struct TMDBVideoResult: Decodable, Sendable {
    let key: String?
    let site: String?
    let type: String?
    let official: Bool?
}


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
    return sortedResults
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
                 print("DOMAIN: \(r.title ?? "") V: \(r.vote_count ?? 0)")
             }
        } catch {
            print("DECODE ERR: \(error)")
        }
    }
}.resume()
group.wait()