# CBC School Management System — Implementation Plan
*Kenya Competency-Based Curriculum (CBC) 2026 Edition — Enterprise ERP*

---

## 1. Project Overview

A **cross-platform Flutter ERP** designed for private Kenyan schools (PP1–G9). It manages academic assessments, financial health, staff specialization, and daily operations (Health, Catering, Security) with a native experience on Android, Windows, and macOS.

---

## 2. Stakeholders & Access Control

The system uses a **Primary Role + Feature Flags** architecture to accommodate multi-tasking staff in private schools.

| Stakeholder | Primary Access | Key Responsibilities |
|---|---|---|
| **Director** | Owner Level | Financial health, enrollment trends, audit logs, board reports. |
| **Headteacher** | Admin L1 | Academic compliance, account management, KNEC data export. |
| **Deputy Headteacher** | Admin L2 | Daily attendance, discipline, leave approval, timetable. |
| **Senior Teacher** | Academic Lead | Curriculum coverage, assessment moderation, HOD management. |
| **Bursar / Accountant** | Finance | Fee structures, payment processing (M-Pesa), expenditure tracking. |
| **Admissions Officer** | Front Office | Student registration, UPI management, admission letters. |
| **Teacher** | Base Role | Rubric entry, evidence upload, narrative remarks, attendance. |
| **Parent** | Portal | Progress tracking, fee balances, child's evidence vault. |
| **Student** | Limited Portal | Portfolio view, assignments, digital feedback. |
| **Nurse / Matron** | Health | Medical records, clinic visits, allergy alerts (linked to kitchen). |
| **Catering Manager** | Operations | Meal planning, dietary restrictions, inventory. |
| **Security Officer** | Safety | Visitor logs, student pickup verification, incident reports. |

---

## 3. Technology Stack

*   **Frontend**: Flutter 3.x (Dart)
*   **Local DB**: SQLite via `floor` (Offline-first architecture)
*   **Cloud DB**: Firebase Firestore (Real-time sync)
*   **Authentication**: Firebase Auth (RBAC + Role Flags)
*   **Media Storage**: Firebase Storage (Evidence & Document Vault)
*   **Utilities**: Riverpod (State), GoRouter (Navigation), PDF/Excel (Exports), Connectivity_plus (Sync).

---

## 4. Database Schema (Expanded)

### 4.1 Core User (Shared)
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role_level INTEGER NOT NULL,      -- 1=Admin, 2=Teacher, 3=Bursar, etc.
  role_flags TEXT,                  -- JSON: ["HOD", "Discipline", "Games", "Nurse"]
  assigned_class_id TEXT,
  department_id TEXT,               -- For HODs
  is_active INTEGER DEFAULT 1,
  created_at INTEGER NOT NULL
);
```

### 4.2 Health Module
```sql
CREATE TABLE medical_records (
  student_id TEXT PRIMARY KEY REFERENCES students(id),
  allergies TEXT,                   -- Red-flag in Catering module
  chronic_conditions TEXT,
  blood_group TEXT,
  emergency_contacts TEXT
);

CREATE TABLE clinic_visits (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  symptoms TEXT,
  action_taken TEXT,
  medication_given TEXT,
  timestamp INTEGER NOT NULL
);
```

### 4.3 Operations (Catering & Security)
```sql
CREATE TABLE meal_plans (
  id TEXT PRIMARY KEY,
  week_date TEXT,
  menu_data TEXT                    -- JSON: {mon: {lunch: "Rice"}, ...}
);

CREATE TABLE visitor_logs (
  id TEXT PRIMARY KEY,
  visitor_name TEXT,
  id_number TEXT,
  student_id TEXT,                  -- If visiting child
  time_in INTEGER,
  time_out INTEGER
);
```

---

## 5. CBC Curriculum & Specialty Roles

### 5.1 Curriculum Bands
*   **Pre-Primary (PP1–PP2)**: 5 Activity Areas.
*   **Lower Primary (G1–G3)**: 7 Subjects.
*   **Upper Primary (G4–G6)**: 8 Subjects.
*   **Junior School (G7–G9)**: 10 Core Subjects + Electives (Computer Science, Home Science, etc.).

### 5.2 Specialty Role Functionalities (Teacher Extensions)
*   **HOD**: Subject moderation, syllabus coverage tracking per teacher.
*   **Games Teacher**: Talent profiles, competition results, fitness logs.
*   **Discipline Master**: Incident logging, digital warnings, parent notifications.
*   **Guidance & Counseling**: Private session logs, at-risk learner flagging (Restricted Access).
*   **Exam Coordinator**: Results consolidation, grade distribution charts (No ranking).
*   **CBC Coordinator**: Portfolio completeness auditing, KNEC format verification.

---

## 6. Implementation Phases

### Phase 1 — Enterprise Core (Current)
- [x] Foundation (Riverpod, Floor, Firebase init)
- [x] Seeding Engine (Curriculum & Users)
- [x] Base Dashboard UI (Teacher, Headteacher, Parent)
- [ ] **Next**: Dynamic Role-Flag navigation system.

### Phase 2 — Academic Deep-Dive (Junior School)
- [x] G7–G9 Subject Expansion & Elective selector.
- [x] HOD Moderation portal (Approval & Rejection workflow).
- [x] Timetable Engine (AI Collision Detection & Slot Suggestion).

### Phase 3 — Operations (Health & Safety)
- [ ] Health Module (Clinic log + Allergy alerts).
- [ ] Catering (Meal tracking).
- [ ] Security (Gate log + Authorized pickup verification).

### Phase 4 — Financial Mastery
- [x] Fee structure per grade band.
- [x] M-Pesa STK Push fee collection engine.
- [x] Financial Inventory Bridge (Procurement & Expenditure Sync).
- [ ] M-Pesa B2C integration for payroll/reimbursements.

### Phase 5 — Transition & Compliance
- [x] KPSEA/KJSEA Weighting engine (20/20/60 math).
- [x] Pathway Recommendation engine for Grade 9 specializations.
- [x] Bulk KNEC data export (CSV/Institutional Bridge).

---

## 7. Key Flutter Packages
*   `flutter_riverpod`, `go_router`, `floor`, `firebase_core`, `cloud_firestore`, `excel`, `pdf`, `image_picker`, `local_auth`.
