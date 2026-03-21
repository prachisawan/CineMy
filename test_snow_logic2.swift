import Foundation

let query = "society of snow"
let wordsToRemove = ["about", "of", "for", "from", "with", "in", "on"]
var remaining = query.lowercased()

func removeWords(from text: String, words: [String]) -> String {
    var newText = text
    for word in words {
        newText = newText.replacingOccurrences(of: "\\b\(word)\\b", with: "", options: .regularExpression)
    }
    return newText
}

let cleaned = removeWords(from: remaining, words: wordsToRemove).trimmingCharacters(in: .whitespacesAndNewlines)
print("Cleaned text:", cleaned)
