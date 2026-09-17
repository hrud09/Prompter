import 'package:flutter_test/flutter_test.dart';
import 'package:prompt_library/models/custom_input.dart';
import 'package:prompt_library/models/prompt.dart';
import 'package:prompt_library/shared/utils/date_formatter.dart';

void main() {
  group('Prompt', () {
    final Prompt prompt = Prompt(
      id: 'abc',
      title: 'Cinematic Fantasy Character',
      description: 'Character portrait prompt.',
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
      final Prompt restored = Prompt.fromMap(prompt.toMap());

      expect(restored.id, prompt.id);
      expect(restored.title, prompt.title);
      expect(restored.description, prompt.description);
      expect(restored.promptText, prompt.promptText);
      expect(restored.referenceImages, prompt.referenceImages);
      expect(restored.outputImages, prompt.outputImages);
      expect(restored.customInputs, prompt.customInputs);
      expect(restored.createdAt, prompt.createdAt);
      expect(restored.updatedAt, prompt.updatedAt);
    });

    test('reports combined image information', () {
      expect(prompt.imageCount, 3);
      expect(prompt.hasImages, isTrue);
      expect(prompt.allImages, <String>['one.jpg', 'two.png', 'three.jpg']);
    });

    test('recovers from malformed stored columns', () {
      final Map<String, Object?> corrupted = Map<String, Object?>.of(prompt.toMap())
        ..[PromptFields.referenceImages] = 'not-json'
        ..[PromptFields.customInputs] = null;

      final Prompt restored = Prompt.fromMap(corrupted);

      expect(restored.referenceImages, isEmpty);
      expect(restored.customInputs, isEmpty);
      expect(restored.outputImages, <String>['three.jpg']);
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
