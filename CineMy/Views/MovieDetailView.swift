import SwiftUI
import SwiftData

struct MovieDetailView: View {
    @Bindable var item: EliteItem
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                if let path = item.posterPath {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(path)")) { image in
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().foregroundStyle(.gray.opacity(0.3))
                                   .frame(height: 300)
                    }
                    .frame(height: 300)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // Title Area (Unchanged)
                    Text(item.title)
                        .font(.largeTitle)
                        .bold()
                    
                    HStack {
                         Text(item.releaseYear)
                            .padding(6)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                        
                        Text(item.type.uppercased())
                            .padding(6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .cornerRadius(8)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                            Text(String(format: "%.1f", item.rating))
                        }
                    }
                    .font(.caption.bold())
                    
                    // Action Buttons - Single Row Layout as requested
                    HStack(spacing: 12) {
                        // 1. My List Button (Heart Icon)
                        Button(action: {
                            ensureItemIsSaved()
                            withAnimation {
                                item.isWatchlist.toggle()
                            }
                        }) {
                            VStack {
                                Image(systemName: item.isWatchlist ? "heart.fill" : "heart")
                                Text(item.isWatchlist ? "Saved" : "Save")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(item.isWatchlist ? Color.pink : Color.pink.opacity(0.1))
                            .foregroundStyle(item.isWatchlist ? .white : .pink)
                            .cornerRadius(12)
                        }

                        // 2. Mark as Watched
                        Button(action: {
                            ensureItemIsSaved()
                            withAnimation {
                                if item.watchedCount > 0 {
                                    item.watchedCount = 0
                                    item.lastWatched = nil
                                } else {
                                    item.watchedCount = 1
                                    item.isInProgress = false
                                    item.lastWatched = Date()
                                }
                            }
                            Task { await syncAfterWatch() }
                        }) {
                            VStack {
                                Image(systemName: item.watchedCount > 0 ? "checkmark.circle.fill" : "checkmark")
                                Text(item.watchedCount > 0 ? "Watched" : "Done")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(item.watchedCount > 0 ? Color.green : Color.green.opacity(0.1))
                            .foregroundStyle(item.watchedCount > 0 ? .white : .green)
                            .cornerRadius(12)
                        }
                        
                        // 3. Watching Now (Small Button Style)
                        Button(action: {
                            ensureItemIsSaved()
                            withAnimation {
                                item.isInProgress.toggle()
                            }
                        }) {
                            VStack {
                                Image(systemName: item.isInProgress ? "pause.fill" : "play.fill")
                                Text(item.isInProgress ? "On Now" : "Now")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(item.isInProgress ? Color.orange : Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Status Text
                    if item.watchedCount > 0 {
                        Text("You have watched this \(item.watchedCount) time(s).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    Text("About")
                        .font(.headline)
                    Text(item.overview)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    private func ensureItemIsSaved() {
        if item.modelContext == nil {
            modelContext.insert(item)
            try? modelContext.save()
            print("Item saved to database: \(item.title)")
        }
    }
    
    @MainActor
    private func syncAfterWatch() async {
        let descriptor = FetchDescriptor<EliteItem>(predicate: #Predicate { $0.watchedCount > 0 })
        if let watchedItems = try? modelContext.fetch(descriptor) {
            let ids = watchedItems.map { $0.tmdbId }
            await FriendService.shared.syncMyHistory(watchedIDs: ids)
        }
    }
}
