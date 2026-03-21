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

do {
    let response = try JSONDecoder().decode(TMDBListResponse.self, from: jsonRaw.data(using: .utf8)!)
    print("Test passed. Count: \(response.results.count)")
} catch {
    print("Test failed:", error)
}
