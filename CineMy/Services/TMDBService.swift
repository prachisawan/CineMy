import Foundation

class TMDBService {
    // ⚠️ REPLACE THIS WITH YOUR ACTUAL API KEY
    private let apiKey = "REDACTED_TMDB_KEY"
    private let baseURL = "https://api.themoviedb.org/3"
    
    enum MediaType: String {
        case movie
        case tv
        case multi // Ambiguous search
    }
    
    // MARK: - Search Logic
    func searchMovies(query: String) async throws -> [EliteItem] {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedQuery.isEmpty { return [] }
        
        // 1. Analyze the sentence
        let analysis = analyzeQuery(cleanedQuery)
        
        let hasCoreSubject = !analysis.remainingText.isEmpty && analysis.remainingText.count > 1
        
        if hasCoreSubject {
            // Text Search (e.g. "Iron Man", "Breaking Bad")
            return try await fetchSearch(query: analysis.remainingText, year: analysis.year, type: analysis.type)
        } else {
            // Smart Filter (e.g. "Best Comedy 2023", "Korean Drama")
            // If "multi" was selected but no text, default to Movie for now.
            let discoverType: MediaType = (analysis.type == .tv) ? .tv : .movie
            
            return try await fetchDiscover(
                type: discoverType,
                language: analysis.language,
                genre: analysis.genre,
                rating: analysis.rating,
                year: analysis.year,
                sortBy: analysis.sortBy
            )
        }
    }
    
    // MARK: - Smart Analyzer
    struct QueryAnalysis {
        var type: MediaType = .multi
        var language: String?
        var genre: Int?
        var rating: Double?
        var year: Int?
        var sortBy: String = "popularity.desc"
        var remainingText: String
    }
    
    private func analyzeQuery(_ text: String) -> QueryAnalysis {
        var remaining = text.lowercased()
        var analysis = QueryAnalysis(remainingText: "")
        
        // 1. Detect Type (Movie vs TV)
        if remaining.contains("series") || remaining.contains("show") || remaining.contains("tv") {
            analysis.type = .tv
        } else if remaining.contains("movie") || remaining.contains("film") {
            analysis.type = .movie
        }
        
        // 2. Detect Sorting
        if remaining.contains("best") || remaining.contains("top") || remaining.contains("highest") {
            analysis.sortBy = "vote_average.desc"
            remaining = removeWords(from: remaining, words: ["best", "top", "highest", "ranking", "ranked"])
        } else if remaining.contains("new") || remaining.contains("latest") || remaining.contains("recent") {
            analysis.sortBy = "primary_release_date.desc"
            analysis.year = Calendar.current.component(.year, from: Date())
            remaining = removeWords(from: remaining, words: ["new", "latest", "recent", "coming soon", "just dropped"])
        }
        
        // 3. Detect Language
        if let lang = detectLanguage(in: remaining) {
            analysis.language = lang.code
            remaining = remaining.replacingOccurrences(of: lang.name, with: "")
        }
        
        // 4. Detect Genre
        let detectionType = (analysis.type == .multi) ? .movie : analysis.type
        if let gen = detectGenre(in: remaining, type: detectionType) {
            analysis.genre = gen.id
            remaining = remaining.replacingOccurrences(of: gen.name, with: "")
            if analysis.type == .multi { analysis.type = .movie }
        }
        
        // 5. Detect Rating
        if let rating = detectRating(in: remaining) {
            analysis.rating = rating.value
            remaining = remaining.replacingOccurrences(of: rating.rawString, with: "")
        }
        
        // 6. Detect Year
        if let year = detectYear(in: remaining) {
            analysis.year = year.value
            remaining = remaining.replacingOccurrences(of: year.rawString, with: "")
        }
        
        // 7. Cleanup
        let fillerWords = [
            "movies", "movie", "films", "film", "cinema",
            "shows", "show", "series", "tv", "season", "episodes",
            "releases", "release", "released", "dropped", "out now",
            "rating", "ratings", "rated", "score", "scored", "imdb", "tmdb",
            "above", "over", "under", "below", "more than", "less than",
            "with", "in", "on", "about", "of", "for", "watch", "looking for", "find me"
        ]
        
        remaining = removeWords(from: remaining, words: fillerWords)
        analysis.remainingText = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return analysis
    }
    
    // MARK: - Detectors
    private func detectLanguage(in text: String) -> (name: String, code: String)? {
        let map = ["malayalam": "ml", "hindi": "hi", "tamil": "ta", "telugu": "te", "kannada": "kn", "korean": "ko", "french": "fr", "english": "en", "spanish": "es", "japanese": "ja", "chinese": "zh", "italian": "it", "german": "de"]
        for (name, code) in map {
            if text.contains(name) { return (name, code) }
        }
        return nil
    }
    
    private func detectGenre(in text: String, type: MediaType) -> (name: String, id: Int)? {
        // TMDB Genre IDs
        let movieMap = [
            "action": 28, "comedy": 35, "drama": 18, "horror": 27, "romance": 10749, 
            "sci-fi": 878, "scifi": 878, "thriller": 53, "animation": 16, "adventure": 12, "crime": 80, "family": 10751, "fantasy": 14
        ]
        let tvMap = [
            "action": 10759, "adventure": 10759, "animation": 16, "comedy": 35, "crime": 80, "documentary": 99, 
            "drama": 18, "family": 10751, "kids": 10762, "mystery": 9648, "news": 10763, "reality": 10764, 
            "sci-fi": 10765, "scifi": 10765, "fantasy": 10765, "soap": 10766, "talk": 10767, "war": 10768, "politics": 10768
        ]
        let map = (type == .tv) ? tvMap : movieMap
        for (name, id) in map {
            if text.contains(name) { return (name, id) }
        }
        return nil
    }
    
    private func detectRating(in text: String) -> (value: Double, rawString: String)? {
        let pattern = "(?:rating|above|over|>)\\s*(\\d+(\\.\\d+)?)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first {
            let raw = nsString.substring(with: match.range)
            let numberPart = raw.filter { "0123456789.".contains($0) }
            if let val = Double(numberPart) { return (val, raw) }
        }
        return nil
    }

    private func detectYear(in text: String) -> (value: Int, rawString: String)? {
        let pattern = "\\b(19|20)\\d{2}\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first {
            let raw = nsString.substring(with: match.range)
            if let val = Int(raw) { return (val, raw) }
        }
        return nil
    }
    
    private func removeWords(from text: String, words: [String]) -> String {
        var newText = text
        for word in words {
            newText = newText.replacingOccurrences(of: "\\b\(word)\\b", with: "", options: .regularExpression)
        }
        return newText
    }
    
    // MARK: - API Calls
    
    private func fetchSearch(query: String, year: Int?, type: MediaType) async throws -> [EliteItem] {
        let endpoint: String
        switch type {
        case .movie: endpoint = "search/movie"
        case .tv: endpoint = "search/tv"
        case .multi: endpoint = "search/multi"
        }
        
        var components = URLComponents(string: "\(baseURL)/\(endpoint)")!
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "1")
        ]
        
        if let year = year {
            if type == .movie {
                queryItems.append(URLQueryItem(name: "year", value: String(year)))
            } else if type == .tv {
                queryItems.append(URLQueryItem(name: "first_air_date_year", value: String(year)))
            }
        }
        
        components.queryItems = queryItems
        guard let url = components.url else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TMDBListResponse.self, from: data)
        
        // STRICT FILTERING (Client-Side)
        // 1. Minimum Rating: 6.0
        // 2. Minimum Votes: 500
        return response.results
            .filter { $0.media_type != "person" }
            .filter { ($0.vote_average ?? 0) >= 6.0 }
            .filter { ($0.vote_count ?? 0) >= 500 }
            .map { $0.toDomainModel(fallbackType: type) }
    }
    
    private func fetchDiscover(type: MediaType, language: String?, genre: Int?, rating: Double?, year: Int?, sortBy: String) async throws -> [EliteItem] {
        let endpoint = (type == .movie) ? "discover/movie" : "discover/tv"
        var components = URLComponents(string: "\(baseURL)/\(endpoint)")!
        
        // STRICT FILTERING (API-Side)
        // Ensure strictly >= 6.0, unless user requested higher (e.g. 8.0)
        let minRating = max(6.0, rating ?? 0.0)
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_video", value: "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "sort_by", value: sortBy),
            
            // Quality Filters
            URLQueryItem(name: "vote_average.gte", value: String(minRating)),
            URLQueryItem(name: "vote_count.gte", value: "500") // 500+ Votes
        ]
        
        if let language = language {
             queryItems.append(URLQueryItem(name: "with_original_language", value: language))
        }
        
        if let genre = genre {
            queryItems.append(URLQueryItem(name: "with_genres", value: String(genre)))
        }
        
        if let year = year {
             let param = (type == .movie) ? "primary_release_year" : "first_air_date_year"
            queryItems.append(URLQueryItem(name: param, value: String(year)))
        }
        
        components.queryItems = queryItems
        guard let url = components.url else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TMDBListResponse.self, from: data)
        return response.results.map { $0.toDomainModel(fallbackType: type) }
    }
}

// MARK: - Internal Response Models
fileprivate struct TMDBListResponse: Decodable {
    let results: [TMDBResult]
}

fileprivate struct TMDBResult: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let release_date: String?
    let first_air_date: String?
    let vote_average: Double?
    let vote_count: Int? // Added for quality filtering
    let poster_path: String?
    let original_language: String?
    let media_type: String?
    
    func toDomainModel(fallbackType: TMDBService.MediaType) -> EliteItem {
        let displayTitle = title ?? name ?? "Unknown"
        let date = release_date ?? first_air_date
        let year = String(date?.prefix(4) ?? "Unknown")
        
        let resolvedType: String
        if let mt = media_type {
            resolvedType = mt
        } else {
            if fallbackType == .multi {
                resolvedType = "movie"
            } else {
                resolvedType = fallbackType.rawValue
            }
        }
        
        return EliteItem(
            id: "\(resolvedType)-\(id)",
            tmdbId: id,
            title: displayTitle,
            type: resolvedType,
            overview: overview ?? "",
            releaseYear: year,
            director: "Unknown", 
            cast: [],
            rating: vote_average ?? 0.0,
            language: original_language ?? "en",
            posterPath: poster_path
        )
    }
}
