import 'package:flutter_test/flutter_test.dart';
import 'package:prompt_library/models/custom_input.dart';
import 'package:prompt_library/models/prompt.dart';
import 'package:prompt_library/models/prompt_group.dart';
import 'package:prompt_library/models/prompt_version.dart';
import 'package:prompt_library/shared/utils/date_formatter.dart';

void main() {
  group('Prompt', () {
    final Prompt prompt = Prompt(
      id: 'abc',
      title: 'Cinematic Fantasy Character',
      description: 'Character portrait prompt.',
      createdAt: DateTime(2026, 9, 1, 10, 30),
      updatedAt: DateTime(2026, 9, 17, 18, 5),
    );

    test('survives a database map round trip', () {
      final Prompt restored = Prompt.fromMap(prompt.toMap());

      expect(restored.id, prompt.id);
      expect(restored.title, prompt.title);
      expect(restored.description, prompt.description);
      expect(restored.createdAt, prompt.createdAt);
      expect(restored.updatedAt, prompt.updatedAt);
    });

    test('copyWith keeps identity and creation date', () {
      final Prompt updated = prompt.copyWith(
        title: 'New title',
        updatedAt: DateTime(2026, 10, 1),
      );

      expect(updated.id, prompt.id);
      expect(updated.createdAt, prompt.createdAt);
      expect(updated.title, 'New title');
      expect(updated.updatedAt, DateTime(2026, 10, 1));
    });

    test('carries transient preview/version/group data without persisting it', () {
      final PromptVersion version = PromptVersion(
        id: 'v1',
        promptId: 'abc',
        label: 'Version 1',
        orderIndex: 0,
        promptText: 'Some text',
        createdAt: prompt.createdAt,
        updatedAt: prompt.updatedAt,
      );
      final PromptGroup group = PromptGroup(
        id: 'g1',
        name: 'Characters',
        createdAt: prompt.createdAt,
        updatedAt: prompt.updatedAt,
      );
      final Prompt withExtras = prompt.copyWith(
        previewVersion: version,
        versionCount: 2,
        groups: <PromptGroup>[group],
      );

      expect(withExtras.previewVersion, version);
      expect(withExtras.versionCount, 2);
      expect(withExtras.groups, <PromptGroup>[group]);
      expect(withExtras.toMap().containsKey('prompt_text'), isFalse);
    });
  });

  group('PromptVersion', () {
    final PromptVersion version = PromptVersion(
      id: 'v1',
      promptId: 'abc',
      label: 'Version 1',
      orderIndex: 0,
      promptText: 'Create a highly detailed cinematic portrait...',
      referenceImages: const <String>['one.jpg', 'two.png'],
      outputImages: const <String>['three.jpg'],
      customInputs: const <CustomInput>[
        CustomInput(name: 'Model', value: 'Midjourney'),
        CustomInput(name: 'Aspect Ratio', value: '16:9'),
      ],
      createdAt: DateTime(2026, 9, 1, 10, 30),
      updatedAt: DateTime(2026, 9, 17, 18, 5),
    );

    test('survives a database map round trip', () {
      final PromptVersion restored = PromptVersion.fromMap(version.toMap());

      expect(restored.id, version.id);
      expect(restored.promptId, version.promptId);
      expect(restored.label, version.label);
      expect(restored.orderIndex, version.orderIndex);
      expect(restored.promptText, version.promptText);
      expect(restored.referenceImages, version.referenceImages);
      expect(restored.outputImages, version.outputImages);
      expect(restored.customInputs, version.customInputs);
      expect(restored.createdAt, version.createdAt);
      expect(restored.updatedAt, version.updatedAt);
    });

    test('reports combined image information', () {
      expect(version.imageCount, 3);
      expect(version.hasImages, isTrue);
      expect(version.allImages, <String>['one.jpg', 'two.png', 'three.jpg']);
    });

    test('recovers from malformed stored columns', () {
      final Map<String, Object?> corrupted = Map<String, Object?>.of(version.toMap())
        ..[PromptVersionFields.referenceImages] = 'not-json'
        ..[PromptVersionFields.customInputs] = null;

      final PromptVersion restored = PromptVersion.fromMap(corrupted);

      expect(restored.referenceImages, isEmpty);
      expect(restored.customInputs, isEmpty);
      expect(restored.outputImages, <String>['three.jpg']);
    });
  });

  group('PromptGroup', () {
    test('survives a database map round trip', () {
      final PromptGroup group = PromptGroup(
        id: 'g1',
        name: 'Characters',
        description: 'Character prompts',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 2),
      );

      final PromptGroup restored = PromptGroup.fromMap(group.toMap());

      expect(restored.id, group.id);
      expect(restored.name, group.name);
      expect(restored.description, group.description);
      expect(restored.createdAt, group.createdAt);
      expect(restored.updatedAt, group.updatedAt);
    });
  });

  group('DateFormatter', () {
    test('formats dates in the current year without the year', () {
      final DateTime thisYear = DateTime(DateTime.now().year, 9, 17);
      expect(DateFormatter.compact(thisYear), 'Sep 17');
    });

    test('formats older dates with the year', () {
      expect(DateFormatter.compact(DateTime(2021, 3, 4)), 'Mar 4, 2021');
      expect(DateFormatter.full(DateTime(2021, 3, 4)), 'Mar 4, 2021');
    });
  });
}
