import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<EliteItem> { $0.watchedCount > 0 }, sort: \.lastWatched, order: .reverse)
    private var allWatchedItems: [EliteItem]
    
    // Toggle: 0 = Movies, 1 = TV Shows
    @State private var typeFilter: Int = 0
    // Edit Mode State
    @State private var isEditing = false
    
    // Rating Sheet State
    @State private var itemToRate: EliteItem?
    
    // Genre Filter
    @State private var selectedGenre: String? = nil
    
    // Base items (Movies vs TV)
    var baseItems: [EliteItem] {
        let typeString = (typeFilter == 0) ? "movie" : "tv"
        return allWatchedItems.filter { $0.type == typeString }
    }
    
    // Filtered by Genre
    var displayItems: [EliteItem] {
        if let genre = selectedGenre {
            return baseItems.filter { $0.genre == genre }
        }
        return baseItems
    }
    
    // Grouping by Month/Year
    struct HistorySectionData: Identifiable {
        let id = UUID()
        let date: Date
        let title: String
        let items: [EliteItem]
    }
    
    var groupedSections: [HistorySectionData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: displayItems) { item -> Date in
            guard let date = item.lastWatched else { return Date.distantPast }
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? Date.distantPast
        }
        
        return grouped.keys.sorted(by: >).map { date in
            let items = grouped[date]!
                .sorted { ($0.lastWatched ?? .distantPast) > ($1.lastWatched ?? .distantPast) }
            let title = date.formatted(.dateTime.month(.wide).year())
            return HistorySectionData(date: date, title: title, items: items)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Type Toggle
                EliteSegmentedControl(
                    options: ["Movies", "TV Shows"],
                    selectedIndex: $typeFilter
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if baseItems.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("No history yet. Start watching!")
                    )
                    Spacer()
                } else {
                    List {
                        // 2. Dashboard Section (Compact)
                        Section {
                            VStack(spacing: 12) {
                                // A. Stats Row (Compact)
                                StatRow(items: baseItems)
                                
                                // B. Donut Chart (Compact & Interactive)
                                DashboardChart(items: baseItems, selectedGenre: $selectedGenre)
                            }
                            .listRowInsets(EdgeInsets()) // Full width to edges
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 4)
                        }
                        
                        // 3. Grouped History Lists
                        if displayItems.isEmpty {
                            ContentUnavailableView {
                                Label("No movies found", systemImage: "magnifyingglass")
                            } description: {
                                Text("No items match the genre \"\(selectedGenre ?? "")\".")
                            }
                        } else {
                            ForEach(groupedSections) { section in
                                Section(header: 
                                    Text(section.title)
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundStyle(.secondary)
                                        .padding(.vertical, 4)
                                ) {
                                    ForEach(section.items) { item in
                                        ZStack {
                                            HistoryRow(item: item, onRate: {
                                                itemToRate = item
                                            })
                                            NavigationLink(destination: MovieDetailView(item: item)) { EmptyView() }.opacity(0)
                                        }
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                    .onDelete { indexSet in
                                        deleteItems(at: indexSet, in: section)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .sheet(item: $itemToRate) { item in
                RatingSheet(item: item)
                    .presentationDetents([.fraction(0.3)])
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet, in section: HistorySectionData) {
        withAnimation {
            for index in offsets {
                let item = section.items[index]
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

// MARK: - Compact Stats Row
struct StatRow: View {
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
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(title: "This Month", value: "\(thisMonthCount)", icon: "calendar")
            StatCard(title: "This Year", value: "\(thisYearCount)", icon: "flag.fill")
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.system(.title3, design: .rounded))
                    .bold()
            }
            Spacer()
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue.opacity(0.8))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

// MARK: - Filterable Dashboard Chart
struct DashboardChart: View {
    let items: [EliteItem]
    @Binding var selectedGenre: String?
    
    struct GenreData: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
        let percentage: Int
        let color: Color
    }
    
    var chartData: [GenreData] {
        var counts: [String: Int] = [:]
        for item in items {
            counts[item.genre, default: 0] += 1
        }
        
        let total = Double(items.count)
        guard total > 0 else { return [] }
        
        let sorted = counts.sorted { $0.value > $1.value }
        let topGenres = sorted.prefix(5)
        let othersCount = sorted.dropFirst(5).map(\.value).reduce(0, +)
        
        var data: [GenreData] = []
        let colors: [Color] = [.purple, .blue, .orange, .pink, .green, .cyan, .indigo]
        
        for (index, element) in topGenres.enumerated() {
            let percentage = Int((Double(element.value) / total) * 100)
            data.append(GenreData(name: element.key, count: element.value, percentage: percentage, color: colors[index % colors.count]))
        }
        
        if othersCount > 0 {
            let percentage = Int((Double(othersCount) / total) * 100)
            data.append(GenreData(name: "Others", count: othersCount, percentage: percentage, color: .gray.opacity(0.5)))
        }
        
        return data
    }
    
    var useSmallFonts: Bool {
        chartData.count > 4
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Chart Area
            ZStack {
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.65), // Slightly thinner ring
                        angularInset: 0
                    )
                    .cornerRadius(0)
                    .foregroundStyle(item.color.opacity(
                        selectedGenre == nil || selectedGenre == item.name ? 1.0 : 0.3
                    ))
                }
                .frame(width: 120, height: 120) // Smaller chart
                
                VStack(spacing: 0) {
                    Text("\(items.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Interactive Legend
            VStack(alignment: .leading, spacing: 8) {
                // "All" option (only visible if filtered)
                if selectedGenre != nil {
                    Button(action: {
                        withAnimation { selectedGenre = nil }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                            Text("Clear Filter")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 4)
                }

                ForEach(chartData) { item in
                    Button(action: {
                        withAnimation {
                            if selectedGenre == item.name {
                                selectedGenre = nil
                            } else {
                                selectedGenre = item.name
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            
                            Text(item.name)
                                .font(useSmallFonts ? .caption : .subheadline)
                                .foregroundStyle(selectedGenre == item.name ? .primary : .primary)
                                .fontWeight(selectedGenre == item.name ? .bold : .regular)
                            
                            Spacer()
                            
                            Text("\(item.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle()) // Make full row tappable
                        .opacity(selectedGenre == nil || selectedGenre == item.name ? 1.0 : 0.4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}


// MARK: - Rating Sheet
struct RatingSheet: View {
    @Bindable var item: EliteItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rate \"\(item.title)\"")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
                .padding(.top, 24)
            
            VStack(spacing: 10) {
                Text("\(item.userRating)/10")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                
                Slider(value: Binding(get: {
                    Double(item.userRating == 0 ? 5 : item.userRating)
                }, set: { newValue in
                    withAnimation {
                        item.userRating = Int(newValue)
                    }
                }), in: 1...10, step: 1)
                .tint(.blue)
                
                Text(ratingDescription(item.userRating))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .presentationCornerRadius(24)
    }
    
    func ratingDescription(_ score: Int) -> String {
        switch score {
        case 0: return "Not Rated"
        case 1...3: return "Bad"
        case 4...6: return "Okay"
        case 7...8: return "Good"
        case 9...10: return "Masterpiece"
        default: return ""
        }
    }
}

// MARK: - Compact History Row (No Date in Row)
struct HistoryRow: View {
    @Bindable var item: EliteItem
    var onRate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Poster (Slightly smaller)
            if let path = item.posterPath {
                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(path)")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 44, height: 66)
                .cornerRadius(6)
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 66)
                    .cornerRadius(6)
            }
            
            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(.body, weight: .medium))
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
                
                // RATING ROW
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)
                    
                    Text("\(String(format: "%.1f", item.rating))")
                        .font(.caption)
                        .bold()
                    
                    Text("/")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Button(action: onRate) {
                        if item.userRating > 0 {
                            Text("Your Score: \(item.userRating)")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        } else {
                            Text("Rate This ☆")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            // Interaction hint
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(10) // Reduced padding
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}
