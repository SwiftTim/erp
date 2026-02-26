// lib/data/models/medical_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'medical_records')
class MedicalRecordModel {
  @PrimaryKey()
  @ColumnInfo(name: 'student_id')
  final String studentId;
  final String? allergies;           // Red-flag JSON: ["Peanuts", "Dust"]
  @ColumnInfo(name: 'chronic_conditions')
  final String? chronicConditions;
  @ColumnInfo(name: 'blood_group')
  final String? bloodGroup;
  @ColumnInfo(name: 'emergency_contacts')
  final String? emergencyContacts;   // JSON: [{name: "Dad", phone: "..."}]

  const MedicalRecordModel({
    required this.studentId,
    this.allergies,
    this.chronicConditions,
    this.bloodGroup,
    this.emergencyContacts,
  });
}

@Entity(tableName: 'clinic_visits')
class ClinicVisitModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  final String symptoms;
  @ColumnInfo(name: 'action_taken')
  final String actionTaken;
  @ColumnInfo(name: 'medication_given')
  final String? medicationGiven;
  final int timestamp;               // Unix epoch ms
  @ColumnInfo(name: 'recorded_by')
  final String recordedBy;           // Nurse ID

  const ClinicVisitModel({
    required this.id,
    required this.studentId,
    required this.symptoms,
    required this.actionTaken,
    this.medicationGiven,
    required this.timestamp,
    required this.recordedBy,
  });
}
