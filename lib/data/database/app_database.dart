import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/prompt.dart';
import '../../models/prompt_group.dart';
import '../../models/prompt_version.dart';

class AppDatabase {
  static const String promptsTable = 'prompts';
  static const String promptVersionsTable = 'prompt_versions';
  static const String promptGroupsTable = 'prompt_groups';
  static const String promptGroupMembersTable = 'prompt_group_members';
  static const String groupMemberPromptId = 'prompt_id';
  static const String groupMemberGroupId = 'group_id';

  static const String _fileName = 'prompt_library.db';
  static const int _schemaVersion = 2;

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
      onCreate: (Database db, int version) async {
        await _createLegacyPromptsTable(db);
        await _migrateToVersionedSchema(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await _migrateToVersionedSchema(db);
        }
      },
    );
  }

  /// The original (schema v1) flat `prompts` table shape, used only as the
  /// starting point for a fresh install before immediately migrating it to
  /// the versioned schema below (keeps `onCreate` and `onUpgrade` sharing a
  /// single migration path).
  Future<void> _createLegacyPromptsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $promptsTable (
        ${PromptFields.id} TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        prompt_text TEXT NOT NULL,
        reference_images TEXT NOT NULL DEFAULT '[]',
        output_images TEXT NOT NULL DEFAULT '[]',
        custom_inputs TEXT NOT NULL DEFAULT '[]',
        ${PromptFields.createdAt} INTEGER NOT NULL,
        ${PromptFields.updatedAt} INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _migrateToVersionedSchema(Database db) async {
    await db.transaction((Transaction txn) async {
      await txn.execute('''
        CREATE TABLE $promptVersionsTable (
          ${PromptVersionFields.id} TEXT PRIMARY KEY,
          ${PromptVersionFields.promptId} TEXT NOT NULL,
          ${PromptVersionFields.label} TEXT NOT NULL,
          ${PromptVersionFields.orderIndex} INTEGER NOT NULL DEFAULT 0,
          ${PromptVersionFields.promptText} TEXT NOT NULL,
          ${PromptVersionFields.referenceImages} TEXT NOT NULL DEFAULT '[]',
          ${PromptVersionFields.outputImages} TEXT NOT NULL DEFAULT '[]',
          ${PromptVersionFields.customInputs} TEXT NOT NULL DEFAULT '[]',
          ${PromptVersionFields.createdAt} INTEGER NOT NULL,
          ${PromptVersionFields.updatedAt} INTEGER NOT NULL
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_prompt_versions_prompt_order '
        'ON $promptVersionsTable (${PromptVersionFields.promptId}, ${PromptVersionFields.orderIndex})',
      );

      await txn.execute('''
        CREATE TABLE $promptGroupsTable (
          ${PromptGroupFields.id} TEXT PRIMARY KEY,
          ${PromptGroupFields.name} TEXT NOT NULL,
          ${PromptGroupFields.description} TEXT NOT NULL DEFAULT '',
          ${PromptGroupFields.createdAt} INTEGER NOT NULL,
          ${PromptGroupFields.updatedAt} INTEGER NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE $promptGroupMembersTable (
          $groupMemberPromptId TEXT NOT NULL,
          $groupMemberGroupId TEXT NOT NULL,
          PRIMARY KEY ($groupMemberPromptId, $groupMemberGroupId)
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_prompt_group_members_group '
        'ON $promptGroupMembersTable ($groupMemberGroupId)',
      );

      final List<Map<String, Object?>> legacyRows = await txn.query(promptsTable);
      for (final Map<String, Object?> row in legacyRows) {
        final int createdAt = row[PromptFields.createdAt] as int? ?? 0;
        final int updatedAt = row[PromptFields.updatedAt] as int? ?? createdAt;
        await txn.insert(promptVersionsTable, <String, Object?>{
          PromptVersionFields.id: '${row[PromptFields.id]}-v1',
          PromptVersionFields.promptId: row[PromptFields.id],
          PromptVersionFields.label: 'Version 1',
          PromptVersionFields.orderIndex: 0,
          PromptVersionFields.promptText: row['prompt_text'] as String? ?? '',
          PromptVersionFields.referenceImages:
              row['reference_images'] as String? ?? '[]',
          PromptVersionFields.outputImages: row['output_images'] as String? ?? '[]',
          PromptVersionFields.customInputs: row['custom_inputs'] as String? ?? '[]',
          PromptVersionFields.createdAt: createdAt,
          PromptVersionFields.updatedAt: updatedAt,
        });
      }

      await txn.execute('''
        CREATE TABLE prompts_new (
          ${PromptFields.id} TEXT PRIMARY KEY,
          ${PromptFields.title} TEXT NOT NULL,
          ${PromptFields.description} TEXT NOT NULL DEFAULT '',
          ${PromptFields.createdAt} INTEGER NOT NULL,
          ${PromptFields.updatedAt} INTEGER NOT NULL
        )
      ''');
      await txn.execute('''
        INSERT INTO prompts_new (${PromptFields.id}, ${PromptFields.title},
          ${PromptFields.description}, ${PromptFields.createdAt}, ${PromptFields.updatedAt})
        SELECT ${PromptFields.id}, title, description, ${PromptFields.createdAt}, ${PromptFields.updatedAt}
        FROM $promptsTable
      ''');
      await txn.execute('DROP TABLE $promptsTable');
      await txn.execute('ALTER TABLE prompts_new RENAME TO $promptsTable');
      await txn.execute(
        'CREATE INDEX idx_prompts_updated_at '
        'ON $promptsTable (${PromptFields.updatedAt} DESC)',
      );
    });
  }
}
