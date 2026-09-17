import 'package:sqflite/sqflite.dart';

import '../../models/prompt_group.dart';
import '../database/app_database.dart';

class PromptGroupRepositoryException implements Exception {
  const PromptGroupRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PromptGroupRepository {
  PromptGroupRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<List<PromptGroup>> fetchAll() {
    return _guard<List<PromptGroup>>(
      (Database db) async {
        final List<Map<String, Object?>> rows = await db.query(
          AppDatabase.promptGroupsTable,
          orderBy: PromptGroupFields.name,
        );
        return rows.map(PromptGroup.fromMap).toList(growable: false);
      },
      'Could not load your groups.',
    );
  }

  Future<void> save(PromptGroup group) {
    return _guard<void>(
      (Database db) async {
        await db.insert(
          AppDatabase.promptGroupsTable,
          group.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
      'Could not save this group.',
    );
  }

  Future<void> delete(PromptGroup group) {
    return _guard<void>(
      (Database db) async {
        final Batch batch = db.batch();
        batch.delete(
          AppDatabase.promptGroupMembersTable,
          where: '${AppDatabase.groupMemberGroupId} = ?',
          whereArgs: <Object?>[group.id],
        );
        batch.delete(
          AppDatabase.promptGroupsTable,
          where: '${PromptGroupFields.id} = ?',
          whereArgs: <Object?>[group.id],
        );
        await batch.commit(noResult: true);
      },
      'Could not delete this group.',
    );
  }

  Future<List<PromptGroup>> fetchGroupsForPrompt(String promptId) {
    return _guard<List<PromptGroup>>(
      (Database db) async {
        final List<Map<String, Object?>> rows = await db.rawQuery('''
          SELECT g.* FROM ${AppDatabase.promptGroupsTable} g
          INNER JOIN ${AppDatabase.promptGroupMembersTable} m
            ON m.${AppDatabase.groupMemberGroupId} = g.${PromptGroupFields.id}
          WHERE m.${AppDatabase.groupMemberPromptId} = ?
          ORDER BY g.${PromptGroupFields.name}
        ''', <Object?>[promptId]);
        return rows.map(PromptGroup.fromMap).toList(growable: false);
      },
      'Could not load groups for this prompt.',
    );
  }

  Future<void> setGroupsForPrompt(String promptId, Iterable<String> groupIds) {
    return _guard<void>(
      (Database db) async {
        final Batch batch = db.batch();
        batch.delete(
          AppDatabase.promptGroupMembersTable,
          where: '${AppDatabase.groupMemberPromptId} = ?',
          whereArgs: <Object?>[promptId],
        );
        for (final String groupId in groupIds) {
          batch.insert(
            AppDatabase.promptGroupMembersTable,
            <String, Object?>{
              AppDatabase.groupMemberPromptId: promptId,
              AppDatabase.groupMemberGroupId: groupId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      'Could not update groups for this prompt.',
    );
  }

  Future<void> removePromptFromAllGroups(String promptId) {
    return _guard<void>(
      (Database db) async {
        await db.delete(
          AppDatabase.promptGroupMembersTable,
          where: '${AppDatabase.groupMemberPromptId} = ?',
          whereArgs: <Object?>[promptId],
        );
      },
      'Could not update groups for this prompt.',
    );
  }

  Future<T> _guard<T>(
    Future<T> Function(Database db) action,
    String failureMessage,
  ) async {
    try {
      final Database db = await _database.database;
      return await action(db);
    } on Object {
      throw PromptGroupRepositoryException(failureMessage);
    }
  }
}
