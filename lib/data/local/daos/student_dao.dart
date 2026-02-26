// lib/data/local/daos/student_dao.dart

import 'package:floor/floor.dart';
import '../../models/student_model.dart';

@dao
abstract class StudentDao {
  @Query('SELECT * FROM students WHERE id = :id')
  Future<StudentModel?> findById(String id);

  @Query('SELECT * FROM students WHERE upi = :upi LIMIT 1')
  Future<StudentModel?> findByUpi(String upi);

  @Query('SELECT * FROM students WHERE class_id = :classId ORDER BY full_name')
  Future<List<StudentModel>> findByClass(String classId);

  @Query('SELECT * FROM students WHERE grade = :grade ORDER BY full_name')
  Future<List<StudentModel>> findByGrade(String grade);

  @Query('SELECT * FROM students WHERE parent_id = :parentId ORDER BY full_name')
  Future<List<StudentModel>> findByParent(String parentId);

  @Query("SELECT * FROM students WHERE full_name LIKE '%' || :query || '%' ORDER BY full_name")
  Future<List<StudentModel>> searchByName(String query);

  @Query('SELECT COUNT(*) FROM students')
  Future<int?> countAll();

  @Query('SELECT * FROM students ORDER BY full_name')
  Future<List<StudentModel>> findAll();

  @Query('SELECT * FROM students WHERE synced = 0')
  Future<List<StudentModel>> findUnsynced();

  @Query('UPDATE students SET synced = 1 WHERE id = :id')
  Future<void> markSynced(String id);

  @insert
  Future<void> insertStudent(StudentModel student);

  @update
  Future<void> updateStudent(StudentModel student);

  @delete
  Future<void> deleteStudent(StudentModel student);
}
