# 🚚 Driver Tracking & Delivery App

A production-ready, real-time driver tracking application built with Flutter. The app seamlessly tracks a driver's live location, speed, and route from the moment they accept a pickup until final delivery. It utilizes a **hybrid backend architecture**, leveraging Firebase for real-time data synchronization and Supabase for secure, scalable media storage.

## 📱 App Demo
[![App Demo](http://img.youtube.com/vi/U6gd7ME4Vng/0.jpg)](https://youtu.be/U6gd7ME4Vng)
*(Click the image above to watch the app in action)*

## 🌟 Key Features
- **Real-Time Background Tracking:** Continuous GPS tracking that persists even when the app is minimized or mobile is locked or internet is lost requiring "Allow     all the time" location permissions.
- **Smart Route Logging:** Automatically logs location coordinates, speed, battery level, and stoppage durations into a dedicated `driver_route_log` collection.
- **Hybrid Backend Integration:** 
  - 🔥 **Firebase:** Handles Authentication, real-time Firestore updates, and live trip state management.
  - 🟢 **Supabase:** Manages secure profile image uploads and storage.
- **State Management:** Clean, reactive UI updates powered by **GetX**.
- **Trip Summaries:** Generates a complete route history and delivery summary for admin/dashboard review.

## 🛠️ Tech Stack
| Category       | Technologies Used |
|----------------|-------------------|
| **Framework**  | Flutter (Dart) |
| **State Mgmt** | GetX |
| **Backend 1**  | Firebase (Auth, Firestore) |
| **Backend 2**  | Supabase (Storage) |
| **Device APIs**| Geolocator, Location Permissions, Battery Plus |
| **Utilities**  | `flutter_dotenv` for secure environment variable management |

## 🏗️ Technical Highlights
- **Secure Configuration:** Sensitive API keys and Firebase config files are strictly excluded from version control using `.gitignore` and managed locally via `.env`.
- **Optimized Media Uploads:** Profile images are uploaded directly to Supabase Storage buckets with unique user-UID file naming conventions to prevent collisions.
- **Resilient Location Tracking:** Implements robust error handling for GPS signal loss and background execution constraints on both Android and iOS.

## 🚀 Getting Started

*Since this repository excludes sensitive configuration files for security, follow these steps to run the project locally:*

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bipin912/driver_tracking_app.git
   cd driver_tracking_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Create a Firebase project and register Android/iOS apps.
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in their respective native directories.
   - Enable Email/Password Authentication and Firestore in the Firebase Console.

4. **Supabase Setup:**
   - Create a Supabase project and a storage bucket named `profiles`.
   - Create a `.env` file in the root directory and add your credentials:
     ```env
     SUPABASE_URL=your_supabase_project_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

5. **Run the app:**
   ```bash
   flutter run
   ```

## 📂 Project Structure
```text
lib/
 ├── core/          # Constants, themes, routes, and reusable widgets
 ├── data/          # Models, repositories, and Firebase/Supabase services
 ├── modules/       # Feature-based folders (auth, tracking, profile)
 └── main.dart      # App entry point and GetX initialization
```

## 🔮 Future Enhancements
- [ ] Implement Geofencing to automatically detect arrival at pickup/delivery zones.
- [ ] Add an offline mode that queues location data and syncs when the network is restored.
- [ ] Build a companion Web Admin Dashboard for real-time fleet monitoring.

---
*Built with ❤️ by [Bipin Xettri](https://github.com/bipin912)*
