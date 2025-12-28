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
    @MainActor
    func searchMovies(query: String) async throws -> [EliteItem] {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedQuery.isEmpty { return [] }
        
        let analysis = analyzeQuery(cleanedQuery)
        
        // DECISION ENGINE
        let hasFilters = (analysis.genre != nil || analysis.language != nil || analysis.rating != nil || analysis.year != nil)
        let text = analysis.remainingText
        let isJustNumbers = Int(text) != nil
        let isShort = text.count < 2
        
        // Prefer Discover if we have filters and the text is junk/numbers
        let useDiscover = hasFilters && (text.isEmpty || isJustNumbers || isShort)
        
        if !useDiscover && !text.isEmpty {
            return try await fetchSearch(query: text, year: analysis.year, type: analysis.type)
        } else {
            let discoverType: MediaType = (analysis.type == .tv) ? .tv : .movie
            return try await fetchDiscover(type: discoverType, language: analysis.language, genre: analysis.genre, rating: analysis.rating, year: analysis.year, sortBy: analysis.sortBy)
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
        var remaining = convertNumberWordsToDigits(in: text.lowercased())
        var analysis = QueryAnalysis(remainingText: "")
        
        // 1. Detect Type
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
        
        let fillerWords = ["movies", "movie", "films", "film", "cinema", "shows", "show", "series", "tv", "season", "episodes", "releases", "release", "released", "dropped", "out now", "rating", "ratings", "rated", "score", "scored", "imdb", "tmdb", "above", "over", "under", "below", "more than", "less than", "with", "in", "on", "about", "of", "for", "watch", "looking for", "find me", "and", "or"]
        
        remaining = removeWords(from: remaining, words: fillerWords)
        
        analysis.remainingText = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
        return analysis
    }
    
    // MARK: - Detectors
    private func convertNumberWordsToDigits(in text: String) -> String {
        let mapping = [
            "one": "1", "two": "2", "three": "3", "four": "4", "five": "5",
            "six": "6", "seven": "7", "eight": "8", "nine": "9", "ten": "10"
        ]
        var newText = text
        for (word, digit) in mapping {
            newText = newText.replacingOccurrences(of: "\\b\(word)\\b", with: digit, options: .regularExpression)
        }
        return newText
    }
    
    static func getGenreName(for id: Int) -> String {
        let map = [
            28: "Action", 12: "Adventure", 16: "Animation", 35: "Comedy", 80: "Crime", 99: "Documentary", 18: "Drama",
            10751: "Family", 14: "Fantasy", 36: "History", 27: "Horror", 10402: "Music", 9648: "Mystery", 10749: "Romance",
            878: "Sci-Fi", 10770: "TV Movie", 53: "Thriller", 10752: "War", 37: "Western", 10759: "Action & Adventure",
            10762: "Kids", 10763: "News", 10764: "Reality", 10765: "Sci-Fi & Fantasy", 10766: "Soap", 10767: "Talk", 10768: "War & Politics"
        ]
        return map[id] ?? "Drama"
    }

    private func detectLanguage(in text: String) -> (name: String, code: String)? {
        let map = [
            "malayalam": "ml", "hindi": "hi", "tamil": "ta", "telugu": "te", "kannada": "kn",
            "marathi": "mr", "bengali": "bn", "gujarati": "gu", "punjabi": "pa",
            "korean": "ko", "french": "fr", "english": "en", "spanish": "es", "japanese": "ja", 
            "chinese": "zh", "italian": "it", "german": "de"
        ]
        for (name, code) in map {
            if text.contains(name) { return (name, code) }
        }
        return nil
    }
    
    private func detectGenre(in text: String, type: MediaType) -> (name: String, id: Int)? {
        let movieMap = ["action": 28, "comedy": 35, "drama": 18, "horror": 27, "romance": 10749, "sci-fi": 878, "scifi": 878, "thriller": 53, "animation": 16, "adventure": 12, "crime": 80, "family": 10751, "fantasy": 14]
        let tvMap = ["action": 10759, "adventure": 10759, "animation": 16, "comedy": 35, "crime": 80, "documentary": 99, "drama": 18, "family": 10751, "kids": 10762, "mystery": 9648, "news": 10763, "reality": 10764, "sci-fi": 10765, "scifi": 10765, "fantasy": 10765, "soap": 10766, "talk": 10767, "war": 10768, "politics": 10768]
        let map = (type == .tv) ? tvMap : movieMap
        for (name, id) in map {
            if text.contains(name) { return (name, id) }
        }
        return nil
    }
    
    // UPDATED: Now handles percentages (80%) by normalizing to 0-10 scale
    private func detectRating(in text: String) -> (value: Double, rawString: String)? {
        let prefixPattern = "(?:rating|rated|score|imdb|tmdb|above|over|>|min)\\s*(\\d+(\\.\\d+)?)"
        let suffixPattern = "(\\d+(\\.\\d+)?)\\s*(?:\\+|and above|or higher|up|stars|%)" // Added % support
        
        if let match = findMatch(pattern: prefixPattern, in: text, captureIndex: 1) {
            return normalizeRating(match)
        }
        if let match = findMatch(pattern: suffixPattern, in: text, captureIndex: 1) {
            return normalizeRating(match)
        }
        return nil
    }
    
    private func normalizeRating(_ match: (Double, String)) -> (Double, String) {
        var value = match.0
        // Fix: User might enter "80%" or "85" thinking of Rotten Tomatoes or Metacritic style
        // TMDB uses 0-10 scale. If value is > 10, assume it's 0-100 and normalize.
        if value > 10.0 {
            value = value / 10.0
        }
        return (value, match.1)
    }
    
    private func findMatch(pattern: String, in text: String, captureIndex: Int) -> (Double, String)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        if let match = results.first {
            let fullMatchString = nsString.substring(with: match.range)
            if match.numberOfRanges > captureIndex {
                let numberString = nsString.substring(with: match.range(at: captureIndex))
                if let val = Double(numberString) { return (val, fullMatchString) }
            }
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
    
    // MARK: - API Calls (PAGINATED & CONCURRENCY SAFE)
    
    @MainActor
    private func fetchSearch(query: String, year: Int?, type: MediaType) async throws -> [EliteItem] {
        // Fetch 5 pages for Search (100 results max)
        var allResults: [TMDBResult] = [] // Store as DTOs first
        for page in 1...5 {
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
                URLQueryItem(name: "page", value: String(page))
            ]
            
            if let year = year {
                if type == .movie { queryItems.append(URLQueryItem(name: "year", value: String(year))) }
                else if type == .tv { queryItems.append(URLQueryItem(name: "first_air_date_year", value: String(year))) }
            }
            
            components.queryItems = queryItems
            guard let url = components.url else { continue }
            
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let response = try? JSONDecoder().decode(TMDBListResponse.self, from: data) {
                allResults.append(contentsOf: response.results)
            }
        }
        
        return convertToDomainAndFilter(results: allResults, fallbackType: type, searchQuery: query)
    }
    
    @MainActor
    private func fetchDiscover(type: MediaType, language: String?, genre: Int?, rating: Double?, year: Int?, sortBy: String) async throws -> [EliteItem] {
        // Fetch up to 20 pages (400 results) to ensure we get "all" relevant items for strict filters
        // Return TMDBResult (struct) instead of EliteItem (class) to avoid Sendable warnings
        let results = await withTaskGroup(of: [TMDBResult].self) { group in
            for page in 1...20 {
                group.addTask {
                    let endpoint = (type == .movie) ? "discover/movie" : "discover/tv"
                    var components = URLComponents(string: "\(self.baseURL)/\(endpoint)")!
                    
                    // TMDB API uses a 0-10 scale for 'vote_average'.
                    // Users might input:
                    // - "8.5" (IMDb style) -> we send 8.5
                    // - "85" or "85%" (Percentage) -> detector normalizes to 8.5
                    // - "8" -> we send 8.0
                    // Default baseline is 6.0 if no specific rating is requested.
                    let minRating = max(6.0, rating ?? 0.0)
                    
                    // Dynamic Vote Threshold
                    // - Regional content (Indian languages) often has lower vote counts on TMDB despite being high quality/popular.
                    // - Global/English content needs a higher threshold to filter spam/noise.
                    let indianLanguages = ["ml", "ta", "te", "kn", "hi", "mr", "bn", "gu", "pa"] 
                    let isRegionalSearch = indianLanguages.contains(language ?? "")
                    let voteThreshold = isRegionalSearch ? "10" : "200"
                    
                    var queryItems = [
                        URLQueryItem(name: "api_key", value: self.apiKey),
                        URLQueryItem(name: "include_adult", value: "false"),
                        URLQueryItem(name: "include_video", value: "false"),
                        URLQueryItem(name: "language", value: "en-US"),
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "sort_by", value: sortBy),
                        URLQueryItem(name: "vote_average.gte", value: String(minRating)),
                        URLQueryItem(name: "vote_count.gte", value: voteThreshold)
                    ]
                    
                    if let language = language { queryItems.append(URLQueryItem(name: "with_original_language", value: language)) }
                    if let genre = genre { queryItems.append(URLQueryItem(name: "with_genres", value: String(genre))) }
                    if let year = year {
                        let param = (type == .movie) ? "primary_release_year" : "first_air_date_year"
                        queryItems.append(URLQueryItem(name: param, value: String(year)))
                    }
                    
                    components.queryItems = queryItems
                    guard let url = components.url else { return [] }
                    
                    if let (data, _) = try? await URLSession.shared.data(from: url),
                       let response = try? JSONDecoder().decode(TMDBListResponse.self, from: data) {
                        return response.results
                    }
                    return []
                }
            }
            
            var collected: [TMDBResult] = []
            for await pageResults in group {
                collected.append(contentsOf: pageResults)
            }
            return collected
        }
        
        return convertToDomainAndFilter(results: results, fallbackType: type)
    }

    // Helper to convert DTOs to Domain Models
    private func convertToDomainAndFilter(results: [TMDBResult], fallbackType: MediaType, searchQuery: String? = nil) -> [EliteItem] {
        // 1. Deduplicate DTOs first
        let uniqueResults = Array(Dictionary(grouping: results, by: { $0.id }).values.compactMap { $0.first })
        
        // 2. Sort Logic
        let sortedResults: [TMDBResult]
        
        if let query = searchQuery?.lowercased() {
             // SEARCH MODE: Relevance Priority
             // 1. First, apply the strict rating filter requested by user
             let qualityResults = uniqueResults.filter { ($0.vote_average ?? 0) >= 6.0 }
             
             sortedResults = qualityResults.sorted { first, second in
                 let title1 = (first.title ?? first.name ?? "").lowercased()
                 let title2 = (second.title ?? second.name ?? "").lowercased()
                 let votes1 = first.vote_count ?? 0
                 let votes2 = second.vote_count ?? 0
                 
                 // Priority 1: Exact Match wins
                 if title1 == query && title2 != query { return true }
                 if title2 == query && title1 != query { return false }
                 
                 // Priority 2: Starts With wins
                 let starts1 = title1.hasPrefix(query)
                 let starts2 = title2.hasPrefix(query)
                 if starts1 && !starts2 { return true }
                 if starts2 && !starts1 { return false }
                 
                 // Priority 3: Vote Count (Popularity) wins for tie-breaking
                 if votes1 != votes2 {
                     return votes1 > votes2
                 }
                 
                 // Fallback: Rating
                 return (first.vote_average ?? 0) > (second.vote_average ?? 0)
             }
        } else {
            // DISCOVER MODE: Rating Priority (High Quality)
            sortedResults = uniqueResults
                .filter { ($0.vote_average ?? 0) >= 6.0 } // Strict 6.0+ for Discover
                .sorted { ($0.vote_average ?? 0) > ($1.vote_average ?? 0) }
        }

        // 3. Map to Domain
        return sortedResults.compactMap { dto -> EliteItem? in
            let displayTitle = dto.title ?? dto.name ?? "Unknown"
            // Filter out Persons if any slipped through
            if dto.media_type == "person" { return nil }
            
            // Search Mode Validity Check:
            if searchQuery != nil {
                // For search, basic validity: must have votes or description
                if (dto.vote_count ?? 0) == 0 && (dto.overview ?? "").isEmpty { return nil }
            }
            
            let date = dto.release_date ?? dto.first_air_date
            let year = String(date?.prefix(4) ?? "Unknown")
            
            let resolvedType: String
            if let mt = dto.media_type {
                resolvedType = mt
            } else {
                if fallbackType == .multi {
                    resolvedType = "movie"
                } else {
                    resolvedType = fallbackType.rawValue
                }
            }
            
            var genreName = "Drama"
            if let ids = dto.genre_ids, let firstId = ids.first {
                genreName = TMDBService.getGenreName(for: firstId)
            }
            
            return EliteItem(
                id: "\(resolvedType)-\(dto.id)",
                tmdbId: dto.id,
                title: displayTitle,
                type: resolvedType,
                overview: dto.overview ?? "",
                releaseYear: year,
                director: "Unknown",
                cast: [],
                rating: dto.vote_average ?? 0.0,
                language: dto.original_language ?? "en",
                posterPath: dto.poster_path,
                genre: genreName
            )
        }
    }
}
