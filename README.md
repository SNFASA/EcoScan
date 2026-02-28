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

## 💡 Solution
EcoScan introduces a **“Snap & Sort”** experience:
1. 📸 User takes a photo of waste
2. 🤖 AI identifies the item and material
3. 🗑️ App recommends the correct bin
4. 🏆 User earns points for correct sorting
5. 📊 Leaderboards motivate sustainable habits

---

## ✨ Key Features (MVP)
- Image-based waste identification
- Clear bin recommendations
- Confidence score for AI predictions
- Gamified points system
- Global leaderboard
- Clean and intuitive UI

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** (Android & iOS)

### AI
- **Gemini Pro Vision**
```json
{
  "item": "plastic bottle",
  "bin": "recycling",
  "confidence": 0.98
}
```

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

```
GEMINI_API_KEY=your_api_key_here
```
API key for Google Maps 
```
GOOGLE_PLACES_API_KEY=your_api_key_here
```
SMTP configuration
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

## 🧑‍💻 Contribution Guide (Issue → Pull Request Flow)

 We follow an issue-based development workflow to keep collaboration clean and organized.

### 1️⃣ Pick or Create an Issue

- Go to the **Issues** tab  
- Choose an issue from the **Backlog / Ready**  
- Assign the issue to yourself  

### 2️⃣ Create a Feature Branch

Branch naming convention:
```
feature/<issue-number>-short-description
```

Example:
```
git checkout -b feature/12-camera-ui
```

### 3️⃣ Work on the Issue

- Make small, focused commits
- Follow the project structure
- Test before pushing  

```
git add .
git commit -m "Add camera UI for scanning"
```

### 4️⃣ Push Your Branch

```
git push origin feature/12-camera-ui
```

### 5️⃣ Open a Pull Request (PR)

- Open a PR targeting the develop branch
- Link the issue using:

```
Closes #12
```
## ✅ PR Checklist

- [ ] Code follows project structure
- [ ] Feature matches issue description
- [ ] No unnecessary files committed
- [ ] App runs without errors

## 6️⃣ Review & Merge

- Admin reviews the PR
- Requested changes (if any) are applied
- PR is merged into **develop**
- Completed issues are moved to **Done**

## 🌳 Branch Rules

- ❌ No direct commits to `main`
- ✅ All changes via Pull Requests
- ✅ Admin approval required before merge

---

## 🏁 Development Workflow Summary

```
Issue → Branch → Code → Pull Request → Review → Merge
```
### This keeps the project:
- Organized
- Easy to review
- Professional for hackathon judges