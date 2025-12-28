import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            MyListView()
                .tabItem {
                    Label("My List", systemImage: "bookmark")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            FriendsManagerView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
        }
    }
}
