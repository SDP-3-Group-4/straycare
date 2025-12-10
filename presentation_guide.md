# StrayCare Project Architecture Guide

Use this guide to explain your folder structure during your presentation. It clearly separates the **Frontend (UI)** from the **Backend Logic (Data & Services)**.

## 1. The Big Picture
Your project follows a **Feature-First Architecture**.
- **Frontend**: Flutter UI (Screens, Widgets).
- **Backend Interface**: Repositories & Services (Code that talks to the cloud).
- **Cloud Backend**: Firebase (DB, Auth) + **StrayCare AI Vet Bot API** + Google Scripts.

---

## 2. Folder Structure Breakdown

### 📂 `lib/features/` (The Core Modules)
This is where 90% of your code lives. Each feature involves both UI and Logic.

| Sub-folder | Role | Responsibility (Frontend vs Backend) |
| :--- | :--- | :--- |
| **`screens/`** | **Frontend (UI)** | **"What the user sees."** <br> e.g., `ChatDetailScreen.dart`, `ProfileScreen.dart`. <br> Contains buttons, layout, colors, and navigation logic. |
| **`widgets/`** | **Frontend (UI)** | **"Reusable UI blocks."** <br> e.g., `PostCard.dart`, `VerifiedBadge.dart`. <br> Components used across multiple screens. |
| **`repositories/`** | **Backend Interface** | **"The Bridge to the Cloud."** <br> e.g., `ChatRepository.dart`, `UserRepository.dart`. <br> This code **FETCHES** and **SENDS** data to Firestore. <br> *Explain to supervisor:* "This file doesn't draw pixels; it talks to the database." |

### 📂 `lib/services/` (Pure Backend Services)
These are global services that power the entire app.

| File | Role | Responsibility |
| :--- | :--- | :--- |
| `auth_service.dart` | **Backend Security** | Handles Login/Signup. Talks to **Firebase Auth**. |
| `firestore_service.dart` | **Database Core** | Generic wrappers for **Cloud Firestore**. |
| `ai_service.dart` | **AI Logic** | **"The Brain."** <br> Sends prompts to our **StrayCare AI Vet Bot** (Anvil 1 Beta) and parses responses. |

### 📂 External Backend Scripts
| File | Role | Responsibility |
| :--- | :--- | :--- |
| `vet_verification_script.gs` | **True Backend** | **Google Apps Script**. <br> Runs on Google Servers (not the phone). <br> Receives verification data and saves it to Google Drive/Sheets. |

---

## 3. How to Answer "Where is the Backend?"

**Q: "Where is the backend in this project?"**

**A:** "The backend is distributed across **Cloud Services** and **Interface Code**:"

1.  **The Database (Cloud):** "We use **Firebase Firestore** (NoSQL) hosted by Google. This holds all users, chats, and posts."
2.  **The AI Model (Cloud):** "We use **StrayCare Anvil 1 Beta**, our fine-tuned proprietary LLM designed for veterinary triage."
3.  **The Code (Here in `lib`):**
    *   "**Frontend**: `lib/features/*/screens` handles the UI and user input."
    *   "**Backend Logic**: `lib/features/*/repositories` and `lib/services` handle the API calls and data synchronization."

---

## 4. Visual Flow for Presentation
*(Draw this on a whiteboard if asked)*

```mermaid
graph LR
    User -->|Interacts| UI[Frontend UI\n(Screens/Widgets)]
    UI -->|Calls| Repo[Repositories\n(Data Layer)]
    Repo -->|API Calls| Firebase[(Firebase Cloud\nAuth & DB)]
    Repo -->|API Calls| AI[AI Service\n(Anvil API)]
```
