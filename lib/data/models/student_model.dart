// lib/data/models/student_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'students')
class StudentModel {
  @PrimaryKey()
  final String id;
  final String upi;          // Unique Personal Identification
  @ColumnInfo(name: 'full_name')
  final String fullName;
  final String gender;       // Male | Female
  final String dob;          // YYYY-MM-DD
  final String grade;        // PP1, PP2, Grade 1 … Grade 9
  @ColumnInfo(name: 'class_id')
  final String classId;
  @ColumnInfo(name: 'parent_id')
  final String? parentId;
  @ColumnInfo(name: 'photo_url')
  final String? photoUrl;
  @ColumnInfo(name: 'created_at')
  final int createdAt;
  final int synced;          // 0=local, 1=synced

  const StudentModel({
    required this.id,
    required this.upi,
    required this.fullName,
    required this.gender,
    required this.dob,
    required this.grade,
    required this.classId,
    this.parentId,
    this.photoUrl,
    required this.createdAt,
    this.synced = 0,
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'upi': upi,
        'fullName': fullName,
        'gender': gender,
        'dob': dob,
        'grade': grade,
        'classId': classId,
        'parentId': parentId,
        'photoUrl': photoUrl,
        'createdAt': createdAt,
      };

  StudentModel copyWith({
    String? fullName,
    String? gender,
    String? dob,
    String? grade,
    String? classId,
    String? parentId,
    String? photoUrl,
    int? synced,
  }) =>
      StudentModel(
        id: id,
        upi: upi,
        fullName: fullName ?? this.fullName,
        gender: gender ?? this.gender,
        dob: dob ?? this.dob,
        grade: grade ?? this.grade,
        classId: classId ?? this.classId,
        parentId: parentId ?? this.parentId,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
        synced: synced ?? this.synced,
      );
}
