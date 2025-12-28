import SwiftUI
import SwiftData

struct MovieDetailView: View {
    @Bindable var item: EliteItem
    @Environment(\.modelContext) private var modelContext
    @State private var showToast = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
                        
                        // Action Buttons - Refactored 2-Button Layout
                        HStack(alignment: .top, spacing: 12) {
                            // 1. Saved Button (Left) - Unchanged
                            Button(action: {
                                ensureItemIsSaved()
                                
                                let isAdding = !item.isWatchlist
                                withAnimation {
                                    item.isWatchlist.toggle()
                                }
                                
                                if isAdding {
                                    withAnimation {
                                        showToast = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            showToast = false
                                        }
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: item.isWatchlist ? "heart.fill" : "heart")
                                    Text(item.isWatchlist ? "Saved" : "Save")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50) // Fixed height
                                .padding(.vertical, 4)
                                .background(item.isWatchlist ? Color.pink : Color.pink.opacity(0.1))
                                .foregroundStyle(item.isWatchlist ? .white : .pink)
                                .cornerRadius(12)
                            }

                            // 2. Dynamic Action Button (Right) & Counter
                            VStack(spacing: 8) {
                                Button(action: {
                                    ensureItemIsSaved()
                                    withAnimation {
                                        if item.isInProgress {
                                            // Complete Action: Move to History
                                            item.isInProgress = false
                                            item.watchedCount += 1
                                            item.lastWatched = Date()
                                            Task { await syncAfterWatch() }
                                        } else {
                                            // Active Action: Move to Watching
                                            item.isInProgress = true
                                            
                                            // Fix: If starting to watch, remove from Watchlist if it was there
                                            if item.isWatchlist {
                                                item.isWatchlist = false
                                            }
                                        }
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: item.isInProgress ? "checkmark" : "play.fill")
                                        Text(item.isInProgress ? "Mark as Watched" : "Start Watching")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50) // Fixed height
                                    .padding(.vertical, 4)
                                    .background(item.isInProgress ? Color.green : Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                                }
                                
                                // History Counter (Below Button 2)
                                if item.watchedCount > 0 {
                                    Text("You have watched this \(item.watchedCount) time(s).")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
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
            
            // Toast Overlay
            if showToast {
                Text("Added to Watchlist")
                    .font(.caption.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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
