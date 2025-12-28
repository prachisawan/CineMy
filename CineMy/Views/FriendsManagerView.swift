import SwiftUI
import SwiftData

struct FriendsManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var friends: [Friend]
    @Query(filter: #Predicate<EliteItem> { $0.watchedCount > 0 }) private var myWatched: [EliteItem]
    
    // Switch to Firebase Service
    @StateObject private var fbService = FriendService.shared
    
    @State private var newFriendCode: String = ""
    @State private var newFriendName: String = ""
    @State private var isAdding: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                // SECTION 1: MY IDENTITY
                Section(header: Text("My Identity")) {
                    if let code = fbService.myCode {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Friend Code")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Text(code)
                                    .font(.system(.title, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Button(action: {
                                    UIPasteboard.general.string = code
                                }) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            HStack {
                                Text("\(myWatched.count) movies synced")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if fbService.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Button("Sync Now") {
                                        Task {
                                            let ids = myWatched.map { $0.tmdbId }
                                            await fbService.syncMyHistory(watchedIDs: ids)
                                        }
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    } else {
                        Button("Generate My Code") {
                            Task {
                                await fbService.initializeSession(userName: UIDevice.current.name)
                            }
                        }
                    }
                }
                
                // SECTION 2: FRIENDS LIST
                Section(header: Text("My Friends")) {
                    ForEach(friends) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.nickname)
                                    .font(.headline)
                                Text(friend.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                if friend.watchedCount > 0 {
                                    Text("\(friend.watchedCount) items")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(4)
                                } else {
                                    Text("Unverified")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                
                                Text("Synced just now")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                modelContext.delete(friend)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                refreshFriend(friend)
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            .tint(.blue)
                        }
                    }
                    
                    if isAdding {
                        VStack(spacing: 12) {
                            TextField("Friend Code (e.g. ALI-928)", text: $newFriendCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.allCharacters)
                            
                            TextField("Nickname (e.g. Alice)", text: $newFriendName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            HStack {
                                Button("Cancel") { isAdding = false; errorMessage = nil }
                                    .foregroundColor(.red)
                                Spacer()
                                Button("Verify & Add") {
                                    verifyAndAddFriend()
                                }
                                .disabled(newFriendCode.isEmpty || newFriendName.isEmpty)
                            }
                        }
                        .padding(.vertical)
                    } else {
                        Button(action: { isAdding = true }) {
                            Label("Add Friend", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                }
                
                Section(footer: Text("Syncing happens anonymously via secure cloud database. No account creation required.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Watch Party")
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    private func verifyAndAddFriend() {
        guard !newFriendCode.isEmpty, !newFriendName.isEmpty else { return }
        errorMessage = nil
        
        Task {
            do {
                let (count, list) = try await fbService.fetchFriend(code: newFriendCode)
                
                await MainActor.run {
                    // Create Friend
                    let friend = Friend(code: newFriendCode, nickname: newFriendName, watchedCount: count, watchedMovies: list)
                    modelContext.insert(friend)
                    
                    // Reset UI
                    newFriendCode = ""
                    newFriendName = ""
                    isAdding = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Code not found. Ask friend to tap 'Sync Now'."
                }
            }
        }
    }
    
    private func refreshFriend(_ friend: Friend) {
        Task {
            do {
                let (count, list) = try await fbService.fetchFriend(code: friend.code)
                friend.watchedCount = count
                friend.watchedMovies = list
                friend.lastUpdated = Date()
            } catch {
                print("Failed to refresh friend")
            }
        }
    }
}
