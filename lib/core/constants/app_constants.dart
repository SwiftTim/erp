// lib/core/constants/app_constants.dart

/// CBC Kenya 2026 — Application-wide constants

class AppConstants {
  AppConstants._();

  static const String appName = 'CBC School';
  static const String appTagline = 'Kenya CBC 2026 School Management';

  // ── Role Levels ────────────────────────────────────────────────────────────
  // ── Role Levels (Hierarchy) ────────────────────────────────────────────────
  static const int roleDirector = 1;
  static const int roleHeadteacher = 2;
  static const int roleDeputy = 3;
  static const int roleSeniorTeacher = 4;
  static const int roleTeacher = 5;
  static const int roleAccountant = 6;
  static const int roleAdmissions = 7;
  static const int roleNurse = 8;
  static const int roleCatering = 9;
  static const int roleSecurity = 10;
  static const int roleParent = 11;
  static const int roleStudent = 12;
  // ── New operations actor roles ─────────────────────────────────────────────
  static const int roleReceptionist  = 13;
  static const int roleBoardingMaster = 14;
  static const int roleLibrarian     = 15;
  static const int roleFleetManager  = 16;
  static const int roleHR            = 17;
  static const int roleStoreKeeper   = 18;

  static const Map<int, String> roleNames = {
    1: 'Director / Proprietor',
    2: 'Headteacher',
    3: 'Deputy Headteacher',
    4: 'Senior Teacher',
    5: 'Teacher',
    6: 'Accountant / Bursar',
    7: 'Admissions Officer',
    8: 'School Nurse / Health',
    9: 'Catering Manager',
    10: 'Security Officer',
    11: 'Parent / Guardian',
    12: 'Student',
    13: 'Receptionist',
    14: 'Boarding Master',
    15: 'Librarian',
    16: 'Fleet Manager',
    17: 'HR Officer',
    18: 'Store Keeper',
  };

  // ── Specialty Role Flags (For Teachers/Staff) ──────────────────────────────
  static const String flagHOD = 'HOD';
  static const String flagDiscipline = 'DISCIPLINE';
  static const String flagGames = 'GAMES';
  static const String flagCounseling = 'COUNSELING';
  static const String flagICT = 'ICT';
  static const String flagExamCoord = 'EXAM_COORD';
  static const String flagCBCCoord = 'CBC_COORD';
  static const String flagClubAdvisor = 'CLUB_ADVISOR';
  static const String flagClassTeacher = 'CLASS_TEACHER';

  static const List<String> teacherSpecialties = [
    flagHOD, flagDiscipline, flagGames, flagCounseling, flagICT, flagExamCoord, flagCBCCoord, flagClubAdvisor, flagClassTeacher
  ];

  // ── Departments (For HODs & Budgeting) ────────────────────────────────────
  static const List<String> departments = [
    'Mathematics', 'Languages', 'Science & Tech', 'Social Sciences',
    'Creative Arts & Sports', 'Religious Education', 'Applied Sciences'
  ];

  // ── Grades ─────────────────────────────────────────────────────────────────
  static const List<String> prePrimaryGrades = ['PP1', 'PP2'];
  static const List<String> lowerPrimaryGrades = ['Grade 1', 'Grade 2', 'Grade 3'];
  static const List<String> upperPrimaryGrades = ['Grade 4', 'Grade 5', 'Grade 6'];
  static const List<String> juniorSchoolGrades = ['Grade 7', 'Grade 8', 'Grade 9'];

  static List<String> get allGrades => [
        ...prePrimaryGrades,
        ...lowerPrimaryGrades,
        ...upperPrimaryGrades,
        ...juniorSchoolGrades,
      ];

  static String gradeBand(String grade) {
    if (prePrimaryGrades.contains(grade)) return 'PP1-PP2';
    if (lowerPrimaryGrades.contains(grade)) return 'Grade 1-3';
    if (upperPrimaryGrades.contains(grade)) return 'Grade 4-6';
    return 'Grade 7-9';
  }

  static String? getNextGrade(String currentGrade) {
    final idx = allGrades.indexOf(currentGrade);
    if (idx != -1 && idx < allGrades.length - 1) {
      return allGrades[idx + 1];
    }
    return null; // Signals graduation/transition out of Junior School
  }

  // ── Formative Rubric (4-Level) ─────────────────────────────────────────────
  static const Map<int, String> rubricCode = {
    4: 'EE',
    3: 'ME',
    2: 'AE',
    1: 'BE',
  };

  static const Map<int, String> rubricLabel = {
    4: 'Exceeding Expectations',
    3: 'Meeting Expectations',
    2: 'Approaching Expectations',
    1: 'Below Expectations',
  };

  static const Map<int, String> rubricDescription = {
    4: 'Learner demonstrates exceptional mastery; applies skills in new and complex situations.',
    3: 'Learner has achieved all required competencies for the grade level independently.',
    2: 'Learner is developing competencies but requires occasional support or practice.',
    1: 'Learner has significant gaps and requires intensive support and intervention.',
  };

  // ── CBC Performance Band Boundaries (For aggregation) ──────────────────────
  static const double bandEEThreshold = 3.5;
  static const double bandMEThreshold = 2.5;
  static const double bandAEThreshold = 1.5;

  static String getCompetencyBand(double average) {
    if (average >= bandEEThreshold) return 'EE';
    if (average >= bandMEThreshold) return 'ME';
    if (average >= bandAEThreshold) return 'AE';
    return 'BE';
  }

  static String getCompetencyLabel(double average) {
    if (average >= bandEEThreshold) return 'Exceeding Expectations';
    if (average >= bandMEThreshold) return 'Meeting Expectations';
    if (average >= bandAEThreshold) return 'Approaching Expectations';
    return 'Below Expectations';
  }

  // ── Assessment Types (CBC Aligned) ────────────────────────────────────────
  static const List<String> assessmentTypes = [
    'Diagnostic',
    'Formative',
    'Summative',
    'Peer Assessment',
    'Self Assessment',
    'Project-Based',
    'Practical',
    'Oral',
    'Written',
    'Observation',
  ];

  // ── Summative Achievement Levels (8-Point) ─────────────────────────────────
  static const List<SummativeLevel> summativeLevels = [
    SummativeLevel(code: 'EE1', label: 'Exceptional',         minPct: 90, maxPct: 100, points: 8),
    SummativeLevel(code: 'EE2', label: 'Very Good',           minPct: 75, maxPct: 89,  points: 7),
    SummativeLevel(code: 'ME1', label: 'Good',                minPct: 58, maxPct: 74,  points: 6),
    SummativeLevel(code: 'ME2', label: 'Fair',                minPct: 41, maxPct: 57,  points: 5),
    SummativeLevel(code: 'AE1', label: 'Needs Improvement',   minPct: 31, maxPct: 40,  points: 4),
    SummativeLevel(code: 'AE2', label: 'Below Average',       minPct: 21, maxPct: 30,  points: 3),
    SummativeLevel(code: 'BE1', label: 'Well Below Average',  minPct: 11, maxPct: 20,  points: 2),
    SummativeLevel(code: 'BE2', label: 'Minimal',             minPct: 1,  maxPct: 10,  points: 1),
  ];

  static SummativeLevel getSummativeLevel(double percentage) {
    for (final level in summativeLevels) {
      if (percentage >= level.minPct && percentage <= level.maxPct) return level;
    }
    return summativeLevels.last;
  }

  // ── Transition Weights ─────────────────────────────────────────────────────
  static const double kpseaWeight = 0.20;   // Grade 6
  static const double sba7Weight  = 0.10;   // Grade 7 SBA
  static const double sba8Weight  = 0.10;   // Grade 8 SBA
  static const double kjseaWeight = 0.60;   // Grade 9

  // ── Core Competencies (7) ─────────────────────────────────────────────────
  static const List<String> coreCompetencies = [
    'Communication and Collaboration',
    'Self-efficacy',
    'Critical Thinking and Problem-solving',
    'Creativity and Imagination',
    'Citizenship',
    'Digital Literacy',
    'Learning to Learn',
  ];

  // ── Narrative Remarks Bank ─────────────────────────────────────────────────
  static String generateNarrative(int score, String subject) {
    switch (score) {
      case 4:
        return 'Learner demonstrates advanced mastery and creatively applies $subject concepts to real-life situations.';
      case 3:
        return 'Learner has achieved all required competencies in $subject and works independently.';
      case 2:
        return 'Learner is developing competencies in $subject but requires occasional support and more practice.';
      case 1:
      default:
        return 'Learner is beginning to grasp $subject concepts but needs significant one-on-one support.';
    }
  }

  // ── Payment Modes ──────────────────────────────────────────────────────────
  static const List<String> paymentModes = ['M-Pesa', 'Bank Transfer', 'Cash', 'Cheque'];

  // ── Terms ──────────────────────────────────────────────────────────────────
  static const List<int> terms = [1, 2, 3];

  // ── Assessment Statuses ───────────────────────────────────────────────────
  static const int statusDraft      = 0;
  static const int statusSubmitted  = 1;
  static const int statusModerated  = 2;
  static const int statusRejected   = 3;

  // ── Attendance Statuses ────────────────────────────────────────────────────
  static const String present = 'Present';
  static const String absent  = 'Absent';
  static const String late    = 'Late';

  // ── Chronic absenteeism threshold (absences per month) ────────────────────
  static const int chronicAbsenceThreshold = 3;

  // ── Senior School Pathways ─────────────────────────────────────────────────
  static const List<String> seniorPathways = [
    'STEM (Science, Technology, Engineering & Mathematics)',
    'Arts and Sports Science',
    'Social Sciences',
  ];
}

// ── Value Objects ─────────────────────────────────────────────────────────────
class SummativeLevel {
  final String code;
  final String label;
  final int minPct;
  final int maxPct;
  final int points;

  const SummativeLevel({
    required this.code,
    required this.label,
    required this.minPct,
    required this.maxPct,
    required this.points,
  });
}
