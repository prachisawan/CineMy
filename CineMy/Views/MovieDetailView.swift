import SwiftUI
import SwiftData

struct MovieDetailView: View {
    @Bindable var item: EliteItem
    @Environment(\.modelContext) private var modelContext
    @State private var showToast = false
    @State private var isLoadingExtras = false
    
    // Service for separate fetching if needed, though we could use shared if static
    private let tmdbService = TMDBService()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Image with Trailer Overlay
                    if let path = item.posterPath {
                        ZStack(alignment: .center) {
                            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(path)")) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().foregroundStyle(.gray.opacity(0.3))
                                           .frame(height: 300)
                            }
                            .frame(height: 300)
                            .clipped()
                            
                            // Trailer Play Button Overlay
                            if let trailerUrl = item.trailerUrl, let url = URL(string: trailerUrl) {
                                Link(destination: url) {
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 60, height: 60)
                                            .shadow(radius: 10)
                                        
                                        Image(systemName: "play.fill")
                                            .font(.title)
                                            .foregroundStyle(.white)
                                            .offset(x: 2) // Optical adjustment
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title Area
                        Text(item.title)
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, -10) // Reduced gap
                        
                        // Metadata Row (Year • Rating • Genres) (Blue Genre Text)
                        HStack(spacing: 6) {
                            Text(item.releaseYear)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                                Text(String(format: "%.1f", item.rating))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            
                            Text("•")
                                .foregroundStyle(.secondary)
                                
                            // Genres in Blue
                            Text(item.genres.prefix(2).joined(separator: ", ").isEmpty ? item.genre : item.genres.prefix(2).joined(separator: ", "))
                                .font(.subheadline.bold())
                                .foregroundStyle(.blue)
                        }
                        
                        // Action Buttons
                        HStack(alignment: .top, spacing: 12) {
                            // Saved Button
                            Button(action: {
                                ensureItemIsSaved()
                                
                                let isAdding = !item.isWatchlist
                                withAnimation {
                                    item.isWatchlist.toggle()
                                }
                                
                                if isAdding {
                                    withAnimation { showToast = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { showToast = false }
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: item.isWatchlist ? "heart.fill" : "heart")
                                        .font(.system(size: 18, weight: .bold)) // Restored weight
                                    Text(item.isWatchlist ? "Saved" : "Save")
                                        .font(.caption.bold()) // Restored weight
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50) // Restored height
                                .padding(.vertical, 0)
                                .background(item.isWatchlist ? Color.pink : Color.pink.opacity(0.1))
                                .foregroundStyle(item.isWatchlist ? .white : .pink)
                                .cornerRadius(12) // Rounded
                            }

                            // Watch/Complete Button
                            VStack(spacing: 4) {
                                Button(action: {
                                    ensureItemIsSaved()
                                    withAnimation {
                                        if item.isInProgress {
                                            item.isInProgress = false
                                            item.watchedCount += 1
                                            item.lastWatched = Date()
                                            Task { await syncAfterWatch() }
                                        } else {
                                            item.isInProgress = true
                                            if item.isWatchlist { item.isWatchlist = false }
                                        }
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: item.isInProgress ? "checkmark" : "play.fill")
                                            .font(.system(size: 18, weight: .bold)) // Restored weight
                                        Text(item.isInProgress ? "Mark as Watched" : "Start Watching")
                                            .font(.caption.bold()) // Restored weight
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50) // Restored height
                                    .padding(.vertical, 0)
                                    .background(item.isInProgress ? Color.green : Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12) // Rounded
                                }
                                
                                if item.watchedCount > 0 {
                                    Text("Watched \(item.watchedCount)x")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        

                        
                        // WHERE TO WATCH (Accessible Row)
                        if !item.watchProviders.isEmpty {
                            HStack(alignment: .center, spacing: 12) {
                                Text("Stream on:")
                                    .font(.subheadline) // Increased size
                                    .foregroundStyle(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(item.watchProviders, id: \.name) { provider in
                                            if let url = URL(string: "https://image.tmdb.org/t/p/original\(provider.logoUrl)") {
                                                AsyncImage(url: url) { image in
                                                    image.resizable()
                                                } placeholder: {
                                                    Color.gray.opacity(0.3)
                                                }
                                                .frame(width: 40, height: 40) // Increased size
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        Divider()
                            .padding(.top, 4)
                        
                        Text("About")
                            .font(.headline)
                        Text(item.overview)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2) // Tighter spacing
                        
                        // 3. TOP CAST
                        if !item.castMembers.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top Cast")
                                    .font(.headline)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(item.castMembers, id: \.name) { member in
                                            VStack(spacing: 8) {
                                                if let path = member.photoUrl, let url = URL(string: "https://image.tmdb.org/t/p/w200\(path)") {
                                                    AsyncImage(url: url) { image in
                                                        image.resizable().aspectRatio(contentMode: .fill)
                                                    } placeholder: {
                                                        Color.gray.opacity(0.3)
                                                    }
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(Circle())
                                                } else {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 80, height: 80)
                                                        .overlay(Text(String(member.name.prefix(1))).bold())
                                                }
                                                
                                                VStack(spacing: 2) {
                                                    Text(member.name)
                                                        .font(.caption)
                                                        .bold()
                                                        .multilineTextAlignment(.center)
                                                        .lineLimit(2)
                                                    
                                                    Text(member.character)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                        .multilineTextAlignment(.center)
                                                        .lineLimit(1)
                                                }
                                                .frame(width: 90)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 50) // Bottom spacing
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
        .task {
            // Fetch extended data whenever this view appears
            if item.genres.count <= 1 || item.castMembers.isEmpty {
                isLoadingExtras = true
                await tmdbService.fetchExtendedData(for: item)
                isLoadingExtras = false
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
