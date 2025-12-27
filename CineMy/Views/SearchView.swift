import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    
    // We use State for results now, because they come from the Web, not the Database
    @State private var searchResults: [EliteItem] = []
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    private let service = TMDBService() // Our new API engine
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                VStack(alignment: .leading, spacing: 10) {
                    Text("Search the World")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)
                        TextField("Ex: 'Malayalam movies' or 'Batman'", text: $searchText)
                            .submitLabel(.search)
                            .autocorrectionDisabled()
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                // Result Count Indicator
                if !searchResults.isEmpty {
                    HStack {
                        Text("\(searchResults.count) results found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    .transition(.opacity)
                }
                
                // Results Area
                if isSearching {
                    ProgressView("Searching TMDB...")
                        .padding(.top, 50)
                    Spacer()
                } else if let error = errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try a different title or language."))
                } else if searchText.isEmpty {
                    ContentUnavailableView("Global Search", systemImage: "popcorn", description: Text("Search for any movie or show.\nTry 'Korean Thriller' or 'Inception'"))
                } else {
                    List(searchResults) { item in
                        ZStack {
                            SmartSearchCard(item: item)
                            NavigationLink(destination: MovieDetailView(item: item)) { EmptyView() }.opacity(0)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                // Call the API
                let items = try await service.searchMovies(query: searchText)
                
                // Update UI on Main Thread AND Sync with DB
                await MainActor.run {
                    self.searchResults = syncWithDatabase(items)
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to connect. Check your internet."
                    self.isSearching = false
                }
            }
        }
    }
    
    // Sync API results with local DB to show correct status (Watched/In Progress)
    private func syncWithDatabase(_ items: [EliteItem]) -> [EliteItem] {
        let syncedItems = items.map { item -> EliteItem in
            let id = item.id
            let descriptor = FetchDescriptor<EliteItem>(predicate: #Predicate { $0.id == id })
            if let existing = try? modelContext.fetch(descriptor).first {
                return existing
            }
            return item
        }
        
        // Filter out items that are already watched (as requested by user)
        // Keep items that are new OR in-progress. Hide finished ones.
        return syncedItems.filter { $0.watchedCount == 0 }
    }
}

// MARK: - Card with AsyncImage (Web Images!)
struct SmartSearchCard: View {
    let item: EliteItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster Image
            if let path = item.posterPath {
                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(path)")) { image in
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().foregroundStyle(.gray.opacity(0.3))
                }
                .frame(width: 80, height: 120)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
                    .overlay(Image(systemName: "film").foregroundStyle(.gray))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .bold()
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // NEW: My List Badge Logic (Minimal Dot)
                    if item.isWatchlist {
                         Image(systemName: "bookmark.fill")
                            .foregroundStyle(.purple)
                            .font(.caption)
                    }
                }
                
                Text(item.releaseYear)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    TagView(text: item.language.uppercased(), color: .blue)
                    TagView(text: item.genre, color: .purple)
                    if item.type == "tv" {
                        TagView(text: "TV", color: .green)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption2)
                    Text(String(format: "%.1f", item.rating))
                        .font(.caption)
                        .bold()
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Helper View for Metadata Tags
struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .cornerRadius(8)
    }
}
