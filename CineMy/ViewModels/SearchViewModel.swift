import Foundation
import SwiftData
import NaturalLanguage

enum FilterState: String {
    case all = "All"
    case watched = "Watched"
    case unwatched = "Unwatched"
}

@Observable
class SearchViewModel {
    var searchText: String = ""
    var filterState: FilterState = .all
    
    var filteredItems: [EliteItem] = []
    
    // Extracted entities for UI verification
    var extractedGenre: String?
    var extractedYear: String?
    var extractedPerson: String?
    
    private var allItems: [EliteItem] = []
    
    init() {}
    
    func setAllItems(_ items: [EliteItem]) {
        self.allItems = items
        // If we already have a search query, re-process
        if !searchText.isEmpty {
            processSearch()
        }
    }
    
    func processSearch() {
        // Reset results first
        var candidates = allItems
        
        // 1. Apply Watched Filter
        switch filterState {
        case .watched:
            candidates = candidates.filter { $0.watchedCount > 0 }
        case .unwatched:
            candidates = candidates.filter { $0.watchedCount == 0 }
        case .all:
            break
        }
        
        // If search text is empty, just return the filtered candidates (or nothing? User said "when I type a query")
        // Usually search shows nothing until query, or shows all. Let's show filtered candidates if query is empty just to respond to the Filter Pills
        if searchText.isEmpty {
             filteredItems = candidates
             return
        }
        
        // Reset extracted
        extractedGenre = nil
        extractedYear = nil
        extractedPerson = nil
        
        // 2. NLTagger Extraction
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = searchText
        
        var keywords: [String] = []
        
        let stopWords: Set<String> = ["from", "in", "with", "by", "for", "about", "the", "a", "an", "on", "of"]
        
        tagger.enumerateTags(in: searchText.startIndex..<searchText.endIndex, unit: .word, scheme: .nameType, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in // Removed .joinNames
            let word = String(searchText[tokenRange])
            if stopWords.contains(word.lowercased()) { return true }
            if let tag = tag {
                if tag == .personalName {
                    extractedPerson = word
                } else if tag == .placeName || tag == .organizationName {
                    keywords.append(word)
                }
            } else {
                if let year = Int(word), year > 1900 && year < 2030 {
                    extractedYear = String(year)
                } else {
                    keywords.append(word)
                }
            }
            return true
        }
        
        // Simple heuristic for Genres
        let commonGenres = ["Thriller", "Action", "Drama", "Comedy", "Sci-Fi", "Horror", "Romance", "Adventure", "Crime", "Mystery"]
        for word in keywords {
            if commonGenres.contains(where: { $0.caseInsensitiveCompare(word) == .orderedSame }) {
                extractedGenre = word.capitalized
            }
        }
        
        // 3. Filtering Logic
        filteredItems = candidates.filter { item in
            var matches = true
            
            // Year Filter
            if let year = extractedYear {
                if item.releaseYear != year {
                    matches = false
                }
            }
            
                // Person Filter (Director or Cast)
            if let person = extractedPerson {
                let personLower = person.lowercased()
                let inCast = item.cast.contains { $0.lowercased().contains(personLower) }
                let isDirector = item.director.lowercased().contains(personLower)
                let titleMatch = item.title.lowercased().contains(personLower) // Fix: Allow if Title matches the "Person" name
                
                if !inCast && !isDirector && !titleMatch {
                    matches = false
                }
            }
            
            // Genre/Keyword/Deep Search
            // Search in Title, Overview, Type
            let textToSearch = (item.title + " " + item.overview + " " + item.type).lowercased()
            
            if let genre = extractedGenre {
                let genreLower = genre.lowercased()
                if !textToSearch.contains(genreLower) {
                    matches = false
                }
            }
            
            // Fallback: If no smart entities found, just naive text search
            if extractedGenre == nil && extractedYear == nil && extractedPerson == nil {
                let query = searchText.lowercased()
                if !textToSearch.contains(query) {
                    matches = false
                }
            }
            
            return matches
        }
        .sorted { $0.rating > $1.rating }
    }
}
