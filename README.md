# 🌱 EcoScan — AI Waste Sorting Gamification App

EcoScan is a mobile application that helps users correctly dispose of waste by using AI-powered image recognition.  
Users simply take a photo of an item, and EcoScan tells them **which bin to use**, while rewarding eco-friendly behavior through **points and leaderboards**.

---

## 🎯 Target Sustainable Development Goals (SDGs)
- **SDG #12** – Responsible Consumption and Production  
- **SDG #13** – Climate Action  

---

## 🚨 Problem
Incorrect waste disposal is a major environmental issue.  
People often don’t know which bin to use, leading to **recycling contamination** and increased landfill waste.

---

## ✨ Features

- 📸 **Snap & Sort** – Take a photo of waste and get instant bin recommendations  
- 🧠 **AI Waste Classification** – Powered by Gemini Pro Vision  
- 🎮 **Gamification** – Earn points and unlock achievements  
- 🏆 **Global Leaderboard** – Compete with users worldwide  
- 🗺️ **Recycling Center Locator** – Find nearby recycling facilities  

---

## 🏗️ Architecture Overview

- **Frontend:** Built with Flutter, utilizing Riverpod (v3.2.1) for scalable state management and dependency injection.
- **Authentication:** Managed via Firebase Auth with support for Google Sign-In.
- **Backend:** Stores user profiles, points, and global leaderboard data.
- **Storage:** Handles temporary or permanent storage of waste images for verification.
- **AI Engine:** via the google_generative_ai package, processing images directly from the device to identify materials and bin types.
- **Maps:** Google Maps SDK integrated with geolocator to help users find the nearest recycling centers.

---

## 🛠️ Tech Stack

| Layer | Technology |
|------|-----------|
| Mobile | Flutter |
| State Management | Riverpod |
| Auth | Firebase Auth |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| AI | Gemini 2.5 Vision |
| Maps | Google Maps SDK |

---

---

##  🚀 Installation & Setup
### Prerequisite
### Make sure you have the following installed:
- Flutter SDK
- Git
- A code editor (VS Code recommended)
- Android Emulator or physical device

### Clone the Repository
```
git clone https://github.com/SNFASA/EcoScan.git
cd EcoScan
 ````

### Install Dependencies
```
git clone https://github.com/SNFASA/EcoScan.git
cd EcoScan
 ````

### Run the App
```
flutter run
 ````

---

## 🔐 Environment Configuration (Optional)

 Some features (AI scanning, leaderboard) may require environment variables.
 Create a .env file (if required) and do not commit it:
### 1. Firebase Configuration
  Instead of committing sensitive files, generate your own configuration:
  1. Create a project on the Firebase Console.
  2. Run flutterfire configure to generate lib/firebase_options.dart.
  3. Download google-services.json (Android) and GoogleService-Info.plist (iOS) and place them       in their respective app and Runner folders.
### 2. Web & Maps Setup (web/index.html)
If running on the web, add your API key placeholder in the <head> section:
```
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>
 ```

### Gemini API
```
GEMINI_API_KEY=your_api_key_here
```
### Google Maps API
```
GOOGLE_PLACES_API_KEY=your_api_key_here
```
 ### SMTP configuration
```
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=465
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=ssl
MAIL_FROM_ADDRESS=
MAIL_FROM_NAME="ecoscan"
```
---

## 🗺️ Future Roadmap 
[ ] Multi-Object Detection: Update the AI pipeline to identify and sort multiple waste items in a single camera frame.

[ ] Municipal Integration: Sync with local government waste schedules to provide real-time "pickup day" notifications.

[ ] Offline Mode: Implement a lightweight on-device TFLite model for basic sorting when internet access is unavailable.

[ ] AR Bin Overlay: Use Augmented Reality to project the correct bin type directly over the item in the camera view.

---

## 🚧 Challenges Faced 
1. API Latency & Cost: Calling high-level LLMs for every scan introduces latency and operational costs. We implemented image compression and are investigating local caching for common items to minimize unnecessary API calls.
2. Prompt Engineering: Ensuring the AI consistently returns valid JSON format (without markdown backticks) required rigorous prompt iteration and validation logic.
3. Environmental Factors: Initial tests showed that low lighting or "busy" backgrounds reduced AI confidence. We implemented a Confidence Score UI to inform users when a better photo is needed.
4. State Synchronization: Keeping the global leaderboard in sync across multiple devices while maintaining low read counts in Firestore to optimize performance and cost.


