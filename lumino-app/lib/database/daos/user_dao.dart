import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<void> upsertUser(UsersCompanion user) =>
      into(users).insert(user, mode: InsertMode.insertOrReplace);

  Future<User?> getUser(String userId) =>
      (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();
}
