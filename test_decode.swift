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

let group = DispatchGroup()
group.enter()

let url = URL(string: "https://api.themoviedb.org/3/search/multi?api_key=REDACTED_TMDB_KEY&query=batman&language=en-US&page=1")!

URLSession.shared.dataTask(with: url) { data, response, error in
    defer { group.leave() }
    
    if let e = error {
        print("Network Error:", e)
        return
    }
    
    guard let data = data else {
        print("No Data")
        return
    }
    
    do {
        let resp = try JSONDecoder().decode(TMDBListResponse.self, from: data)
        print("Success! Decoded \(resp.results.count) items.")
    } catch {
        print("Decoding Error:", error)
        print("JSON snippet:", String(data: data, encoding: .utf8)?.prefix(500) ?? "")
    }
}.resume()

group.wait()
