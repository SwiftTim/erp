# CBC School Management ERP

A modern, cross-platform ERP tailored for private Kenyan schools implementing the Competency-Based Curriculum (CBC) 2026 Edition. 

🚧 **Note: This project is still actively under development. Several features are planned or currently being built.** 🚧

## 🚀 Milestone: Timetable Engine is fully functional!
We have successfully reached a major milestone: the **Constraint-Based Timetable Engine is now working**.
- Dynamically handles class subject demands, teacher capacities, and school-specific constraints.
- Employs an intelligent backtracking algorithm to assign slots without collisions.
- Integrates nicely with the core backend for generation, tracking, and dashboard rendering.

## Overview

The ERP provides dedicated dashboards for various school stakeholders (Director, Headteacher, Deputy, Teachers, Parents, and operations staff), backed by dynamic role-based access control.

### Current Core Features
- **Offline-First Architecture**: Powered by SQLite (`floor`) with Firebase syncing for remote capabilities.
- **Academic Deep-Dive**: Complete implementation of Junior School (Grade 7 - 9) with subject expansion, electives, and teacher mediation protocols.
- **Financial Mastery**: Built-in fee structure generation and M-Pesa STK push processing.
- **Dynamic Access Control**: Contextual Role-Flag system to securely transition user context on the fly.
- **Milestone: Timetable Engine**: Automated, collision-free class and teacher schedules seamlessly integrated for CBC demands.

### Tech Stack
- **Frontend App**: Flutter 3.x (Dart), Riverpod, GoRouter, fl_chart
- **Local DB**: SQLite via `floor`
- **Cloud/Backend Systems**: Firebase Firestore, Firebase Auth, Firebase Storage

## Getting Started

*(Instructions on how to configure Firebase, Floor, and generate necessary `.g.dart` files will be added soon.)*

---
*Built natively with Flutter for Android, macOS, and Windows.*
