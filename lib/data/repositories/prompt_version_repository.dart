import 'package:sqflite/sqflite.dart';

import '../../models/prompt_version.dart';
import '../../shared/services/image_storage_service.dart';
import '../database/app_database.dart';

class PromptVersionRepositoryException implements Exception {
  const PromptVersionRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PromptVersionRepository {
  PromptVersionRepository({
    required AppDatabase database,
    required ImageStorageService imageStorage,
  })  : _database = database,
        _imageStorage = imageStorage;

  final AppDatabase _database;
  final ImageStorageService _imageStorage;

  Future<List<PromptVersion>> fetchForPrompt(String promptId) {
    return _guard<List<PromptVersion>>(
      (Database db) async {
        final List<Map<String, Object?>> rows = await db.query(
          AppDatabase.promptVersionsTable,
          where: '${PromptVersionFields.promptId} = ?',
          whereArgs: <Object?>[promptId],
          orderBy: PromptVersionFields.orderIndex,
        );
        return rows.map(PromptVersion.fromMap).toList(growable: false);
      },
      'Could not load prompt versions.',
    );
  }

  Future<void> save(PromptVersion version) {
    return _guard<void>(
      (Database db) async {
        await db.insert(
          AppDatabase.promptVersionsTable,
          version.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
      'Could not save this version.',
    );
  }

  Future<void> saveAll(Iterable<PromptVersion> versions) {
    return _guard<void>(
      (Database db) async {
        final Batch batch = db.batch();
        for (final PromptVersion version in versions) {
          batch.insert(
            AppDatabase.promptVersionsTable,
            version.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      'Could not save these versions.',
    );
  }

  Future<void> deleteByIds(Iterable<String> versionIds) async {
    final List<String> ids = versionIds.toList(growable: false);
    if (ids.isEmpty) {
      return;
    }
    final List<PromptVersion> versions = await _guard<List<PromptVersion>>(
      (Database db) async {
        final List<Map<String, Object?>> rows = await db.query(
          AppDatabase.promptVersionsTable,
          where:
              '${PromptVersionFields.id} IN (${List<String>.filled(ids.length, '?').join(',')})',
          whereArgs: ids,
        );
        return rows.map(PromptVersion.fromMap).toList(growable: false);
      },
      'Could not delete these versions.',
    );
    await _guard<void>(
      (Database db) async {
        await db.delete(
          AppDatabase.promptVersionsTable,
          where:
              '${PromptVersionFields.id} IN (${List<String>.filled(ids.length, '?').join(',')})',
          whereArgs: ids,
        );
      },
      'Could not delete these versions.',
    );
    for (final PromptVersion version in versions) {
      await _imageStorage.deleteImages(version.allImages);
    }
  }

  Future<T> _guard<T>(
    Future<T> Function(Database db) action,
    String failureMessage,
  ) async {
    try {
      final Database db = await _database.database;
      return await action(db);
    } on Object {
      throw PromptVersionRepositoryException(failureMessage);
    }
  }
}
