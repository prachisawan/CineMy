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

class EliteItem: CustomStringConvertible {
    let title: String
    init(title: String) { self.title = title }
    var description: String { return title }
}

let jsonRaw = """
{
  "page": 1,
  "results": [
    {
      "adult": false,
      "backdrop_path": "/b3zRQOvw5bUf3A0Teb1kXWn5TfV.jpg",
      "id": 268,
      "title": "Batman",
      "original_language": "en",
      "original_title": "Batman",
      "overview": "Batman must face his most ruthless nemesis when a deformed madman calling himself \\"The Joker\\" seizes control of Gotham's criminal underworld.",
      "poster_path": "/cxQKILudGjKxV9J96OtkzE7GgA2.jpg",
      "media_type": "movie",
      "genre_ids": [
        14,
        28,
        80
      ],
      "popularity": 73.082,
      "release_date": "1989-06-21",
      "video": false,
      "vote_average": 7.2,
      "vote_count": 7180
    },
    {
      "adult": false,
      "id": 2232,
      "name": "Christian Bale",
      "original_name": "Christian Bale",
      "media_type": "person",
      "popularity": 45.47,
      "gender": 2,
      "known_for_department": "Acting",
      "profile_path": "/b7fTC9WFkgqGOv77mLQtmD8B33N.jpg"
    }
  ],
  "total_pages": 4,
  "total_results": 71
}
"""

let response = try! JSONDecoder().decode(TMDBListResponse.self, from: jsonRaw.data(using: .utf8)!)
let uniqueResults = Array(Dictionary(grouping: response.results, by: { $0.id }).values.compactMap { $0.first })

let query = "batman"
let sortedResults: [TMDBResult]

let exactMatches = uniqueResults.filter { item in
    let title = (item.title ?? item.name ?? "").lowercased()
    let rating = item.vote_average ?? 0.0
    return title == query && rating > 0 && rating != 10.0
}

if !exactMatches.isEmpty {
    print("Exact match found!")
    let hasHighQuality = exactMatches.contains { ($0.vote_average ?? 0) > 7.0 }
    
    let finalExactMatches: [TMDBResult]
    if hasHighQuality {
        finalExactMatches = exactMatches.filter { ($0.vote_average ?? 0) >= 6.0 }
    } else {
        finalExactMatches = exactMatches
    }
    
    sortedResults = finalExactMatches.sorted { ($0.vote_count ?? 0) > ($1.vote_count ?? 0) }
} else {
    print("No exact match.")
    let qualityResults = uniqueResults.filter { item in 
         let rating = item.vote_average ?? 0
         let votes = item.vote_count ?? 0
         return rating > 0 && rating != 10.0 && votes >= 50
    }
    
    sortedResults = qualityResults.sorted { first, second in
        let title1 = (first.title ?? first.name ?? "").lowercased()
        let title2 = (second.title ?? second.name ?? "").lowercased()
        let votes1 = first.vote_count ?? 0
        let votes2 = second.vote_count ?? 0
        
        let starts1 = title1.hasPrefix(query)
        let starts2 = title2.hasPrefix(query)
        if starts1 && !starts2 { return true }
        if starts2 && !starts1 { return false }
        
        if votes1 != votes2 {
            return votes1 > votes2
        }
        
        return (first.vote_average ?? 0) > (second.vote_average ?? 0)
    }
}

let items = sortedResults.compactMap { dto -> EliteItem? in
    let displayTitle = dto.title ?? dto.name ?? "Unknown"
    
    if dto.media_type == "person" { 
        print("Filtered person")
        return nil 
    }
    
    if (dto.vote_count ?? 0) < 50 && (dto.overview ?? "").isEmpty { 
        print("Filtered due to vote count/overview")
        return nil 
    }
    
    return EliteItem(title: displayTitle)
}

print("Results mapped:")
for item in items {
    print("- \(item.title)")
}
