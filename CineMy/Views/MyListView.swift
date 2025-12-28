import SwiftUI
import SwiftData

struct MyListView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Toggle State: 0 = Watching, 1 = Watchlist
    @State private var selectedTab: Int = 0
    
    // 1. Currently Watching (In Progress)
    @Query(filter: #Predicate<EliteItem> { $0.isInProgress == true }, sort: \.title)
    private var watchingItems: [EliteItem]

    // 2. Watchlist (Saved but NOT In Progress)
    @Query(filter: #Predicate<EliteItem> { $0.isWatchlist == true && $0.isInProgress == false }, sort: \.title)
    private var watchlistItems: [EliteItem]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // TOGGLE BAR: Custom Elite Segmented Control
                EliteSegmentedControl(
                    options: ["Watching", "Watchlist"],
                    selectedIndex: $selectedTab
                )
                .padding()
                .padding(.bottom, 5) // Extra spacing below
                
                // THE LIST
                if currentItems.isEmpty {
                    ContentUnavailableView(
                        (selectedTab == 1) ? "Watchlist Empty" : "Not Watching Anything",
                        systemImage: (selectedTab == 1) ? "bookmark" : "play.slash",
                        description: Text((selectedTab == 1) ? "Add movies to your list to see them here." : "Start watching a movie to track it here.")
                    )
                } else {
                    List {
                        ForEach(currentItems) { item in
                            MyListCard(item: item, isWatching: (selectedTab == 0))
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My List")
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    // Computed property to get the correct list based on selection
    var currentItems: [EliteItem] {
        if selectedTab == 0 {
            return watchingItems
        } else {
            return watchlistItems
        }
    }
    
    // Actions
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = currentItems[index]
                if selectedTab == 1 {
                    // Removing from Watchlist
                    item.isWatchlist = false
                } else {
                    // Removing from Watching -> Just stop watching, don't delete from DB
                    item.isInProgress = false
                }
            }
        }
    }
}

// Helper Card View
struct MyListCard: View {
    let item: EliteItem
    let isWatching: Bool
    @State private var isCompleting = false
    
    var body: some View {
        ZStack {
             NavigationLink(destination: MovieDetailView(item: item)) { EmptyView() }.opacity(0)
             
             HStack(spacing: 12) {
                // Poster
                if let path = item.posterPath {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(path)")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 80, height: 120) // Bigger Poster
                    .cornerRadius(8)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 120) // Bigger Poster
                        .cornerRadius(8)
                        .overlay(Image(systemName: "film").foregroundStyle(.gray))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(item.releaseYear)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if isWatching {
                        Text("In Progress")
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                            .padding(.top, 4)
                    } else {
                        // Show Type for Watchlist items
                        Text(item.type.uppercased())
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Optional: Complete Button
                if isWatching {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCompleting = true
                        }
                        
                        // Delay to show success state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                item.isInProgress = false
                                item.watchedCount += 1
                                item.lastWatched = Date()
                            }
                            Task {
                                await FriendService.shared.syncMyHistory(watchedIDs: [item.tmdbId])
                            }
                        }
                    }) {
                        Text("Watched?")
                           .font(.caption.bold())
                           .padding(.horizontal, 12)
                           .padding(.vertical, 6)
                           .background(isCompleting ? Color.green : Color.clear)
                           .foregroundStyle(isCompleting ? .white : .green)
                           .clipShape(Capsule())
                           .overlay(
                               Capsule().stroke(Color.green, lineWidth: 1.5)
                           )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isCompleting)
                }
             }
             .padding(.vertical, 8) // Increased vertical padding
        }
        .listRowSeparator(.hidden)
    }
}
