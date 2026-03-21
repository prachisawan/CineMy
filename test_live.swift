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

// The URL identical to the one the app uses under the hood:
let url = URL(string: "https://api.themoviedb.org/3/discover/movie?api_key=REDACTED_TMDB_KEY&include_adult=false&include_video=false&language=en-US&page=1&sort_by=popularity.desc&vote_average.gte=6.0&vote_count.gte=10&with_original_language=ml")!

var request = URLRequest(url: url)
request.timeoutInterval = 10 

URLSession.shared.dataTask(with: request) { data, response, error in
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
        for (i, r) in resp.results.prefix(5).enumerated() {
             let title = r.title ?? r.name ?? "Unknown"
             let rating = r.vote_average ?? 0
             print("\(i+1). \(title) (Rating: \(rating))")
        }
    } catch {
        print("Decoding Error:", error)
    }
}.resume()

group.wait()
