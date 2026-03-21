import Foundation

let query = "Society of Snow"

enum MediaType: String {
    case movie
    case tv
    case multi // Ambiguous search
}

struct QueryAnalysis {
    var type: MediaType = .multi
    var language: String?
    var genre: Int?
    var rating: Double?
    var year: Int?
    var sortBy: String = "popularity.desc"
    var remainingText: String
}

func convertNumberWordsToDigits(in text: String) -> String {
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

func detectLanguage(in text: String) -> (name: String, code: String)? {
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

func detectGenre(in text: String, type: MediaType) -> (name: String, id: Int)? {
    let movieMap = ["action": 28, "comedy": 35, "drama": 18, "horror": 27, "romance": 10749, "sci-fi": 878, "scifi": 878, "thriller": 53, "animation": 16, "adventure": 12, "crime": 80, "family": 10751, "fantasy": 14]
    for (name, id) in movieMap {
        if text.contains(name) { return (name, id) }
    }
    return nil
}

func removeWords(from text: String, words: [String]) -> String {
    var newText = text
    for word in words {
        newText = newText.replacingOccurrences(of: "\\b\(word)\\b", with: "", options: .regularExpression)
    }
    return newText
}

func analyzeQuery(_ text: String) -> QueryAnalysis {
    var remaining = convertNumberWordsToDigits(in: text.lowercased())
    var analysis = QueryAnalysis(remainingText: "")
    
    // 3. Detect Language
    if let lang = detectLanguage(in: remaining) {
        analysis.language = lang.code
        remaining = remaining.replacingOccurrences(of: lang.name, with: "")
    }
    
    // 4. Detect Genre
    if let gen = detectGenre(in: remaining, type: analysis.type) {
        analysis.genre = gen.id
        remaining = remaining.replacingOccurrences(of: gen.name, with: "")
        if analysis.type == .multi { analysis.type = .movie }
    }
    
    let fillerWords = ["movies", "movie", "films", "film", "cinema", "shows", "show", "series", "tv", "season", "episodes", "releases", "release", "released", "dropped", "out now", "rating", "ratings", "rated", "score", "scored", "imdb", "tmdb", "above", "over", "under", "below", "more than", "less than", "with", "in", "on", "about", "of", "for", "from", "since", "watch", "looking for", "find me", "and", "or", "streaming"]
    
    remaining = removeWords(from: remaining, words: fillerWords)
    
    analysis.remainingText = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
    return analysis
}

let result = analyzeQuery(query)
print("Analysis for '\(query)':")
print("Remaining text: '\(result.remainingText)'")
print("Genre: \(result.genre ?? -1)")
