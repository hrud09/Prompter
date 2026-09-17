import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'custom_input.dart';

class PromptVersionFields {
  const PromptVersionFields._();

  static const String id = 'id';
  static const String promptId = 'prompt_id';
  static const String label = 'label';
  static const String orderIndex = 'order_index';
  static const String promptText = 'prompt_text';
  static const String referenceImages = 'reference_images';
  static const String outputImages = 'output_images';
  static const String customInputs = 'custom_inputs';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

@immutable
class PromptVersion {
  const PromptVersion({
    required this.id,
    required this.promptId,
    required this.label,
    required this.orderIndex,
    required this.promptText,
    required this.createdAt,
    required this.updatedAt,
    this.referenceImages = const <String>[],
    this.outputImages = const <String>[],
    this.customInputs = const <CustomInput>[],
  });

  factory PromptVersion.fromMap(Map<String, Object?> map) {
    return PromptVersion(
      id: map[PromptVersionFields.id] as String? ?? '',
      promptId: map[PromptVersionFields.promptId] as String? ?? '',
      label: map[PromptVersionFields.label] as String? ?? '',
      orderIndex: map[PromptVersionFields.orderIndex] as int? ?? 0,
      promptText: map[PromptVersionFields.promptText] as String? ?? '',
      referenceImages: _decodeImages(map[PromptVersionFields.referenceImages]),
      outputImages: _decodeImages(map[PromptVersionFields.outputImages]),
      customInputs: _decodeCustomInputs(map[PromptVersionFields.customInputs]),
      createdAt: _decodeDate(map[PromptVersionFields.createdAt]),
      updatedAt: _decodeDate(map[PromptVersionFields.updatedAt]),
    );
  }

  final String id;
  final String promptId;
  final String label;
  final int orderIndex;
  final String promptText;
  final List<String> referenceImages;
  final List<String> outputImages;
  final List<CustomInput> customInputs;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<String> get allImages => <String>[...referenceImages, ...outputImages];

  int get imageCount => referenceImages.length + outputImages.length;

  bool get hasImages => imageCount > 0;

  PromptVersion copyWith({
    String? label,
    int? orderIndex,
    String? promptText,
    List<String>? referenceImages,
    List<String>? outputImages,
    List<CustomInput>? customInputs,
    DateTime? updatedAt,
  }) {
    return PromptVersion(
      id: id,
      promptId: promptId,
      label: label ?? this.label,
      orderIndex: orderIndex ?? this.orderIndex,
      promptText: promptText ?? this.promptText,
      referenceImages: referenceImages ?? this.referenceImages,
      outputImages: outputImages ?? this.outputImages,
      customInputs: customInputs ?? this.customInputs,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      PromptVersionFields.id: id,
      PromptVersionFields.promptId: promptId,
      PromptVersionFields.label: label,
      PromptVersionFields.orderIndex: orderIndex,
      PromptVersionFields.promptText: promptText,
      PromptVersionFields.referenceImages: jsonEncode(referenceImages),
      PromptVersionFields.outputImages: jsonEncode(outputImages),
      PromptVersionFields.customInputs:
          jsonEncode(customInputs.map((CustomInput input) => input.toJson()).toList()),
      PromptVersionFields.createdAt: createdAt.toUtc().millisecondsSinceEpoch,
      PromptVersionFields.updatedAt: updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  static List<String> _decodeImages(Object? source) {
    final Object? decoded = _tryDecode(source);
    if (decoded is! List) {
      return const <String>[];
    }
    return decoded.whereType<String>().toList(growable: false);
  }

  static List<CustomInput> _decodeCustomInputs(Object? source) {
    final Object? decoded = _tryDecode(source);
    if (decoded is! List) {
      return const <CustomInput>[];
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(CustomInput.fromJson)
        .toList(growable: false);
  }

  static Object? _tryDecode(Object? source) {
    if (source is! String || source.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(source);
    } on FormatException {
      return null;
    }
  }

  static DateTime _decodeDate(Object? source) {
    final int millis = source is int ? source : 0;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }
}
