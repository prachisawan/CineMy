import SwiftUI
import SwiftData
import FirebaseCore // Import Firebase

@main
struct CineMyApp: App {
    // 1. Create the container manually
    let container: ModelContainer

    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        do {
            container = try ModelContainer(for: EliteItem.self, Friend.self)
            
            // 2. Check and Seed Data
            try seedDataIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 3. Use the container we created above
        .modelContainer(container)
    }

    // This function loads the JSON file into the database
    func seedDataIfNeeded(context: ModelContext) throws {
        // Check if data already exists to avoid duplicates
        let descriptor = FetchDescriptor<EliteItem>()
        let count = try context.fetchCount(descriptor)

        if count == 0 {
            print("Database empty. Seeding data...")
            
            // Locate the JSON file
            guard let url = Bundle.main.url(forResource: "movies_shows", withExtension: "json") else {
                print("Error: Could not find movies_shows.json")
                return
            }

            // Decode using the DTO helper (Fixes the error!)
            let data = try Data(contentsOf: url)
            let dtos = try JSONDecoder().decode([EliteItemDTO].self, from: data)
            
            // Convert DTOs to real Database items
            let items = dtos.map { $0.toModel() }

            for item in items {
                context.insert(item)
            }
            
            try context.save()
            print("Success! Added \(items.count) items to the database.")
        } else {
            print("Database already contains data. Skipping seed.")
        }
    }
}
