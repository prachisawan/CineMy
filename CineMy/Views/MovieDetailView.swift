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
                    // Title Area
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
                    
                    // Action Buttons
                    HStack(spacing: 15) {
                        // 1. Toggle "In Progress"
                        Button(action: {
                            ensureItemIsSaved()
                            withAnimation {
                                item.isInProgress.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: item.isInProgress ? "pause.fill" : "play.fill")
                                Text(item.isInProgress ? "Watching Now" : "Start Watching")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(item.isInProgress ? Color.orange : Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        
                        // 2. Mark as Finished (Increments count, clears progress)
                        Button(action: {
                            ensureItemIsSaved()
                            item.watchedCount += 1
                            item.isInProgress = false
                        }) {
                            VStack {
                                Image(systemName: "checkmark")
                                Text("Done")
                            }
                            .frame(width: 60)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
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
}
