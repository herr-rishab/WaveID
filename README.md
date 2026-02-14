# WaveID – Audio-Based Attendance & Session Management System

WaveID is a cross-platform mobile application built using Flutter and Firebase that enables secure, proximity-based attendance marking using audio token transmission.

The system consists of:

- Mobile Application (Student / Teacher / Admin)
- Web Dashboard for centralized monitoring and reporting

WaveID can be used for placement drives, classroom attendance, workshops, training sessions, corporate events, and other structured gatherings where secure and verifiable presence tracking is required.

---

# Core Concept

Traditional attendance systems rely on manual sheets, QR codes, or location-based methods. WaveID introduces a proximity-based approach where a time-bound token is transmitted via audio and validated through a backend system.

Audio ensures physical proximity.  
Backend validation ensures identity, integrity, and data consistency.

---

# System Architecture

```
Parent Device (Audio Broadcast)
            ↓
Child Devices (Audio Detection)
            ↓
Firebase Backend (Authentication + Validation + Storage)
            ↓
Web Dashboard (Monitoring + Reporting)
```

The mobile application handles attendance marking.  
The dashboard provides centralized visibility and analytics.

---

# Roles & Responsibilities

## Student
- Secure login using Firebase Authentication
- Join active session
- Listen for attendance token via microphone
- Decode token and submit for validation
- View personal attendance history

## Teacher / Session Controller
- Create and manage attendance sessions
- Generate session-specific tokens
- Broadcast token via audio
- Monitor real-time attendance updates

## Admin
- Manage users and roles
- Create and manage drives, classes, or sessions
- Monitor attendance across sessions
- Export reports and analytics
- Manage dashboard-level configurations

---

# Web Dashboard

The Web Dashboard acts as the centralized monitoring system.

### Features
- View attendance per session, drive, or event
- Track total registered vs present participants
- Export attendance data
- Manage session lifecycle
- Real-time updates via Firestore listeners
- Role-based access control

All attendance marked from the mobile application is instantly stored in Firestore and reflected on the dashboard.

---

# Attendance Workflow

## 1. Session Creation
Admin or Teacher creates a session:
- Event name (e.g., placement drive, lecture, workshop)
- Date and time
- Associated participants

## 2. Session Activation
Teacher:
- Starts attendance session
- Token is generated
- Token is encoded into audio frequencies
- Audio is broadcast to participants

## 3. Attendance Marking
Student:
- Opens listening mode
- Audio is decoded into token
- Token is submitted to backend
- Backend validates:
  - Session is active
  - Token matches
  - Token is not expired
  - Student has not already marked attendance

If valid, attendance is recorded under that session.

---

# Security Model

WaveID enforces security through:

- Firebase Authentication identity binding
- Role-based access control
- Firestore security rules
- Session-bound tokens
- One-time attendance marking per session
- Backend validation before record creation

Audio transmission acts as a proximity transport mechanism.  
Actual trust enforcement is handled through backend validation.

---

# Tech Stack

| Layer | Technology |
|--------|------------|
| Mobile App | Flutter |
| Language | Dart |
| Backend | Firebase |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Dashboard | Web application connected to Firestore |
| Audio Engine | Custom frequency encoder/decoder |
| Platforms | Android, iOS |

---

# Project Structure (Mobile)

```
lib/
 ├── models/              # User, Session, Attendance models
 ├── services/            # Auth, Firestore, Audio, Token logic
 ├── screens/             # Admin / Teacher / Student UI
 ├── widgets/             # Reusable components
 ├── theme/               # App styling
 └── main.dart            # Entry point
```

---

# Setup Instructions

## 1. Clone Repository

```bash
git clone https://github.com/your-username/waveid.git
cd waveid
```

## 2. Install Dependencies

```bash
flutter pub get
```

## 3. Firebase Setup

- Create a Firebase project
- Enable Authentication
- Enable Cloud Firestore
- Add:
  - `google-services.json` (Android)
  - `GoogleService-Info.plist` (iOS)
- Configure `firebase_options.dart`

## 4. Run Application

```bash
flutter run
```

---

# Use Cases

WaveID is adaptable to multiple scenarios:

- University lectures
- Placement drives
- Corporate training sessions
- Workshops and seminars
- Campus events
- Professional certification sessions

---

# Future Improvements

- Time-window token rotation
- Cloud Functions for stricter server-side validation
- Advanced dashboard analytics
- Multi-organization support
- Device binding for enhanced security
- Attendance anomaly detection

---

# What This Project Demonstrates

- Full-stack system design (Mobile + Dashboard)
- Real-time synchronization using Firestore
- Role-based architecture
- Audio signal encoding and decoding
- Secure token-based validation model
- Scalable session-based attendance system

---
## Contributors

Rishab Aggarwal (23FE10CSE00017)
Ayan Dafadar (23FE10CSE00125)
