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
