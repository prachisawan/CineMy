import Foundation
import SwiftData

@Observable
class DataLoader {
    var items: [EliteItem] = []
    
    // Core logic to load data from JSON into SwiftData
    func loadData(modelContext: ModelContext) {
        // 1. Check if we already have data
        let descriptor = FetchDescriptor<EliteItem>()
        do {
            let existingItems = try modelContext.fetch(descriptor)
            if !existingItems.isEmpty {
                print("Data already loaded. Count: \(existingItems.count)")
                self.items = existingItems
                return
            }
        } catch {
            print("Fetch error: \(error)")
        }
        
        // 2. Load from JSON
        guard let url = Bundle.main.url(forResource: "movies_shows", withExtension: "json") else {
            print("movies_shows.json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dtos = try decoder.decode([EliteItemDTO].self, from: data)
            
            print("Seeding \(dtos.count) items into SwiftData...")
            
            for dto in dtos {
                let item = dto.toModel()
                modelContext.insert(item)
                self.items.append(item)
            }
            
            // Save context
            // SwiftData auto-saves, but explicit save can be good for batch.
            // try modelContext.save() 
            print("Seeding complete.")
            
        } catch {
            print("Error loading/parsing JSON: \(error)")
        }
    }
}
