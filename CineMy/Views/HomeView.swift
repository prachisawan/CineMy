import SwiftUI
import SwiftData

struct HomeView: View {
    // The parent only manages the SELECTION state
    @State private var selectedType: String = "movie"

    var body: some View {
        NavigationStack {
            VStack {
                // The "Movies / TV Shows" Toggle
                Picker("Type", selection: $selectedType) {
                    Text("Movies").tag("movie")
                    Text("TV Shows").tag("tv")
                }
                .pickerStyle(.segmented)
                .padding()
                
                // We pass the selection to a sub-view.
                // This forces the query to refresh cleanly without the "immutable" error.
                MovieListView(type: selectedType)
            }
            .navigationTitle("CineMy")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {}) {
                        Label("Newest", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

// MARK: - The List Sub-View (Handles the Database Query)
struct MovieListView: View {
    @Query private var items: [EliteItem]
    
    // The Init is where the magic happens.
    // It accepts the 'type' and builds a fresh Query for it.
    init(type: String) {
        let predicate = #Predicate<EliteItem> { $0.type == type }
        _items = Query(filter: predicate, sort: \.releaseYear, order: .reverse)
    }
    
    var body: some View {
        if items.isEmpty {
            ContentUnavailableView(
                "No Content",
                systemImage: "popcorn",
                description: Text("No items found in this category.")
            )
        } else {
            List(items) { item in
                ZStack {
                    MovieCard(item: item)
                    
                    NavigationLink(destination: MovieDetailView(item: item)) {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - The Card Design (Unchanged)
struct MovieCard: View {
    let item: EliteItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Title, Year, and Rating Badge
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(item.releaseYear)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Rating Badge
                Text(String(format: "%.1f", item.rating))
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ratingColor(item.rating).opacity(0.15))
                    .foregroundStyle(ratingColor(item.rating))
                    .clipShape(Capsule())
            }
            
            Divider()
            
            // Row 2: Footer with Director and Eye Icon
            HStack {
                Label(item.director, systemImage: "movieclapper")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                if item.watchedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                        Text("\(item.watchedCount)")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    func ratingColor(_ rating: Double) -> Color {
        switch rating {
        case 8.0...: return .green
        case 6.0..<8.0: return .orange
        default: return .gray
        }
    }
}
