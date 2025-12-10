# StrayCare: A Social Platform for Animal Welfare

A mobile-first social platform dedicated to addressing the pressing challenges of animal welfare. It centralizes all aspects of animal care into a single, comprehensive mobile application, connecting animal lovers, pet owners, rescuers, and volunteers within a unified ecosystem. The platform provides community-driven features for reporting, rescuing, and adopting animals, alongside an integrated marketplace for pet services and AI-powered assistance for immediate guidance.

This project is submitted as a requirement for the **CSE 328 (Software Engineering Lab)** and **CSE 300 (Software Development Project 3)** courses.

---

## 🚀 The Problem

Urban areas face significant challenges with stray animal injuries, abandonment, and a lack of timely medical attention. Existing solutions are often scattered across various social media groups, classifieds, and informal fundraisers, leading to inefficiency and delayed help for animals in distress.

---

## 🔑 Key Features

- 🆘 **Emergency Rescue Feed:** Allows users to create urgent posts for injured or at-risk animals, complete with location tags to alert nearby rescuers.  
- ❤️ **Adoption & Community Posts:** A social feed for users to post animals for adoption, share success stories, and provide educational content.  
- 💰 **Fundraising Campaigns:** A dedicated feature for users to create and contribute to fundraising campaigns for medical treatment or rescue operations.  
- 🛒 **Pet Marketplace:** An integrated marketplace where users can sell pet-related products or offer professional services, such as:  
  - Veterinarian Consultations  
  - Grooming Services  
  - Pet Supplies  
- 🤖 **AI-Powered Assistance:**  
  - **AI Vet Bot:** An intelligent chatbot providing basic first-aid guidance, and automatically monitoring emergency posts to offer initial advice if no human response is present.  
  - **Breed Detection:** Helps users identify an animal's breed from a photo using AI.  
- 💬 **Direct Messaging:** Secure, real-time chat system for coordinating rescues and consulting veterinarians after booking.  
- 🔔 **Real-time Notifications:** Central hub for all important updates about posts, messages, and marketplace transactions.  
- 🔒 **Secure Authentication:** Complete user authentication using Email/Password (with OTP verification) and Google Sign-In.

---

## 🛠️ Tech Stack

| Category         | Technology                                    |
|------------------|-----------------------------------------------|
| Frontend         | Flutter                                       |
| Backend          | Firebase (Authentication, Cache Storage), MongoDB Atlas (Database), Python Django, FastAPI Dart Frog, Google Cloud Functions and APIs |
| AI (Vet Bot)     | Proprietary fine-tuned LoRA LLM API (e.g. Anvil AI)  |
| AI (Breed Detection) | TensorFlow Lite                             |
| Geolocation      | Google Maps API                               |
| Payment Gateway  | SSLCOMMERZE (or similar)                           |

---

## 📦 Project Documentation

This repository contains complete design and planning artifacts for the project:

- Software Requirement Specification (SRS)  
- Software Design Specification (SDS)  
- Use Case Diagram  
- Entity-Relationship Diagram (ERD)  
- Sequence Diagrams  
- Class Diagram  
<a href="https://github.com/SDP-3-Group-4/straycare/wiki">Check it out here.</a>
---

## 🏁 Getting Started

### Prerequisites

- Flutter SDK (v3.x.x)  
- An editor (e.g., VS Code, Android Studio)  
- A Firebase project  

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/straycare.git

# Navigate to the project directory
cd straycare

# Install dependencies
flutter pub get
