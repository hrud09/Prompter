import 'package:sqflite/sqflite.dart';

import '../../models/prompt.dart';
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
    required this._database,
    required this._imageStorage,
  });

  static const String _escapeCharacter = '!';

  static const String _searchClause =
      "${PromptFields.title} LIKE ? ESCAPE '!' "
      "OR ${PromptFields.description} LIKE ? ESCAPE '!' "
      "OR ${PromptFields.promptText} LIKE ? ESCAPE '!'";

  final AppDatabase _database;
  final ImageStorageService _imageStorage;

  Future<List<Prompt>> fetchAll({String query = ''}) {
    final String trimmed = query.trim();
    return _guard<List<Prompt>>(
      (Database db) async {
        final List<Map<String, Object?>> rows = trimmed.isEmpty
            ? await db.query(
                AppDatabase.promptsTable,
                orderBy: '${PromptFields.updatedAt} DESC',
              )
            : await db.query(
                AppDatabase.promptsTable,
                where: _searchClause,
                whereArgs: List<Object?>.filled(3, _likePattern(trimmed)),
                orderBy: '${PromptFields.updatedAt} DESC',
              );
        return rows.map(Prompt.fromMap).toList(growable: false);
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
        return rows.isEmpty ? null : Prompt.fromMap(rows.first);
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
    await _guard<void>(
      (Database db) async {
        await db.delete(
          AppDatabase.promptsTable,
          where: '${PromptFields.id} = ?',
          whereArgs: <Object?>[prompt.id],
        );
      },
      'Could not delete this prompt.',
    );
    await _imageStorage.deleteImages(prompt.allImages);
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
