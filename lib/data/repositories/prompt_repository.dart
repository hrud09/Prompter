import 'package:sqflite/sqflite.dart';

import '../../models/prompt.dart';
import '../../models/prompt_group.dart';
import '../../models/prompt_version.dart';
import '../../shared/services/image_storage_service.dart';
import '../database/app_database.dart';

class PromptRepositoryException implements Exception {
  const PromptRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PromptRepository {
  PromptRepository({
    required AppDatabase database,
    required ImageStorageService imageStorage,
  })  : _database = database,
        _imageStorage = imageStorage;

  static const String _escapeCharacter = '!';

  final AppDatabase _database;
  final ImageStorageService _imageStorage;

  Future<List<Prompt>> fetchAll({String query = '', String? groupId}) {
    final String trimmed = query.trim();
    return _guard<List<Prompt>>(
      (Database db) async {
        final List<String> whereClauses = <String>[];
        final List<Object?> whereArgs = <Object?>[];

        if (trimmed.isNotEmpty) {
          final String pattern = _likePattern(trimmed);
          whereClauses.add('''(
            p.${PromptFields.title} LIKE ? ESCAPE '!'
            OR p.${PromptFields.description} LIKE ? ESCAPE '!'
            OR EXISTS (
              SELECT 1 FROM ${AppDatabase.promptVersionsTable} v
              WHERE v.${PromptVersionFields.promptId} = p.${PromptFields.id}
                AND v.${PromptVersionFields.promptText} LIKE ? ESCAPE '!'
            )
          )''');
          whereArgs.addAll(<Object?>[pattern, pattern, pattern]);
        }

        if (groupId != null) {
          whereClauses.add('''EXISTS (
            SELECT 1 FROM ${AppDatabase.promptGroupMembersTable} m
            WHERE m.${AppDatabase.groupMemberPromptId} = p.${PromptFields.id}
              AND m.${AppDatabase.groupMemberGroupId} = ?
          )''');
          whereArgs.add(groupId);
        }

        final String whereSql =
            whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

        final List<Map<String, Object?>> rows = await db.rawQuery('''
          SELECT p.* FROM ${AppDatabase.promptsTable} p
          $whereSql
          ORDER BY p.${PromptFields.updatedAt} DESC
        ''', whereArgs);

        final List<Prompt> prompts = rows.map(Prompt.fromMap).toList(growable: false);
        return _attachPreviewsAndGroups(db, prompts);
      },
      'Could not load your prompts.',
    );
  }

  Future<Prompt?> findById(String id) {
    return _guard<Prompt?>(
      (Database db) async {
        final List<Map<String, Object?>> rows = await db.query(
          AppDatabase.promptsTable,
          where: '${PromptFields.id} = ?',
          whereArgs: <Object?>[id],
          limit: 1,
        );
        if (rows.isEmpty) {
          return null;
        }
        final List<Prompt> attached = await _attachPreviewsAndGroups(
          db,
          <Prompt>[Prompt.fromMap(rows.first)],
        );
        return attached.first;
      },
      'Could not open that prompt.',
    );
  }

  Future<void> save(Prompt prompt) {
    return _guard<void>(
      (Database db) async {
        await db.insert(
          AppDatabase.promptsTable,
          prompt.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
      'Could not save this prompt.',
    );
  }

  Future<void> delete(Prompt prompt) async {
    final List<String> imagesToDelete = await _guard<List<String>>(
      (Database db) async {
        final List<Map<String, Object?>> versionRows = await db.query(
          AppDatabase.promptVersionsTable,
          where: '${PromptVersionFields.promptId} = ?',
          whereArgs: <Object?>[prompt.id],
        );
        final List<PromptVersion> versions =
            versionRows.map(PromptVersion.fromMap).toList(growable: false);
        final List<String> images = versions
            .expand((PromptVersion version) => version.allImages)
            .toList(growable: false);

        await db.transaction((Transaction txn) async {
          await txn.delete(
            AppDatabase.promptVersionsTable,
            where: '${PromptVersionFields.promptId} = ?',
            whereArgs: <Object?>[prompt.id],
          );
          await txn.delete(
            AppDatabase.promptGroupMembersTable,
            where: '${AppDatabase.groupMemberPromptId} = ?',
            whereArgs: <Object?>[prompt.id],
          );
          await txn.delete(
            AppDatabase.promptsTable,
            where: '${PromptFields.id} = ?',
            whereArgs: <Object?>[prompt.id],
          );
        });
        return images;
      },
      'Could not delete this prompt.',
    );
    await _imageStorage.deleteImages(imagesToDelete);
  }

  Future<List<Prompt>> _attachPreviewsAndGroups(Database db, List<Prompt> prompts) async {
    if (prompts.isEmpty) {
      return prompts;
    }
    final List<String> ids = prompts.map((Prompt prompt) => prompt.id).toList(growable: false);
    final String placeholders = List<String>.filled(ids.length, '?').join(',');

    final List<Map<String, Object?>> versionRows = await db.rawQuery('''
      SELECT * FROM ${AppDatabase.promptVersionsTable}
      WHERE ${PromptVersionFields.promptId} IN ($placeholders)
      ORDER BY ${PromptVersionFields.promptId}, ${PromptVersionFields.orderIndex}
    ''', ids);

    final Map<String, PromptVersion> previewByPromptId = <String, PromptVersion>{};
    final Map<String, int> countByPromptId = <String, int>{};
    for (final Map<String, Object?> row in versionRows) {
      final PromptVersion version = PromptVersion.fromMap(row);
      previewByPromptId.putIfAbsent(version.promptId, () => version);
      countByPromptId.update(
        version.promptId,
        (int value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final List<Map<String, Object?>> groupRows = await db.rawQuery('''
      SELECT m.${AppDatabase.groupMemberPromptId} AS prompt_id, g.*
      FROM ${AppDatabase.promptGroupMembersTable} m
      INNER JOIN ${AppDatabase.promptGroupsTable} g
        ON g.${PromptGroupFields.id} = m.${AppDatabase.groupMemberGroupId}
      WHERE m.${AppDatabase.groupMemberPromptId} IN ($placeholders)
      ORDER BY g.${PromptGroupFields.name}
    ''', ids);

    final Map<String, List<PromptGroup>> groupsByPromptId = <String, List<PromptGroup>>{};
    for (final Map<String, Object?> row in groupRows) {
      final String promptId = row['prompt_id'] as String? ?? '';
      groupsByPromptId.putIfAbsent(promptId, () => <PromptGroup>[]).add(PromptGroup.fromMap(row));
    }

    return prompts
        .map((Prompt prompt) => prompt.copyWith(
              previewVersion: previewByPromptId[prompt.id],
              versionCount: countByPromptId[prompt.id] ?? 0,
              groups: groupsByPromptId[prompt.id] ?? const <PromptGroup>[],
            ))
        .toList(growable: false);
  }

  String _likePattern(String query) {
    final String escaped = query
        .replaceAll(_escapeCharacter, '$_escapeCharacter$_escapeCharacter')
        .replaceAll('%', '$_escapeCharacter%')
        .replaceAll('_', '${_escapeCharacter}_');
    return '%$escaped%';
  }

  Future<T> _guard<T>(
    Future<T> Function(Database db) action,
    String failureMessage,
  ) async {
    try {
      final Database db = await _database.database;
      return await action(db);
    } on Object {
      throw PromptRepositoryException(failureMessage);
    }
  }
}
