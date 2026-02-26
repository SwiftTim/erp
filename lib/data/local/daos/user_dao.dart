// lib/data/local/daos/user_dao.dart

import 'package:floor/floor.dart';
import '../../models/user_model.dart';

@dao
abstract class UserDao {
  @Query('SELECT * FROM users WHERE id = :id')
  Future<UserModel?> findById(String id);

  @Query('SELECT * FROM users WHERE email = :email LIMIT 1')
  Future<UserModel?> findByEmail(String email);

  @Query('SELECT * FROM users WHERE is_active = 1 ORDER BY role_level, name')
  Future<List<UserModel>> findAllActive();

  @Query('SELECT * FROM users')
  Future<List<UserModel>> findAll();

  @Query('SELECT COUNT(*) FROM users')
  Future<int?> countAll();

  @Query('SELECT * FROM users WHERE role_level = :roleLevel AND is_active = 1')
  Future<List<UserModel>> findByRole(int roleLevel);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertUser(UserModel user);

  @update
  Future<void> updateUser(UserModel user);

  @Query('UPDATE users SET is_active = :active WHERE id = :id')
  Future<void> setActive(String id, int active);

  @delete
  Future<void> deleteUser(UserModel user);
}
