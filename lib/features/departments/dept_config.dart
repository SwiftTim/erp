// lib/features/departments/dept_config.dart
// Defines every department's modules, compliance checklist, and report types.

import 'package:flutter/material.dart';
import 'widgets/dept_module_panel.dart';

class DeptConfig {
  final String name;
  final IconData icon;
  final Color color;
  final String mandate;
  final List<String> hodResponsibilities;
  final List<String> memberResponsibilities;
  final List<String> reportTypes;
  final List<ModuleConfig> modules;
  final List<String> complianceItems;
  final List<String> subjects;

  const DeptConfig({
    required this.name,
    required this.icon,
    required this.color,
    required this.mandate,
    required this.hodResponsibilities,
    required this.memberResponsibilities,
    required this.reportTypes,
    required this.modules,
    required this.complianceItems,
    required this.subjects,
  });
}

final Map<String, DeptConfig> kDeptConfigs = {
  // ── 1. Languages ─────────────────────────────────────────────────────────────
  'languages': DeptConfig(
    name: 'Languages Department',
    icon: Icons.translate_outlined,
    color: const Color(0xFF1565C0),
    mandate: 'Develop communication competence, monitor literacy levels, moderate oral and written assessments.',
    subjects: ['English', 'Kiswahili', 'Indigenous Language', 'Foreign Language'],
    hodResponsibilities: [
      'Monitor reading fluency levels per grade',
      'Review writing quality standards',
      'Moderate composition marking',
      'Ensure oral assessment compliance',
      'Approve schemes of work',
    ],
    memberResponsibilities: [
      'Upload reading progress reports',
      'Record oral assessments',
      'Track vocabulary development',
      'Submit term performance',
    ],
    reportTypes: [
      'Literacy Performance Summary',
      'Reading Fluency Trends',
      'Writing Quality Distribution',
      'Intervention Plan for Weak Learners',
    ],
    complianceItems: [
      'Schemes of work submitted by all members',
      'Oral assessment rubrics distributed',
      'Composition moderation forms completed',
      'Literacy diagnostic administered',
      'Term reading fluency data uploaded',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'reading_fluency',
        title: 'Reading Fluency Tracker',
        description: 'Record per-learner reading fluency scores per grade',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF1565C0),
        fields: [
          ModuleField(key: 'learner_name', label: 'Learner Name / ID'),
          ModuleField(key: 'fluency_score', label: 'Fluency Score (wpm)', type: ModuleFieldType.number),
          ModuleField(
              key: 'band',
              label: 'Band',
              type: ModuleFieldType.dropdown,
              options: ['EE', 'ME', 'AE', 'BE']),
          ModuleField(key: 'notes', label: 'Observation Notes', type: ModuleFieldType.multiline),
          ModuleField(key: 'upload', label: 'Upload Reading Record (optional)', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'oral_assessment',
        title: 'Oral Assessment Rubric Manager',
        description: 'Log oral assessments with rubric-based scoring',
        icon: Icons.record_voice_over_outlined,
        color: Colors.teal,
        fields: [
          ModuleField(key: 'assessment_title', label: 'Assessment Title'),
          ModuleField(
              key: 'topic',
              label: 'Topic / Strand',
              type: ModuleFieldType.text),
          ModuleField(
              key: 'score',
              label: 'Average Score',
              type: ModuleFieldType.dropdown,
              options: ['EE (4)', 'ME (3)', 'AE (2)', 'BE (1)']),
          ModuleField(key: 'rubric_file', label: 'Upload Rubric / Recording', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'composition_moderation',
        title: 'Composition Moderation Tool',
        description: 'Track composition marking moderation sessions',
        icon: Icons.edit_note_outlined,
        color: Colors.purple,
        fields: [
          ModuleField(key: 'composition_title', label: 'Composition Title / Topic'),
          ModuleField(key: 'class_moderated', label: 'Class Moderated'),
          ModuleField(key: 'hod_remarks', label: 'Moderation Remarks', type: ModuleFieldType.multiline),
          ModuleField(key: 'moderation_doc', label: 'Upload Moderated Scripts (photo)', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'vocabulary_tracker',
        title: 'Vocabulary Growth Tracker',
        description: 'Track vocabulary acquisition milestones per class',
        icon: Icons.spellcheck_outlined,
        color: Colors.orange,
        fields: [
          ModuleField(key: 'vocabulary_set', label: 'Vocabulary Set / Theme'),
          ModuleField(key: 'words_count', label: 'Number of Words Assessed', type: ModuleFieldType.number),
          ModuleField(
              key: 'retention_level',
              label: 'Average Retention',
              type: ModuleFieldType.dropdown,
              options: ['High (>80%)', 'Good (60-80%)', 'Fair (40-60%)', 'Low (<40%)']),
          ModuleField(key: 'evidence', label: 'Upload Vocabulary Test / Evidence', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 2. Mathematics ────────────────────────────────────────────────────────────
  'mathematics': DeptConfig(
    name: 'Mathematics Department',
    icon: Icons.calculate_outlined,
    color: const Color(0xFF6A1B9A),
    mandate: 'Strengthen numeracy and ensure strand mastery across Numbers, Algebra, Geometry, Statistics.',
    subjects: ['Mathematics'],
    hodResponsibilities: [
      'Monitor strand coverage',
      'Analyze common errors',
      'Moderate internal exams',
      'Balance teacher workload',
    ],
    memberResponsibilities: [
      'Enter strand-based assessments',
      'Flag conceptual difficulties',
      'Propose remedial actions',
    ],
    reportTypes: [
      'Strand Difficulty Heatmap',
      'Performance Trend per Grade',
      'Competency Distribution',
      'Remedial Impact Report',
    ],
    complianceItems: [
      'Strand coverage checklist submitted',
      'Common error analysis completed',
      'Internal exam moderated by HOD',
      'Remedial plan uploaded',
      'Schemes signed off',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'strand_assessment',
        title: 'Strand-Based Assessment Entry',
        description: 'Record assessments per Math strand',
        icon: Icons.grid_4x4_outlined,
        color: const Color(0xFF6A1B9A),
        fields: [
          ModuleField(key: 'strand', label: 'Strand', type: ModuleFieldType.dropdown,
              options: ['Numbers', 'Algebra', 'Geometry', 'Measurement', 'Statistics & Probability']),
          ModuleField(key: 'sub_strand', label: 'Sub-Strand / Topic'),
          ModuleField(key: 'avg_score', label: 'Class Average Score', type: ModuleFieldType.number),
          ModuleField(key: 'errors_noted', label: 'Common Errors Noted', type: ModuleFieldType.multiline),
        ],
      ),
      ModuleConfig(
        moduleType: 'question_bank',
        title: 'Question Bank Builder',
        description: 'Add question bank items per strand and difficulty',
        icon: Icons.quiz_outlined,
        color: Colors.indigo,
        fields: [
          ModuleField(key: 'strand', label: 'Strand', type: ModuleFieldType.dropdown,
              options: ['Numbers', 'Algebra', 'Geometry', 'Measurement', 'Statistics']),
          ModuleField(key: 'difficulty', label: 'Difficulty', type: ModuleFieldType.dropdown,
              options: ['Easy', 'Medium', 'Hard', 'HOTS']),
          ModuleField(key: 'question', label: 'Question / Description', type: ModuleFieldType.multiline),
          ModuleField(key: 'doc', label: 'Upload Question Paper', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'remedial_action',
        title: 'Remedial Action Plan',
        description: 'Track remedial interventions for weak learners',
        icon: Icons.healing_outlined,
        color: Colors.red,
        fields: [
          ModuleField(key: 'topic', label: 'Topic Requiring Remediation'),
          ModuleField(key: 'no_learners', label: 'Number of Learners in Group', type: ModuleFieldType.number),
          ModuleField(key: 'strategy', label: 'Remediation Strategy', type: ModuleFieldType.multiline),
          ModuleField(key: 'plan_doc', label: 'Upload Remedial Plan/Materials', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 3. Science & Technology ───────────────────────────────────────────────────
  'science': DeptConfig(
    name: 'Science & Technology Department',
    icon: Icons.science_outlined,
    color: const Color(0xFF00695C),
    mandate: 'Monitor theory + practical balance and ensure lab safety compliance.',
    subjects: ['Integrated Science', 'Biology', 'Chemistry', 'Physics', 'Computer Science'],
    hodResponsibilities: [
      'Approve practical schedules',
      'Monitor equipment usage',
      'Ensure safety documentation',
      'Review experimental assessment rubrics',
    ],
    memberResponsibilities: [
      'Record practical sessions',
      'Log equipment usage',
      'Report safety incidents',
    ],
    reportTypes: [
      'Practical Completion Rate',
      'Lab Usage Log',
      'Safety Compliance Report',
      'Resource Gap Summary',
    ],
    complianceItems: [
      'Lab safety induction completed for all classes',
      'First aid kit inspected and stocked',
      'Chemical register updated',
      'Practical schedules submitted to HOD',
      'Equipment inventory updated',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'lab_booking',
        title: 'Lab Booking System',
        description: 'Schedule and track lab sessions',
        icon: Icons.biotech_outlined,
        color: const Color(0xFF00695C),
        fields: [
          ModuleField(key: 'class_name', label: 'Class / Group'),
          ModuleField(key: 'practical_title', label: 'Practical / Experiment Title'),
          ModuleField(key: 'date', label: 'Scheduled Date', type: ModuleFieldType.date),
          ModuleField(key: 'duration', label: 'Duration (minutes)', type: ModuleFieldType.number),
          ModuleField(key: 'equipment', label: 'Equipment Required', type: ModuleFieldType.multiline),
        ],
      ),
      ModuleConfig(
        moduleType: 'equipment_inventory',
        title: 'Equipment Inventory',
        description: 'Log lab equipment status and availability',
        icon: Icons.inventory_2_outlined,
        color: Colors.teal,
        fields: [
          ModuleField(key: 'item_name', label: 'Equipment Name'),
          ModuleField(key: 'quantity', label: 'Quantity Available', type: ModuleFieldType.number),
          ModuleField(key: 'condition', label: 'Condition', type: ModuleFieldType.dropdown,
              options: ['Good', 'Fair', 'Needs Repair', 'Condemned']),
          ModuleField(key: 'notes', label: 'Notes / Action Required', type: ModuleFieldType.multiline),
        ],
      ),
      ModuleConfig(
        moduleType: 'safety_incident',
        title: 'Safety Incident Tracker',
        description: 'Log any lab safety incidents or near-misses',
        icon: Icons.warning_amber_outlined,
        color: Colors.orange,
        fields: [
          ModuleField(key: 'incident_type', label: 'Incident Type', type: ModuleFieldType.dropdown,
              options: ['Chemical Spill', 'Equipment Damage', 'Injury', 'Near-Miss', 'Fire', 'Other']),
          ModuleField(key: 'description', label: 'Incident Description', type: ModuleFieldType.multiline),
          ModuleField(key: 'action_taken', label: 'Immediate Action Taken', type: ModuleFieldType.multiline),
          ModuleField(key: 'report_doc', label: 'Upload Incident Report', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'practical_assessment',
        title: 'Practical Assessment Log',
        description: 'Record learner practical assessment scores',
        icon: Icons.assignment_outlined,
        color: Colors.indigo,
        fields: [
          ModuleField(key: 'practical_name', label: 'Practical Name'),
          ModuleField(key: 'avg_score', label: 'Average Score (%)', type: ModuleFieldType.number),
          ModuleField(
              key: 'band',
              label: 'Overall Band',
              type: ModuleFieldType.dropdown,
              options: ['EE', 'ME', 'AE', 'BE']),
          ModuleField(key: 'rubric', label: 'Upload Rubric / Results Sheet', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 4. Humanities / Social Studies ───────────────────────────────────────────
  'humanities': DeptConfig(
    name: 'Humanities / Social Studies Department',
    icon: Icons.public_outlined,
    color: const Color(0xFFBF360C),
    mandate: 'Promote civic literacy, governance understanding, and historical awareness.',
    subjects: ['Social Studies', 'History', 'Geography', 'Citizenship', 'Religious Education'],
    hodResponsibilities: [
      'Review project-based assessments',
      'Ensure balanced thematic coverage',
      'Track fieldwork compliance',
    ],
    memberResponsibilities: [
      'Record project assessments',
      'Submit fieldwork reports',
      'Track civic project progress',
    ],
    reportTypes: [
      'Project Evaluation Distribution',
      'Citizenship Competency Analysis',
      'Historical Strand Mastery Report',
    ],
    complianceItems: [
      'Fieldwork permission forms processed',
      'Project rubrics distributed to learners',
      'Thematic coverage map submitted',
      'Civic projects assessed and logged',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'fieldwork',
        title: 'Fieldwork Tracker',
        description: 'Plan and record fieldwork activities',
        icon: Icons.map_outlined,
        color: const Color(0xFFBF360C),
        fields: [
          ModuleField(key: 'destination', label: 'Fieldwork Destination / Site'),
          ModuleField(key: 'objective', label: 'Learning Objective', type: ModuleFieldType.multiline),
          ModuleField(key: 'date', label: 'Planned Date', type: ModuleFieldType.date),
          ModuleField(key: 'participants', label: 'Number of Learners', type: ModuleFieldType.number),
          ModuleField(key: 'report_upload', label: 'Upload Permission Forms / Report', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'civic_project',
        title: 'Civic Project Repository',
        description: 'Log learner civic projects and evaluations',
        icon: Icons.groups_outlined,
        color: Colors.blue,
        fields: [
          ModuleField(key: 'project_title', label: 'Project Title'),
          ModuleField(key: 'theme', label: 'Citizenship Theme', type: ModuleFieldType.dropdown,
              options: ['Local Governance', 'Environmental', 'Community Service', 'Human Rights', 'Patriotism']),
          ModuleField(key: 'score', label: 'Evaluation Score / Band', type: ModuleFieldType.dropdown,
              options: ['EE', 'ME', 'AE', 'BE']),
          ModuleField(key: 'project_doc', label: 'Upload Project / Evidence', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 5. Creative Arts ─────────────────────────────────────────────────────────
  'creative_arts': DeptConfig(
    name: 'Creative Arts Department',
    icon: Icons.palette_outlined,
    color: const Color(0xFFAD1457),
    mandate: 'Develop artistic and expressive skills; track performance-based competencies.',
    subjects: ['Visual Arts', 'Performing Arts', 'Music', 'Home Science', 'Physical Education'],
    hodResponsibilities: [
      'Moderate practical evaluations',
      'Track talent identification',
      'Approve exhibition schedules',
    ],
    memberResponsibilities: [
      'Record portfolio uploads',
      'Log performance assessments',
      'Track participation',
    ],
    reportTypes: [
      'Talent Development Report',
      'Performance Growth Trends',
      'Participation Analytics',
    ],
    complianceItems: [
      'Portfolio assessments completed',
      'Exhibition schedule approved',
      'Talent identification records updated',
      'Performance rubrics distributed',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'portfolio',
        title: 'Performance Portfolio Manager',
        description: 'Upload and track learner portfolio evidence',
        icon: Icons.collections_outlined,
        color: const Color(0xFFAD1457),
        fields: [
          ModuleField(key: 'learner_id', label: 'Learner Name / ID'),
          ModuleField(key: 'skill_area', label: 'Skill Area', type: ModuleFieldType.dropdown,
              options: ['Visual Art', 'Music', 'Drama / Theatre', 'Dance', 'Craft', 'Digital Art']),
          ModuleField(key: 'evidence', label: 'Upload Portfolio Evidence (photo/scan)', type: ModuleFieldType.upload),
          ModuleField(key: 'remarks', label: 'Assessment Remarks', type: ModuleFieldType.multiline),
        ],
      ),
      ModuleConfig(
        moduleType: 'talent_log',
        title: 'Talent Identification Log',
        description: 'Flag and track identified talented learners',
        icon: Icons.star_outlined,
        color: Colors.amber,
        fields: [
          ModuleField(key: 'learner_id', label: 'Learner Name / ID'),
          ModuleField(key: 'talent_area', label: 'Talent Area'),
          ModuleField(key: 'talent_level', label: 'Level', type: ModuleFieldType.dropdown,
              options: ['Emerging', 'Promising', 'Exceptional']),
          ModuleField(key: 'recommendation', label: 'Recommended Action', type: ModuleFieldType.multiline),
        ],
      ),
      ModuleConfig(
        moduleType: 'exhibition',
        title: 'Exhibition Planner',
        description: 'Schedule and track art exhibitions and performances',
        icon: Icons.event_outlined,
        color: Colors.purple,
        fields: [
          ModuleField(key: 'title', label: 'Exhibition / Performance Title'),
          ModuleField(key: 'date', label: 'Scheduled Date', type: ModuleFieldType.date),
          ModuleField(key: 'venue', label: 'Venue'),
          ModuleField(key: 'description', label: 'Exhibition Description', type: ModuleFieldType.multiline),
          ModuleField(key: 'flyer', label: 'Upload Programme / Flyer', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 6. Technical & Applied Sciences ──────────────────────────────────────────
  'technical': DeptConfig(
    name: 'Technical & Applied Sciences Department',
    icon: Icons.build_outlined,
    color: const Color(0xFF37474F),
    mandate: 'Practical skill development, workshop safety compliance, and competency certification.',
    subjects: ['Agriculture', 'Home Science', 'Business Studies', 'Power & Machinery'],
    hodResponsibilities: [
      'Monitor workshop use',
      'Approve tool allocation',
      'Track competency certification',
    ],
    memberResponsibilities: [
      'Record workshop sessions',
      'Log tool usage',
      'Submit skill competency assessments',
    ],
    reportTypes: [
      'Skill Competency Matrix',
      'Tool Usage Log',
      'Safety Inspection Report',
    ],
    complianceItems: [
      'Workshop safety inspection completed',
      'Tool register updated',
      'Skill competency records uploaded',
      'PPE availability confirmed',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'workshop_booking',
        title: 'Workshop Booking',
        description: 'Schedule and record workshop session usage',
        icon: Icons.handyman_outlined,
        color: const Color(0xFF37474F),
        fields: [
          ModuleField(key: 'class_name', label: 'Class'),
          ModuleField(key: 'project', label: 'Practical Project'),
          ModuleField(key: 'date', label: 'Session Date', type: ModuleFieldType.date),
          ModuleField(key: 'tools_used', label: 'Tools Required', type: ModuleFieldType.multiline),
        ],
      ),
      ModuleConfig(
        moduleType: 'skill_cert',
        title: 'Skill Certification Tracker',
        description: 'Record learner competency certifications',
        icon: Icons.workspace_premium_outlined,
        color: Colors.amber,
        fields: [
          ModuleField(key: 'learner_id', label: 'Learner Name / ID'),
          ModuleField(key: 'skill', label: 'Skill / Competency Area'),
          ModuleField(key: 'level', label: 'Competency Level', type: ModuleFieldType.dropdown,
              options: ['Introductory', 'Intermediate', 'Advanced', 'Certified']),
          ModuleField(key: 'cert_doc', label: 'Upload Certificate / Evidence', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'tool_inventory',
        title: 'Tool Inventory System',
        description: 'Track workshop tools and their condition',
        icon: Icons.inventory_outlined,
        color: Colors.blueGrey,
        fields: [
          ModuleField(key: 'tool_name', label: 'Tool Name'),
          ModuleField(key: 'quantity', label: 'Quantity', type: ModuleFieldType.number),
          ModuleField(key: 'condition', label: 'Condition', type: ModuleFieldType.dropdown,
              options: ['Good', 'Fair', 'Needs Repair', 'Condemned']),
        ],
      ),
    ],
  ),

  // ── 7. Religious Education ────────────────────────────────────────────────────
  'religious_ed': DeptConfig(
    name: 'Religious Education Department',
    icon: Icons.self_improvement_outlined,
    color: const Color(0xFF4527A0),
    mandate: 'Moral development and spiritual literacy across all faith traditions.',
    subjects: ['CRE', 'IRE', 'HRE'],
    hodResponsibilities: [
      'Moderate project assessments',
      'Review value-based evaluations',
      'Coordinate observance events',
    ],
    memberResponsibilities: [
      'Record moral competency assessments',
      'Log observance event participation',
      'Upload project evaluations',
    ],
    reportTypes: [
      'Moral Competency Trends',
      'Participation in Observances',
      'Community Engagement Summary',
    ],
    complianceItems: [
      'Faith-based project assessments completed',
      'Observance calendar shared',
      'Value rubrics distributed',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'moral_assessment',
        title: 'Moral Competency Assessment',
        description: 'Record learner moral/value competency scores',
        icon: Icons.favorite_outline,
        color: const Color(0xFF4527A0),
        fields: [
          ModuleField(key: 'theme', label: 'Value Theme', type: ModuleFieldType.dropdown,
              options: ['Respect', 'Integrity', 'Responsibility', 'Compassion', 'Patriotism']),
          ModuleField(key: 'score', label: 'Class Average', type: ModuleFieldType.dropdown,
              options: ['EE', 'ME', 'AE', 'BE']),
          ModuleField(key: 'remarks', label: 'Teacher Remarks', type: ModuleFieldType.multiline),
        ],
      ),
      ModuleConfig(
        moduleType: 'observance_event',
        title: 'Observance Event Log',
        description: 'Plan and log faith observance events',
        icon: Icons.event_outlined,
        color: Colors.indigo,
        fields: [
          ModuleField(key: 'event_name', label: 'Event Name'),
          ModuleField(key: 'faith', label: 'Faith Tradition', type: ModuleFieldType.dropdown,
              options: ['Christian', 'Islamic', 'Hindu', 'Interfaith', 'Cultural']),
          ModuleField(key: 'date', label: 'Event Date', type: ModuleFieldType.date),
          ModuleField(key: 'attendance', label: 'Learner Attendance Count', type: ModuleFieldType.number),
          ModuleField(key: 'report', label: 'Upload Event Report/Photos', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 8. Examinations ───────────────────────────────────────────────────────────
  'examinations': DeptConfig(
    name: 'Examinations Department',
    icon: Icons.fact_check_outlined,
    color: const Color(0xFF1B5E20),
    mandate: 'Coordinate internal assessments and ensure exam integrity.',
    subjects: ['All Subjects (Coordinating)'],
    hodResponsibilities: [
      'Build exam timetable',
      'Assign paper setters',
      'Oversee moderation',
      'Publish results',
    ],
    memberResponsibilities: [
      'Set assigned exam papers',
      'Invigilate assigned sessions',
      'Submit marked scripts promptly',
    ],
    reportTypes: [
      'Exam Completion Report',
      'Mark Distribution Summary',
      'Moderation Outcomes',
      'Results Publication Log',
    ],
    complianceItems: [
      'Exam timetable shared with all staff',
      'Question papers moderated',
      'Answer scripts secured post-exam',
      'Results entered and verified',
      'Invigilation roster posted',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'exam_builder',
        title: 'Exam Builder',
        description: 'Log and track exam paper development',
        icon: Icons.edit_document,
        color: const Color(0xFF1B5E20),
        fields: [
          ModuleField(key: 'subject', label: 'Subject'),
          ModuleField(key: 'paper_type', label: 'Paper Type', type: ModuleFieldType.dropdown,
              options: ['CAT', 'Mid-Term', 'End of Term', 'Mock', 'Practice']),
          ModuleField(key: 'set_by', label: 'Paper Setter'),
          ModuleField(key: 'moderation_date', label: 'Moderation Date', type: ModuleFieldType.date),
          ModuleField(key: 'paper_upload', label: 'Upload Draft Paper (secure)', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'mark_audit',
        title: 'Mark Entry Audit',
        description: 'Track mark submission status per subject',
        icon: Icons.fact_check_outlined,
        color: Colors.green,
        fields: [
          ModuleField(key: 'subject', label: 'Subject'),
          ModuleField(key: 'class_name', label: 'Class'),
          ModuleField(key: 'marks_entered', label: 'Marks Entered By'),
          ModuleField(key: 'status', label: 'Status', type: ModuleFieldType.dropdown,
              options: ['Submitted', 'Verified', 'Published', 'Query']),
        ],
      ),
      ModuleConfig(
        moduleType: 'moderation_workflow',
        title: 'Moderation Workflow',
        description: 'Record paper and script moderation outcomes',
        icon: Icons.rule_outlined,
        color: Colors.orange,
        fields: [
          ModuleField(key: 'subject', label: 'Subject'),
          ModuleField(key: 'moderator', label: 'Moderator Name'),
          ModuleField(key: 'outcome', label: 'Moderation Outcome', type: ModuleFieldType.dropdown,
              options: ['Approved', 'Minor Revisions', 'Major Revisions', 'Rejected']),
          ModuleField(key: 'remarks', label: 'Remarks', type: ModuleFieldType.multiline),
          ModuleField(key: 'doc', label: 'Upload Moderation Form', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 9. Guidance & Counseling ──────────────────────────────────────────────────
  'counseling': DeptConfig(
    name: 'Guidance & Counseling',
    icon: Icons.support_outlined,
    color: const Color(0xFF00838F),
    mandate: 'Student welfare, emotional support, and confidential case management.',
    subjects: ['Counseling & Guidance'],
    hodResponsibilities: [
      'Maintain confidential case files',
      'Track intervention outcomes',
      'Flag high-risk learners',
    ],
    memberResponsibilities: [
      'Conduct welfare check-ins',
      'Record referrals',
      'Log intervention sessions',
    ],
    reportTypes: [
      'Case Load Summary',
      'Risk Indicator Dashboard',
      'Referral Outcomes Report',
    ],
    complianceItems: [
      'All case files secured and updated',
      'High-risk learners reviewed with HOD',
      'External referrals documented',
      'Monthly counseling summary submitted',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'case_mgmt',
        title: 'Case Management',
        description: 'Log confidential learner support cases',
        icon: Icons.folder_outlined,
        color: const Color(0xFF00838F),
        fields: [
          ModuleField(key: 'case_id', label: 'Case Reference Code'),
          ModuleField(key: 'category', label: 'Issue Category', type: ModuleFieldType.dropdown,
              options: ['Emotional', 'Social', 'Academic', 'Family', 'Behavioural', 'Health', 'Abuse']),
          ModuleField(key: 'risk_level', label: 'Risk Level', type: ModuleFieldType.dropdown,
              options: ['Low', 'Medium', 'High', 'Critical']),
          ModuleField(key: 'action', label: 'Action Taken', type: ModuleFieldType.multiline),
          ModuleField(key: 'case_doc', label: 'Upload Case Notes (confidential)', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'referral',
        title: 'Referral Tracker',
        description: 'Track external referrals to specialists',
        icon: Icons.swap_horiz_outlined,
        color: Colors.teal,
        fields: [
          ModuleField(key: 'referral_to', label: 'Referred To (Agency / Specialist)'),
          ModuleField(key: 'reason', label: 'Reason for Referral', type: ModuleFieldType.multiline),
          ModuleField(key: 'date', label: 'Referral Date', type: ModuleFieldType.date),
          ModuleField(key: 'outcome', label: 'Outcome', type: ModuleFieldType.dropdown,
              options: ['Pending', 'Accepted', 'In Progress', 'Completed', 'Declined']),
        ],
      ),
    ],
  ),

  // ── 10. ICT Department ────────────────────────────────────────────────────────
  'ict': DeptConfig(
    name: 'ICT Department',
    icon: Icons.computer_outlined,
    color: const Color(0xFF0277BD),
    mandate: 'System stability, device management, and user access control.',
    subjects: ['Computer Studies', 'ICT / Digital Literacy'],
    hodResponsibilities: [
      'Oversee device inventory',
      'Manage user access logs',
      'Coordinate incident resolution',
    ],
    memberResponsibilities: [
      'Log device issues',
      'Conduct access audits',
      'Monitor network status',
    ],
    reportTypes: [
      'Device Status Report',
      'Access Audit Summary',
      'Incident Resolution Log',
      'Network Uptime Report',
    ],
    complianceItems: [
      'Device inventory audited this term',
      'Unauthorized access reports cleared',
      'Network stability checks completed',
      'Student ICT usage policy acknowledged',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'device_inventory',
        title: 'Device Inventory',
        description: 'Track all school ICT devices and their status',
        icon: Icons.devices_outlined,
        color: const Color(0xFF0277BD),
        fields: [
          ModuleField(key: 'device_type', label: 'Device Type', type: ModuleFieldType.dropdown,
              options: ['Laptop', 'Desktop', 'Tablet', 'Projector', 'Printer', 'Server', 'Router']),
          ModuleField(key: 'serial', label: 'Serial Number / Asset Tag'),
          ModuleField(key: 'location', label: 'Location / Room'),
          ModuleField(key: 'condition', label: 'Condition', type: ModuleFieldType.dropdown,
              options: ['Working', 'Needs Repair', 'Under Repair', 'Condemned']),
          ModuleField(key: 'photo', label: 'Upload Device Photo', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'ict_incident',
        title: 'ICT Incident Reporting',
        description: 'Log technical incidents and resolutions',
        icon: Icons.bug_report_outlined,
        color: Colors.red,
        fields: [
          ModuleField(key: 'incident_type', label: 'Incident Type', type: ModuleFieldType.dropdown,
              options: ['Network Outage', 'Device Failure', 'Security Breach', 'Data Loss', 'Software Bug', 'Other']),
          ModuleField(key: 'description', label: 'Description', type: ModuleFieldType.multiline),
          ModuleField(key: 'resolution', label: 'Resolution / Action Taken', type: ModuleFieldType.multiline),
          ModuleField(key: 'doc', label: 'Upload Incident Report', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 11. Discipline Department ─────────────────────────────────────────────────
  'discipline': DeptConfig(
    name: 'Discipline Department',
    icon: Icons.gavel_outlined,
    color: const Color(0xFFB71C1C),
    mandate: 'Maintain student behavior standards and coordinate parent notification.',
    subjects: ['Cross-Cutting (All Classes)'],
    hodResponsibilities: [
      'Review all escalated cases',
      'Coordinate parent meetings',
      'Authorize detentions',
    ],
    memberResponsibilities: [
      'Report incidents promptly',
      'Log detention records',
      'Notify parents of violations',
    ],
    reportTypes: [
      'Incident Count by Category',
      'Behavior Trend Analytics',
      'Detention Log Summary',
      'Parent Communication Report',
    ],
    complianceItems: [
      'All incidents logged within 24 hours',
      'Parent notifications sent for major incidents',
      'Detention register updated',
      'Monthly behavior summary submitted to HOD',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'behavior_incident',
        title: 'Incident Reporting',
        description: 'Log learner behavior incidents',
        icon: Icons.report_outlined,
        color: const Color(0xFFB71C1C),
        fields: [
          ModuleField(key: 'learner_id', label: 'Learner Name / ID'),
          ModuleField(key: 'category', label: 'Incident Category', type: ModuleFieldType.dropdown,
              options: ['Bullying', 'Disruption', 'Vandalism', 'Defiance', 'Truancy', 'Lateness', 'Theft', 'Violence', 'Other']),
          ModuleField(key: 'description', label: 'Incident Description', type: ModuleFieldType.multiline),
          ModuleField(key: 'action', label: 'Action Taken'),
          ModuleField(key: 'parent_notified', label: 'Parent Notified?', type: ModuleFieldType.dropdown,
              options: ['Yes - Called', 'Yes - SMS', 'Yes - Meeting', 'No - Minor', 'No - Pending']),
        ],
      ),
      ModuleConfig(
        moduleType: 'detention_log',
        title: 'Detention Log',
        description: 'Record detention assignments and completions',
        icon: Icons.lock_clock_outlined,
        color: Colors.orange,
        fields: [
          ModuleField(key: 'learner_id', label: 'Learner Name / ID'),
          ModuleField(key: 'reason', label: 'Reason for Detention'),
          ModuleField(key: 'date', label: 'Detention Date', type: ModuleFieldType.date),
          ModuleField(key: 'supervisor', label: 'Supervising Teacher'),
        ],
      ),
    ],
  ),

  // ── 12. Co-Curricular Department ──────────────────────────────────────────────
  'cocurricular': DeptConfig(
    name: 'Co-Curricular Department',
    icon: Icons.sports_outlined,
    color: const Color(0xFF2E7D32),
    mandate: 'Clubs & sports coordination, event planning, and participation analytics.',
    subjects: ['Sports', 'Clubs & Societies'],
    hodResponsibilities: [
      'Approve new clubs',
      'Oversee events calendar',
      'Track trophy / competition records',
    ],
    memberResponsibilities: [
      'Update club membership lists',
      'Log event participation',
      'Submit activity reports',
    ],
    reportTypes: [
      'Club Membership Summary',
      'Event Participation Report',
      'Trophy / Competition Log',
    ],
    complianceItems: [
      'All active clubs registered',
      'Club constitutions on file',
      'Annual events calendar submitted',
      'Sports equipment inventory updated',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'club_membership',
        title: 'Club Membership Tracker',
        description: 'Manage club rosters and membership',
        icon: Icons.group_outlined,
        color: const Color(0xFF2E7D32),
        fields: [
          ModuleField(key: 'club_name', label: 'Club Name'),
          ModuleField(key: 'patron', label: 'Club Patron / Advisor'),
          ModuleField(key: 'member_count', label: 'Number of Members', type: ModuleFieldType.number),
          ModuleField(key: 'meeting_day', label: 'Regular Meeting Day'),
          ModuleField(key: 'roster', label: 'Upload Member Roster', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'event_planner',
        title: 'Event Planner',
        description: 'Schedule and track school events',
        icon: Icons.event_note_outlined,
        color: Colors.blue,
        fields: [
          ModuleField(key: 'event_name', label: 'Event Name'),
          ModuleField(key: 'event_type', label: 'Type', type: ModuleFieldType.dropdown,
              options: ['Sports Day', 'Drama Festival', 'Music Competition', 'Science Fair', 'Debate', 'Other']),
          ModuleField(key: 'date', label: 'Event Date', type: ModuleFieldType.date),
          ModuleField(key: 'venue', label: 'Venue'),
          ModuleField(key: 'participants', label: 'Number of Participants', type: ModuleFieldType.number),
          ModuleField(key: 'programme', label: 'Upload Programme / Results', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'trophy_log',
        title: 'Trophy & Competition Log',
        description: 'Record competition results and achievements',
        icon: Icons.emoji_events_outlined,
        color: Colors.amber,
        fields: [
          ModuleField(key: 'competition', label: 'Competition / Tournament Name'),
          ModuleField(key: 'level', label: 'Level', type: ModuleFieldType.dropdown,
              options: ['School', 'Zone', 'Sub-County', 'County', 'National']),
          ModuleField(key: 'result', label: 'Result / Position'),
          ModuleField(key: 'team_members', label: 'Team Members', type: ModuleFieldType.multiline),
          ModuleField(key: 'photo', label: 'Upload Trophy Photo / Certificate', type: ModuleFieldType.upload),
        ],
      ),
    ],
  ),

  // ── 13. Special Needs Education ────────────────────────────────────────────────
  'special_needs': DeptConfig(
    name: 'Special Needs Education',
    icon: Icons.accessibility_new_outlined,
    color: const Color(0xFF4A148C),
    mandate: 'Inclusive education compliance and learner support.',
    subjects: ['SNE Support (Cross-Cutting)'],
    hodResponsibilities: [
      'Review all IEPs',
      'Ensure accommodation compliance',
      'Monitor learner progress',
    ],
    memberResponsibilities: [
      'Develop and update IEPs',
      'Record accommodation logs',
      'Track intervention progress',
    ],
    reportTypes: [
      'IEP Progress Summary',
      'Accommodation Compliance Report',
      'Inclusive Education Index',
    ],
    complianceItems: [
      'IEPs developed for all identified learners',
      'Accommodations implemented in classrooms',
      'SNE screening conducted this term',
      'Progress reviews completed with parents',
    ],
    modules: [
      ModuleConfig(
        moduleType: 'iep',
        title: 'IEP Tracker',
        description: 'Manage Individual Education Plans',
        icon: Icons.person_pin_outlined,
        color: const Color(0xFF4A148C),
        fields: [
          ModuleField(key: 'learner_id', label: 'Learner Name / ID'),
          ModuleField(key: 'disability_type', label: 'Identified Need', type: ModuleFieldType.dropdown,
              options: ['Visual Impairment', 'Hearing Impairment', 'Physical', 'Intellectual', 'Autism', 'Learning Difficulty', 'Other']),
          ModuleField(key: 'goals', label: 'IEP Goals', type: ModuleFieldType.multiline),
          ModuleField(key: 'accommodations', label: 'Accommodations Provided', type: ModuleFieldType.multiline),
          ModuleField(key: 'review_date', label: 'Next Review Date', type: ModuleFieldType.date),
          ModuleField(key: 'iep_doc', label: 'Upload Signed IEP Document', type: ModuleFieldType.upload),
        ],
      ),
      ModuleConfig(
        moduleType: 'accommodation_log',
        title: 'Accommodation Log',
        description: 'Record classroom accommodations provided',
        icon: Icons.tune_outlined,
        color: Colors.deepPurple,
        fields: [
          ModuleField(key: 'learner_id', label: 'Learner Name / ID'),
          ModuleField(key: 'accommodation', label: 'Accommodation Type', type: ModuleFieldType.dropdown,
              options: ['Extra Time', 'Large Print', 'Reader/Scribe', 'Separate Room', 'Assistive Device', 'Other']),
          ModuleField(key: 'subject', label: 'Subject / Context'),
          ModuleField(key: 'date', label: 'Date Applied', type: ModuleFieldType.date),
        ],
      ),
    ],
  ),
};

/// Maps department DB ID to config key.
/// Returns the config if the department name contains a keyword.
DeptConfig? findConfigForDept(String deptName) {
  final lower = deptName.toLowerCase();
  if (lower.contains('language') || lower.contains('english') || lower.contains('kiswahili')) {
    return kDeptConfigs['languages'];
  }
  if (lower.contains('math')) return kDeptConfigs['mathematics'];
  if (lower.contains('science') || lower.contains('technology')) return kDeptConfigs['science'];
  if (lower.contains('humanit') || lower.contains('social')) return kDeptConfigs['humanities'];
  if (lower.contains('art') || lower.contains('creative') || lower.contains('music')) {
    return kDeptConfigs['creative_arts'];
  }
  if (lower.contains('technical') || lower.contains('applied')) return kDeptConfigs['technical'];
  if (lower.contains('religious') || lower.contains('cre') || lower.contains('ire')) {
    return kDeptConfigs['religious_ed'];
  }
  if (lower.contains('exam')) return kDeptConfigs['examinations'];
  if (lower.contains('counsel') || lower.contains('guidance')) return kDeptConfigs['counseling'];
  if (lower.contains('ict') || lower.contains('computer') || lower.contains('digital')) {
    return kDeptConfigs['ict'];
  }
  if (lower.contains('disciplin')) return kDeptConfigs['discipline'];
  if (lower.contains('co-curr') || lower.contains('cocurr') || lower.contains('sport') || lower.contains('club')) {
    return kDeptConfigs['cocurricular'];
  }
  if (lower.contains('special') || lower.contains('sne') || lower.contains('inclusive')) {
    return kDeptConfigs['special_needs'];
  }
  return null;
}
