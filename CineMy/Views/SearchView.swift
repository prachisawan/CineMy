import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var friends: [Friend]
    
    // We use State for results now, because they come from the Web, not the Database
    @State private var rawAPIResults: [EliteItem] = []
    @State private var searchResults: [EliteItem] = []
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var includeWatched = true
    
    // Watch Party State
    @State private var showFriendFilter = false
    @State private var selectedFriendCodes: Set<String> = []
    
    private let service = TMDBService() // Our new API engine
    private let friendService = FriendService.shared // Start using the shared service directly for refreshing
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Search the World")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !friends.isEmpty {
                            Button(action: { showFriendFilter = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedFriendCodes.isEmpty ? "person.2" : "person.2.fill")
                                    if !selectedFriendCodes.isEmpty {
                                        Text("\(selectedFriendCodes.count)")
                                            .font(.caption2)
                                            .bold()
                                            .padding(4)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(selectedFriendCodes.isEmpty ? .secondary : .blue)
                            }
                        }
                    }
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
                    
                    Toggle("Include Watched Items", isOn: $includeWatched)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                        .tint(.blue)
                        .onChange(of: includeWatched) {
                            withAnimation {
                                self.searchResults = syncWithDatabase(rawAPIResults)
                            }
                        }
                }
                .padding(.bottom, 10)
                
                // Result Count Indicator
                if !searchResults.isEmpty {
                    HStack {
                        Text("\(searchResults.count) results found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !selectedFriendCodes.isEmpty {
                            Spacer()
                            Text("Filtering for \(selectedFriendCodes.count) friends")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        } else {
                            Spacer()
                        }
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
                    if !selectedFriendCodes.isEmpty {
                         ContentUnavailableView("All Watched!", systemImage: "checkmark.seal", description: Text("No unwatched movies found for this group.\nTry a different search."))
                    } else {
                        ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try a different title or language."))
                    }
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
            .sheet(isPresented: $showFriendFilter) {
                NavigationStack {
                    List {
                        Section(header: Text("Filter Watched Movies")) {
                            Toggle("Show Unwatched by Me", isOn: .constant(true))
                                .disabled(true)
                                .tint(.blue)
                            
                            ForEach(friends) { friend in
                                HStack {
                                    Image(systemName: "person.circle")
                                    VStack(alignment: .leading) {
                                        Text(friend.nickname)
                                        Text("\(friend.watchedMovies.count) watched")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    if selectedFriendCodes.contains(friend.code) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedFriendCodes.contains(friend.code) {
                                        selectedFriendCodes.remove(friend.code)
                                    } else {
                                        selectedFriendCodes.insert(friend.code)
                                    }
                                }
                            }
                        }
                        
                        Section(footer: Text("Tap 'Refresh Data' to ensure you have the latest watch history from the cloud.")) {
                            Button("Refresh Friends Data") {
                                Task {
                                    await refreshAllFriends()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .navigationTitle("Group Watch")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showFriendFilter = false
                                if !searchResults.isEmpty {
                                    // Re-filter existing results without API call if just toggling
                                    performSearch() 
                                }
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
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
                    self.rawAPIResults = items
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
    
    private func refreshAllFriends() async {
        for friend in friends {
            if let (count, list) = try? await friendService.fetchFriend(code: friend.code) {
                await MainActor.run {
                    friend.watchedCount = count
                    friend.watchedMovies = list
                    friend.lastUpdated = Date()
                }
            }
        }
    }
    
    // Sync API results with local DB AND Apply Friend Filters
    private func syncWithDatabase(_ items: [EliteItem]) -> [EliteItem] {
        // 1. First, merge with local data (to know if I watched it)
        let syncedItems = items.map { item -> EliteItem in
            let id = item.id
            let descriptor = FetchDescriptor<EliteItem>(predicate: #Predicate { $0.id == id })
            if let existing = try? modelContext.fetch(descriptor).first {
                return existing
            }
            return item
        }
        
        // 2. Identify Exclusion List (My Watched + Friends Watched)
        var excludedTMDBIDs: Set<Int> = []
        
        // Add selected friends' history
        let activeFriends = friends.filter { selectedFriendCodes.contains($0.code) }
        
        print("DEBUG: Filtering for \(activeFriends.count) friends.")
        
        for friend in activeFriends {
            print("DEBUG: Friend \(friend.nickname) has watched IDs: \(friend.watchedMovies)")
            for id in friend.watchedMovies {
                excludedTMDBIDs.insert(id)
            }
        }
        
        print("DEBUG: Total Excluded IDs: \(excludedTMDBIDs)")
        
        // 3. Filter
        return syncedItems.filter { item in
            // ALWAYS honor the manual toggle:
            if !includeWatched && item.watchedCount > 0 { 
                return false 
            }
            
            // If building a Group Watchlist (friends selected), hide the movies ANYONE has seen.
            if !selectedFriendCodes.isEmpty {
                // Hide if I've seen it
                if item.watchedCount > 0 { return false }
                
                // Hide if Friends have seen it
                if excludedTMDBIDs.contains(item.tmdbId) { 
                    print("DEBUG: Hiding \(item.title) (ID: \(item.tmdbId)) because a friend saw it.")
                    return false 
                }
            }
            
            // If just doing a regular solo search, SHOW EVERYTHING so they can find their movie!
            return true
        }
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
                    
                    HStack(spacing: 6) {
                        // NEW: Watched Badge Logic
                        if item.watchedCount > 0 {
                             Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                        
                        // NEW: My List Badge Logic (Minimal Dot)
                        if item.isWatchlist {
                             Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                                .font(.caption)
                        }
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
