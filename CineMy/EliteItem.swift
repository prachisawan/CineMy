import Foundation
import SwiftData

@Model
final class EliteItem {
    @Attribute(.unique) var id: String
    var tmdbId: Int
    var title: String
    var type: String // "movie" or "show"
    var overview: String
    var releaseYear: String
    var director: String
    var cast: [String]
    var rating: Double
    var language: String
    var posterPath: String? // NEW: For web images
    
    // Status & Metadata
    var watchedCount: Int = 0
    var isInProgress: Bool = false
    var isWatchlist: Bool = false
    var lastWatched: Date?
    var genre: String
    var platforms: [String]
    
    init(id: String, tmdbId: Int, title: String, type: String, overview: String, releaseYear: String, director: String, cast: [String], rating: Double, language: String, posterPath: String? = nil, genre: String = "Drama", platforms: [String] = [], isWatchlist: Bool = false, lastWatched: Date? = nil) {
        self.id = id
        self.tmdbId = tmdbId
        self.title = title
        self.type = type
        self.overview = overview
        self.releaseYear = releaseYear
        self.director = director
        self.cast = cast
        self.rating = rating
        self.language = language
        self.posterPath = posterPath
        self.genre = genre
        self.platforms = platforms
        self.isWatchlist = isWatchlist
        self.lastWatched = lastWatched
    }
}

// We don't need the complex Decoder anymore because we are fetching from the Web!
// But we keep a simple one just in case you still use the local file for backups.
struct EliteItemDTO: Decodable {
    let id: String?
    let tmdb_id: Int
    let title: String
    let type: String?
    let overview: String
    let release_year: String?
    let rating: Double
    let language: String?
    
    func toModel() -> EliteItem {
        return EliteItem(
            id: UUID().uuidString,
            tmdbId: tmdb_id,
            title: title,
            type: type ?? "movie",
            overview: overview,
            releaseYear: release_year ?? "2024",
            director: "Unknown",
            cast: [],
            rating: rating,
            language: language ?? "en"
        )
    }
}
