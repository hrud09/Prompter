import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'custom_input.dart';

class PromptFields {
  const PromptFields._();

  static const String id = 'id';
  static const String title = 'title';
  static const String description = 'description';
  static const String promptText = 'prompt_text';
  static const String referenceImages = 'reference_images';
  static const String outputImages = 'output_images';
  static const String customInputs = 'custom_inputs';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

@immutable
class Prompt {
  const Prompt({
    required this.id,
    required this.title,
    required this.description,
    required this.promptText,
    required this.createdAt,
    required this.updatedAt,
    this.referenceImages = const <String>[],
    this.outputImages = const <String>[],
    this.customInputs = const <CustomInput>[],
  });

  factory Prompt.fromMap(Map<String, Object?> map) {
    return Prompt(
      id: map[PromptFields.id] as String? ?? '',
      title: map[PromptFields.title] as String? ?? '',
      description: map[PromptFields.description] as String? ?? '',
      promptText: map[PromptFields.promptText] as String? ?? '',
      referenceImages: _decodeImages(map[PromptFields.referenceImages]),
      outputImages: _decodeImages(map[PromptFields.outputImages]),
      customInputs: _decodeCustomInputs(map[PromptFields.customInputs]),
      createdAt: _decodeDate(map[PromptFields.createdAt]),
      updatedAt: _decodeDate(map[PromptFields.updatedAt]),
    );
  }

  final String id;
  final String title;
  final String description;
  final String promptText;
  final List<String> referenceImages;
  final List<String> outputImages;
  final List<CustomInput> customInputs;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<String> get allImages => <String>[...referenceImages, ...outputImages];

  int get imageCount => referenceImages.length + outputImages.length;

  bool get hasImages => imageCount > 0;

  Prompt copyWith({
    String? title,
    String? description,
    String? promptText,
    List<String>? referenceImages,
    List<String>? outputImages,
    List<CustomInput>? customInputs,
    DateTime? updatedAt,
  }) {
    return Prompt(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
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
      PromptFields.id: id,
      PromptFields.title: title,
      PromptFields.description: description,
      PromptFields.promptText: promptText,
      PromptFields.referenceImages: jsonEncode(referenceImages),
      PromptFields.outputImages: jsonEncode(outputImages),
      PromptFields.customInputs:
          jsonEncode(customInputs.map((CustomInput input) => input.toJson()).toList()),
      PromptFields.createdAt: createdAt.toUtc().millisecondsSinceEpoch,
      PromptFields.updatedAt: updatedAt.toUtc().millisecondsSinceEpoch,
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
