# Enterprise Upgrade Workplan: CBC Intelligence & Automation

This plan outlines the multi-phase transition from a standard ERP to an **Enterprise Intelligence System (EIS)** for Kenyan CBC schools.

## 🏗 Phase 1: Infrastructure & Data Foundation (Next 24 Hours)
*   **Database Expansion**: 
    *   Implement new entities: `TeachingAssignment`, `OfficialMemo`, `ClubModel`, `InventoryModel`, `StaffLeave`, `SystemLog`, `TimetableEntry`.
    *   Update `UserModel` with cleaner Flag handling (JSON encoding/decoding utilities).
*   **Master Curriculum Seeding**:
    *   Inject the complete Ministry of Education syllabus (PP1 to Grade 9) with full Subject -> Strand -> Sub-strand hierarchy into the `curriculum_seed.json`.
*   **RBAC 2.0**:
    *   Refine `AppShell` to handle the 12 stakeholder dashboards and dynamic "Role Flags".

## 🚀 Phase 2: Operational Engine Revamp
*   **Teacher Assignment Pipeline**:
    *   Create the "Senior Teacher" portal for linking Teachers to Subjects/Classes.
    *   Implement "Class Teacher" auto-detection in the dashboard.
*   **Attendance Heatmap**:
    *   Upgrade Attendance service to notify parents automatically and generate Deputy reports.
*   **Timetable Engine (MVP)**:
    *   Implement a rule-based generator that respects teacher availability and lesson counts per subject.

## 🤝 Phase 3: Connective Intelligence
*   **Memo Engine**:
    *   Create an official school memo portal with "Read Receipt" tracking for staff.
*   **Approval Workflows**:
    *   Implement the HOD -> Headteacher approval chain for and assessment locking.
*   **Intelligence Alerts**:
    *   Background service to flag at-risk students (academic or attendance) on the Executive Dashboard.

## 🏦 Phase 4: Specialty & Infrastructure
*   **Clubs & Societies**:
    *   Advisor-led club management and member achievement logging.
*   **Inventory & Assets**:
    *   School resource tracking and maintenance logs.
*   **Audit & Security**:
    *   Implement `SystemActivityLog` middleware to track every sensitive action (who edited what).
    *   Local backup management tool.

## 🎨 Phase 5: High-Resolution UI Execution
*   **Aesthetic Overhaul**:
    *   Implement "Premium Dark Mode" and "Glassmorphism" variants for Executive roles.
    *   Add micro-animations for STK-Push and Report generation.

---

### Immediate Next Steps:
1.  **Seed Update**: Populate the database with the massive CBC curriculum list.
2.  **Model Expansion**: Create the missing entity files for Timetable, Clubs, and Memos.
3.  **AppRouter Update**: Re-map the navigation to reflect the 3-Core-Layer architecture.
