// lib/data/models/user_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'users')
class UserModel {
  @PrimaryKey()
  final String id;
  final String name;
  @ColumnInfo(name: 'email')
  final String email;
  @ColumnInfo(name: 'password_hash')
  final String passwordHash;
  @ColumnInfo(name: 'role_level')
  final int roleLevel;           // 1=Headteacher … 5=Parent
  @ColumnInfo(name: 'role_flags')
  final String? roleFlags;       // JSON string: ["HOD", "GAMES", "DISCIPLINE"]
  @ColumnInfo(name: 'assigned_class_id')
  final String? assignedClassId;
  @ColumnInfo(name: 'department_id')
  final String? departmentId;    // For HODs
  @ColumnInfo(name: 'is_active')
  final int isActive;            // 1=active, 0=deactivated
  @ColumnInfo(name: 'created_at')
  final int createdAt;           // Unix epoch ms

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.roleLevel,
    this.roleFlags,
    this.assignedClassId,
    this.departmentId,
    this.isActive = 1,
    required this.createdAt,
  });

  bool hasFlag(String flag) {
    if (roleFlags == null) return false;
    return roleFlags!.contains(flag);
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? passwordHash,
    int? roleLevel,
    String? roleFlags,
    String? assignedClassId,
    String? departmentId,
    int? isActive,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        roleLevel: roleLevel ?? this.roleLevel,
        roleFlags: roleFlags ?? this.roleFlags,
        assignedClassId: assignedClassId ?? this.assignedClassId,
        departmentId: departmentId ?? this.departmentId,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'email': email,
        'roleLevel': roleLevel,
        'roleFlags': roleFlags,
        'assignedClassId': assignedClassId,
        'departmentId': departmentId,
        'isActive': isActive,
        'createdAt': createdAt,
      };
}
