import 'package:flutter/foundation.dart';

import 'prompt_group.dart';
import 'prompt_version.dart';

class PromptFields {
  const PromptFields._();

  static const String id = 'id';
  static const String title = 'title';
  static const String description = 'description';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

@immutable
class Prompt {
  const Prompt({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.previewVersion,
    this.versionCount = 0,
    this.groups = const <PromptGroup>[],
  });

  factory Prompt.fromMap(Map<String, Object?> map) {
    return Prompt(
      id: map[PromptFields.id] as String? ?? '',
      title: map[PromptFields.title] as String? ?? '',
      description: map[PromptFields.description] as String? ?? '',
      createdAt: _decodeDate(map[PromptFields.createdAt]),
      updatedAt: _decodeDate(map[PromptFields.updatedAt]),
    );
  }

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Transient, not persisted on this row: the lowest-`orderIndex` version,
  /// populated by [PromptRepository] for list/card previews.
  final PromptVersion? previewVersion;

  /// Transient, not persisted: total number of versions for this prompt.
  final int versionCount;

  /// Transient, not persisted: groups this prompt belongs to.
  final List<PromptGroup> groups;

  Prompt copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
    PromptVersion? previewVersion,
    int? versionCount,
    List<PromptGroup>? groups,
  }) {
    return Prompt(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      previewVersion: previewVersion ?? this.previewVersion,
      versionCount: versionCount ?? this.versionCount,
      groups: groups ?? this.groups,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      PromptFields.id: id,
      PromptFields.title: title,
      PromptFields.description: description,
      PromptFields.createdAt: createdAt.toUtc().millisecondsSinceEpoch,
      PromptFields.updatedAt: updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  static DateTime _decodeDate(Object? source) {
    final int millis = source is int ? source : 0;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }
}
