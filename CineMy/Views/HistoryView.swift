import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(filter: #Predicate<EliteItem> { $0.watchedCount > 0 }, sort: \.title)
    private var allWatchedItems: [EliteItem]
    
    // Toggle: 0 = Movies, 1 = TV Shows
    @State private var typeFilter: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Type Toggle
                Picker("Type", selection: $typeFilter) {
                    Text("Movies").tag(0)
                    Text("TV Shows").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if filteredItems.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Mark \(typeFilter == 0 ? "movies" : "shows") as watched.")
                    )
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 2. Dashboard Section
                            DashboardView(items: filteredItems)
                            
                            // 3. The List
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recent History")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredItems) { item in
                                        HistoryRow(item: item)
                                        Divider().padding(.leading)
                                    }
                                }
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .navigationTitle("History")
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    // Filter items based on selection
    var filteredItems: [EliteItem] {
        let typeString = (typeFilter == 0) ? "movie" : "tv"
        return allWatchedItems.filter { $0.type == typeString }
    }
}

// MARK: - Dashboard Card
struct DashboardView: View {
    let items: [EliteItem]
    
    var thisMonthCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return items.filter { item in
            guard let date = item.lastWatched else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }
    
    var thisYearCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return items.filter { item in
            guard let date = item.lastWatched else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }.count
    }
    
    var topGenres: [(key: String, value: Int)] {
        var counts: [String: Int] = [:]
        for item in items {
            counts[item.genre, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Row 1: Activity Stats
            HStack(spacing: 15) {
                StatCard(title: "This Month", value: "\(thisMonthCount)", icon: "calendar")
                StatCard(title: "This Year", value: "\(thisYearCount)", icon: "flag.fill")
            }
            
            // Row 2: Taste (Genre Breakdown)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.pie.fill").foregroundStyle(.purple)
                    Text("Top Taste")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                if topGenres.isEmpty {
                    Text("Watch more to see stats!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(topGenres, id: \.key) { genre, count in
                        HStack {
                            Text(genre).font(.system(.body, design: .rounded)).bold()
                            Spacer()
                            Text("\(count)").foregroundStyle(.secondary)
                        }
                        if genre != topGenres.last?.key {
                            Divider()
                        }
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).foregroundStyle(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(.title, design: .rounded))
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct HistoryRow: View {
    let item: EliteItem
    
    var body: some View {
        HStack(spacing: 15) {
            // Poster
            if let path = item.posterPath {
                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(path)")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 75)
                .cornerRadius(8)
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 75)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                HStack {
                     Text(item.genre)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    
                    Text("Watched: \(item.watchedCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
    }
}
