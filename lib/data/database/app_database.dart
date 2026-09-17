import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/prompt.dart';

class AppDatabase {
  static const String promptsTable = 'prompts';
  static const String _fileName = 'prompt_library.db';
  static const int _schemaVersion = 1;

  Future<Database>? _pending;

  Future<Database> get database async {
    final Future<Database> opening = _pending ??= _open();
    try {
      return await opening;
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final Future<Database>? opening = _pending;
    _pending = null;
    if (opening == null) {
      return;
    }
    final Database database = await opening;
    await database.close();
  }

  Future<Database> _open() async {
    final String directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, _fileName),
      version: _schemaVersion,
      onCreate: _createSchema,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $promptsTable (
        ${PromptFields.id} TEXT PRIMARY KEY,
        ${PromptFields.title} TEXT NOT NULL,
        ${PromptFields.description} TEXT NOT NULL DEFAULT '',
        ${PromptFields.promptText} TEXT NOT NULL,
        ${PromptFields.referenceImages} TEXT NOT NULL DEFAULT '[]',
        ${PromptFields.outputImages} TEXT NOT NULL DEFAULT '[]',
        ${PromptFields.customInputs} TEXT NOT NULL DEFAULT '[]',
        ${PromptFields.createdAt} INTEGER NOT NULL,
        ${PromptFields.updatedAt} INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_prompts_updated_at '
      'ON $promptsTable (${PromptFields.updatedAt} DESC)',
    );
  }
}
