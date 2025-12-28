import Foundation

// MARK: - API Response Models
// Defined in a separate file to ensure no MainActor inference leakage.

struct TMDBListResponse: Decodable, Sendable {
    let results: [TMDBResult]
}

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
    let media_type: String?
    let genre_ids: [Int]?
}
