import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class FriendService: ObservableObject {
    static let shared = FriendService()
    
    private let db = Firestore.firestore()
    
    @Published var myCode: String?
    @Published var isSyncing: Bool = false
    @Published var error: String?
    
    // Local persistence key
    private let kMyCodeKey = "MyFirebaseFriendCode"
    
    init() {
        self.myCode = UserDefaults.standard.string(forKey: kMyCodeKey)
    }
    
    // MARK: - Identity & Auth
    
    /// Ensures the user is anonymously logged in and has a unique "Friend Code".
    func initializeSession(userName: String) async {
        // 1. Check Auth (Sign in silently if needed)
        if Auth.auth().currentUser == nil {
            do {
                try await Auth.auth().signInAnonymously()
                #if DEBUG
                print("DEBUG: Signed in anonymously with UID: \(Auth.auth().currentUser?.uid ?? "unknown")")
                #endif
            } catch {
                await MainActor.run { self.error = "Auth Error: \(error.localizedDescription)" }
                return
            }
        }
        
        // 2. Generate Code only if we don't have one
        if myCode == nil {
            await createUniqueCode(userName: userName)
        }
    }
    
    private func createUniqueCode(userName: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Generate a fun, short code: "ALI-928"
        let cleanName = userName.prefix(3).uppercased().filter { $0.isLetter }
        let prefix = cleanName.isEmpty ? "USR" : cleanName
        let randomNum = Int.random(in: 100...999)
        let candidateCode = "\(prefix)-\(randomNum)"
        
        let docRef = db.collection("users").document(uid)
        
        // Data to save
        let userData: [String: Any] = [
            "friendCode": candidateCode,
            "uid": uid,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        do {
            // Merge: true means we update the code/uid without deleting existing watched history if mostly likely
            try await docRef.setData(userData, merge: true)
            
            await MainActor.run {
                self.myCode = candidateCode
                UserDefaults.standard.set(candidateCode, forKey: kMyCodeKey)
            }
        } catch {
            await MainActor.run { self.error = "Setup Error: \(error.localizedDescription)" }
        }
    }
    
    // MARK: - Syncing History
    
    func syncMyHistory(watchedIDs: [Int]) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run { self.isSyncing = true }
        
        let listData: [String: Any] = [
            "watchedMovieIds": watchedIDs,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection("users").document(uid).setData(listData, merge: true)
        } catch {
            print("Sync Error: \(error.localizedDescription)")
        }
        
        await MainActor.run { self.isSyncing = false }
    }
    
    // MARK: - Fetching Friends
    
    /// Finds a user by their Friend Code and returns their watched list
    func fetchFriend(code: String) async throws -> (count: Int, list: [Int]) {
        // Query the "users" collection where "friendCode" == code
        let querySnapshot = try await db.collection("users")
            .whereField("friendCode", isEqualTo: code.uppercased())
            .getDocuments()
        
        guard let doc = querySnapshot.documents.first else {
            throw NSError(domain: "App", code: 404, userInfo: [NSLocalizedDescriptionKey: "Friend code not found"])
        }
        
        let data = doc.data()
        if let watchedList = data["watchedMovieIds"] as? [Int] {
            return (watchedList.count, watchedList)
        }
        
        return (0, [])
    }
}
