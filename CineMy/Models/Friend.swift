import Foundation
import SwiftData

@Model
final class Friend {
    @Attribute(.unique) var code: String
    var nickname: String
    var watchedCount: Int
    var watchedMovies: [Int] // List of TMDB IDs
    var lastUpdated: Date
    
    init(code: String, nickname: String, watchedCount: Int = 0, watchedMovies: [Int] = []) {
        self.code = code
        self.nickname = nickname
        self.watchedCount = watchedCount
        self.watchedMovies = watchedMovies
        self.lastUpdated = Date()
    }
}
