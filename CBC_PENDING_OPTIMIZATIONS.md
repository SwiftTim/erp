# CBC ERP — Pending Optimizations & Logic Gaps
*Status: Identified for Institutional Hardening & Phase 6*

This document tracks specialized logic gaps discovered during the Phase 3-5 Audit. These items are required for a production-grade enterprise deployment.

---

## 🔐 1. Authentication & Role Flow
- [x] **Per-Route Role Validation**: Implement middleware/guards in `app_router.dart` (Completed).
- [x] **Session Hardening**: Automated session timeout logic (Completed).

## 📚 2. Academic & Attendance Pipeline
- [x] **Assessment State Lock**: Disable editing for moderated assessments in `assessment_entry_page.dart` (Completed).
- [x] **Automated Absence Alerts**: Trigger alerts to parents (Completed).
- [x] **Absenteeism Analytics**: Chronic Absenteeism heatmap (Completed).

## 🧑‍🏫 3. Teacher Operations
- [x] **Staff Presence Logic**: Daily clock-in/out system (Completed).
- [x] **Syllabus Coverage Tracking**: Checklist for strands (Completed).
- [x] **Substitution Persistence**: Workflow to delegate class rights (Completed).

## 💰 4. Finance Pipeline
- [x] **Digital Receipt Engine**: PDF generation (Completed).
- [x] **Defaulter Lock Mechanism**: Report card flagging (Completed).
- [x] **Transactional Reversals**: Voiding workflow in models and DAOs (Completed).

## 💬 5. Communication System
- [x] **Messaging Persistence**: Bridge Messaging UI to SQLite (Completed).
- [x] **Emergency Override**: High-priority broadcast override in `AppShell` (Completed).
- [x] **Memo Read Receipts**: Tracking views (Completed).

## 📦 6. Inventory & Assets
- [x] **Asset Assignment Workflow**: Linked assets to staff ID in models (Completed).
- [x] **Maintenance Logs**: Historical record servicing (Completed).

## 🔄 7. System Integrity & Security
- [x] **Multi-Year Archiving**: Promote All logic (Completed).
- [x] **Input Sanitization**: Global filter for narrative remarks (Completed).
- [x] **File Size Hardening**: 5MB cap on individual Evidence Item uploads (Completed).



