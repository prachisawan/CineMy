import Foundation

let queryToTest = "Society of Snow"

Task {
    let service = TMDBService()
    do {
        print("Starting search for '\(queryToTest)'...")
        let results = try await service.searchMovies(query: queryToTest)
        print("Results count: \(results.count)")
        for r in results.prefix(5) {
            print("- \(r.title)")
        }
    } catch {
        print("Error: \(error)")
    }
    exit(0)
}
RunLoop.main.run()
