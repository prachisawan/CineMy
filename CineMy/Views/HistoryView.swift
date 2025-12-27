import SwiftUI
import SwiftData

struct HistoryView: View {
    // query items where watchedCount is > 0
    @Query(filter: #Predicate<EliteItem> { $0.watchedCount > 0 }, sort: \.title)
    private var watchedItems: [EliteItem]

    var body: some View {
        NavigationStack {
            Group {
                if watchedItems.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Mark movies as watched to see them here.")
                    )
                } else {
                    List {
                        ForEach(watchedItems) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.headline)
                                    Text("Watched \(item.watchedCount) time(s)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(item.type == "movie" ? "Movie" : "Show")
                                    .font(.caption2)
                                    .padding(5)
                                    .background(.quaternary)
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}
