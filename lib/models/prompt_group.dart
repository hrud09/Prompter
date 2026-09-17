import 'package:flutter/foundation.dart';

class PromptGroupFields {
  const PromptGroupFields._();

  static const String id = 'id';
  static const String name = 'name';
  static const String description = 'description';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

@immutable
class PromptGroup {
  const PromptGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
  });

  factory PromptGroup.fromMap(Map<String, Object?> map) {
    return PromptGroup(
      id: map[PromptGroupFields.id] as String? ?? '',
      name: map[PromptGroupFields.name] as String? ?? '',
      description: map[PromptGroupFields.description] as String? ?? '',
      createdAt: _decodeDate(map[PromptGroupFields.createdAt]),
      updatedAt: _decodeDate(map[PromptGroupFields.updatedAt]),
    );
  }

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  PromptGroup copyWith({
    String? name,
    String? description,
    DateTime? updatedAt,
  }) {
    return PromptGroup(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      PromptGroupFields.id: id,
      PromptGroupFields.name: name,
      PromptGroupFields.description: description,
      PromptGroupFields.createdAt: createdAt.toUtc().millisecondsSinceEpoch,
      PromptGroupFields.updatedAt: updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  static DateTime _decodeDate(Object? source) {
    final int millis = source is int ? source : 0;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is PromptGroup && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}
