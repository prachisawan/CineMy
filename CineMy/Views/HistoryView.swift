import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<EliteItem> { $0.watchedCount > 0 }, sort: \.lastWatched, order: .reverse)
    private var allWatchedItems: [EliteItem]
    
    // Toggle: 0 = Movies, 1 = TV Shows
    @State private var typeFilter: Int = 0
    // Edit Mode State
    @State private var isEditing = false
    
    // Filter items based on selection
    var filteredItems: [EliteItem] {
        let typeString = (typeFilter == 0) ? "movie" : "tv"
        return allWatchedItems.filter { $0.type == typeString }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Type Toggle (Custom Elite Segmented Control)
                EliteSegmentedControl(
                    options: ["Movies", "TV Shows"],
                    selectedIndex: $typeFilter
                )
                .padding()
                .padding(.bottom, 5) // Extra spacing below
                
                if filteredItems.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("No history yet. Start watching!")
                    )
                    .padding()
                    Spacer()
                } else {
                    List {
                        // 2. Dashboard Section
                        Section {
                            DashboardView(items: filteredItems)
                                .listRowInsets(EdgeInsets()) // Full width
                                .listRowBackground(Color.clear)
                        }
                        
                        // 3. The List
                        Section(header: 
                            HStack {
                                Text("Recent History")
                                Spacer()
                                Button(isEditing ? "Done" : "Edit") {
                                    withAnimation {
                                        isEditing.toggle()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            }
                        ) {
                            ForEach(filteredItems) { item in
                                ZStack {
                                    // Remove the custom red delete button to prevent double icons
                                    // System edit mode will handle the delete icon automatically
                                    HistoryRow(item: item)
                                    NavigationLink(destination: MovieDetailView(item: item)) { EmptyView() }.opacity(0)
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .onDelete(perform: deleteItems)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .navigationTitle("History")
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = filteredItems[index]
                item.watchedCount = 0
                item.lastWatched = nil
            }
        }
        Task { await syncChanges() }
    }
    
    @MainActor
    private func syncChanges() async {
        let descriptor = FetchDescriptor<EliteItem>(predicate: #Predicate { $0.watchedCount > 0 })
        if let watchedItems = try? modelContext.fetch(descriptor) {
            let ids = watchedItems.map { $0.tmdbId }
            await FriendService.shared.syncMyHistory(watchedIDs: ids)
        }
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
        .padding(.bottom, 10)
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
    @Bindable var item: EliteItem
    
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
            
            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                     Text(item.genre)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                }
                
                // NEW: Watched Date Label
                if let date = item.lastWatched {
                    Text("Watched on \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Interaction hint (chevron)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
