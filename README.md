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
