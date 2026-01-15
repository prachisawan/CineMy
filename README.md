# 🎬 CineMy

A beautifully crafted iOS movie & TV show companion app built with **SwiftUI** and **SwiftData**. Discover new content using natural language search, track your watch history, build watchlists, and sync with friends for perfect group movie nights.

![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)
![Platform](https://img.shields.io/badge/Platform-iOS%2017+-blue?style=flat-square&logo=apple)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple?style=flat-square)
![Firebase](https://img.shields.io/badge/Backend-Firebase-yellow?style=flat-square&logo=firebase)

---

## ✨ Features

### 🔍 Intelligent Search
Search movies and TV shows using **natural language queries** with no need for exact titles!
- `"Malayalam thriller movies rated above 8"`
- `"2023 horror films"`
- `"Korean drama TV shows"`

The app understands languages, genres, ratings, years, and content types to deliver exactly what you're looking for.

### 📊 Personal Tracking
- **Watchlist**: Save movies you want to watch later
- **Watch History**: Track what you've seen with watch counts
- **In Progress**: Mark content you're currently watching
- **User Ratings**: Rate movies on your own scale

### 👥 Group Watch (Social Sync)
Plan movie nights with friends without the hassle:
- Generate a unique **Friend Code** to share
- Add friends and sync watch histories via **Firebase**
- **Filter search results** to show only movies no one has seen
- Anonymous sync — no account creation required

### 🎥 Rich Movie Details
- High-quality poster images from TMDB
- **Trailer playback** with YouTube integration
- Full cast profiles with photos and character names
- **Streaming availability** — see where to watch (Netflix, Prime, etc.)
- Genre tags, ratings, and release information

---

## 📱 Screenshots

| Home | Search | Movie Details | Friends |
|:----:|:------:|:-------------:|:-------:|
| Browse your library | Natural language search | Full movie info | Watch Party sync |

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **SwiftUI** | Declarative UI framework |
| **SwiftData** | Local persistence & data modeling |
| **TMDB API** | Movie/TV metadata, posters, trailers |
| **Firebase Realtime DB** | Anonymous cross-device friend sync |
| **Async/Await** | Modern concurrency for network calls |

---

## 🏗️ Architecture

```
CineMy/
├── Models/
│   ├── EliteItem.swift        # Core movie/show model with SwiftData
│   └── Friend.swift           # Friend model for social sync
├── Views/
│   ├── HomeView.swift         # Main library browser
│   ├── SearchView.swift       # Natural language search
│   ├── MovieDetailView.swift  # Rich detail view with actions
│   ├── MyListView.swift       # Watchlist & history tabs
│   └── FriendsManagerView.swift # Watch Party management
├── ViewModels/
│   └── SearchViewModel.swift  # Search logic & state
├── Services/
│   ├── TMDBService.swift      # TMDB API integration
│   ├── FriendService.swift    # Firebase sync service
│   └── TMDBResponses.swift    # API response models
└── CineMyApp.swift            # App entry point
```

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ device or simulator
- TMDB API Key ([Get one free](https://www.themoviedb.org/settings/api))
- Firebase project (for social features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/prachisawan/CineMy.git
   cd CineMy
   ```

2. **Configure TMDB API Key**
   
   Open `CineMy/Services/TMDBService.swift` and replace the API key:
   ```swift
   private let apiKey = "YOUR_TMDB_API_KEY"
   ```

3. **Configure Firebase**
   - Create a project at [Firebase Console](https://console.firebase.google.com)
   - Download `GoogleService-Info.plist` and add to the project
   - Enable Realtime Database

4. **Build & Run**
   ```bash
   open CineMy.xcodeproj
   ```
   Press `Cmd + R` in Xcode to run on simulator or device.

---

## 📖 Usage

### Natural Language Search Examples

| Query | What it finds |
|-------|---------------|
| `Batman` | All Batman movies & shows |
| `Hindi comedy movies` | Bollywood comedies |
| `TV shows rated above 8.5` | Highly rated series |
| `2024 action films` | Recent action movies |
| `Malayalam thriller` | Regional thrillers |

### Group Watch Flow

1. Go to **Watch Party** tab
2. Tap **Generate My Code** to get your unique ID
3. Share your code with friends
4. Add friends using their codes
5. When searching, tap the **filter icon** to enable "Unwatched by friends"
6. Results will only show movies no one in your group has seen!

---

## 🎯 Key Highlights

- **100% SwiftUI** — No UIKit dependencies
- **Offline-first** — SwiftData persists all data locally
- **Privacy-focused** — Anonymous friend sync, no accounts
- **No ads** — Clean, distraction-free experience
- **Modern iOS** — Built for iOS 17+ with latest APIs

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs via Issues
- Suggest features
- Submit pull requests

---

## 📄 License

This project is available for personal and educational use.

---

## 🙏 Acknowledgments

- [TMDB](https://www.themoviedb.org/) for the comprehensive movie database API
- [Firebase](https://firebase.google.com/) for real-time sync capabilities
- Apple for SwiftUI and SwiftData frameworks

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/prachisawan">Prachi Sawan</a>
</p>
