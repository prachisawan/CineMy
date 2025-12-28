# Firebase Setup Guide for CineMy

Since you are switching to Firebase, follow these steps to get your backend ready.

## 1. Create Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com/).
2. Click **Add project**.
3. Name it `CineMy-Backend`.
4. Minimize Google Analytics (you don't strictly need it right now).
5. Click **Create Project**.

## 2. Add iOS App
1. In the project dashboard, click the **iOS icon** (circle with the Apple logo).
2. **Bundle ID**: Enter exactly: `com.cinemy.app` (or whatever is in your Xcode 'Signing' tab).
3. **App Nickname**: CineMy.
4. Click **Register app**.
5. **Download config file**: Download the `GoogleService-Info.plist`.
6. **Drag and Drop** this file into your Xcode project (put it near `Info.plist`). **Important**: Make sure "Copy items if needed" is checked.

## 3. Install SDKs (Swift Package Manager)
1. Open Xcode.
2. Go to **File > Add Package Dependencies...**
3. Paste: `https://github.com/firebase/firebase-ios-sdk`
4. Click **Add Package**.
5. When asked to choose libraries, select ONLY:
   - **FirebaseAuth**
   - **FirebaseFirestore**

## 4. Enable Anonymous Auth
1. Go back to Firebase Console.
2. Click **Build** -> **Authentication** in the sidebar.
3. Click **Get Started**.
4. Click the **Sign-in method** tab.
5. Click **Anonymous**.
6. Toggle **Enable** and click **Save**.

## 5. Create Firestore Database
1. Click **Build** -> **Firestore Database** in the sidebar.
2. Click **Create Database**.
3. Choose a Location (e.g., `us-central1` or whatever is closest).
4. **Security Rules**: Start in **Test Mode** (allow all reads/writes for 30 days). This is easiest for development.
   - *Later, we will lock this down, but strict rules interfere with testing right now.*
5. Click **Enable**.

## 6. Create Index (Optional but Recommended)
For simple queries like "Find user where code == 'PRA-99'", Firestore usually works automatically. If you see an error in the logs about an index, simply click the link in the error log to create one.

---
**Done!** Your backend is ready. Now the app code I provided will work.
