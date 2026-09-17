import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prompt_library/app/app.dart';
import 'package:prompt_library/data/database/app_database.dart';
import 'package:prompt_library/data/repositories/prompt_group_repository.dart';
import 'package:prompt_library/data/repositories/prompt_repository.dart';
import 'package:prompt_library/data/repositories/prompt_version_repository.dart';
import 'package:prompt_library/features/prompts/controllers/groups_controller.dart';
import 'package:prompt_library/features/prompts/controllers/prompts_controller.dart';
import 'package:prompt_library/features/settings/controllers/theme_controller.dart';
import 'package:prompt_library/models/prompt.dart';
import 'package:prompt_library/models/prompt_group.dart';
import 'package:prompt_library/models/prompt_version.dart';
import 'package:prompt_library/shared/services/image_picker_service.dart';
import 'package:prompt_library/shared/services/image_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemoryPromptVersionRepository extends PromptVersionRepository {
  InMemoryPromptVersionRepository()
      : super(database: AppDatabase(), imageStorage: ImageStorageService());

  final Map<String, PromptVersion> versions = <String, PromptVersion>{};

  List<PromptVersion> versionsFor(String promptId) {
    final List<PromptVersion> matches =
        versions.values.where((PromptVersion v) => v.promptId == promptId).toList();
    matches.sort((PromptVersion a, PromptVersion b) => a.orderIndex.compareTo(b.orderIndex));
    return matches;
  }

  @override
  Future<List<PromptVersion>> fetchForPrompt(String promptId) async => versionsFor(promptId);

  @override
  Future<void> save(PromptVersion version) async {
    versions[version.id] = version;
  }

  @override
  Future<void> saveAll(Iterable<PromptVersion> items) async {
    for (final PromptVersion version in items) {
      versions[version.id] = version;
    }
  }

  @override
  Future<void> deleteByIds(Iterable<String> versionIds) async {
    for (final String id in versionIds) {
      versions.remove(id);
    }
  }
}

class InMemoryPromptGroupRepository extends PromptGroupRepository {
  InMemoryPromptGroupRepository() : super(database: AppDatabase());

  final Map<String, PromptGroup> groups = <String, PromptGroup>{};
  final Map<String, Set<String>> membership = <String, Set<String>>{};

  @override
  Future<List<PromptGroup>> fetchAll() async {
    final List<PromptGroup> list = groups.values.toList();
    list.sort((PromptGroup a, PromptGroup b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<void> save(PromptGroup group) async {
    groups[group.id] = group;
  }

  @override
  Future<void> delete(PromptGroup group) async {
    groups.remove(group.id);
    for (final Set<String> ids in membership.values) {
      ids.remove(group.id);
    }
  }

  @override
  Future<List<PromptGroup>> fetchGroupsForPrompt(String promptId) async {
    final Set<String> ids = membership[promptId] ?? const <String>{};
    final List<PromptGroup> list =
        groups.values.where((PromptGroup g) => ids.contains(g.id)).toList();
    list.sort((PromptGroup a, PromptGroup b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<void> setGroupsForPrompt(String promptId, Iterable<String> groupIds) async {
    membership[promptId] = groupIds.toSet();
  }

  @override
  Future<void> removePromptFromAllGroups(String promptId) async {
    membership.remove(promptId);
  }
}

class InMemoryPromptRepository extends PromptRepository {
  InMemoryPromptRepository(this._versionRepository, this._groupRepository)
      : super(database: AppDatabase(), imageStorage: ImageStorageService());

  final InMemoryPromptVersionRepository _versionRepository;
  final InMemoryPromptGroupRepository _groupRepository;

  final Map<String, Prompt> store = <String, Prompt>{};

  @override
  Future<List<Prompt>> fetchAll({String query = '', String? groupId}) async {
    final String needle = query.trim().toLowerCase();
    final List<Prompt> matches = store.values.where((Prompt prompt) {
      if (groupId != null &&
          !(_groupRepository.membership[prompt.id]?.contains(groupId) ?? false)) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      final bool matchesVersionText = _versionRepository
          .versionsFor(prompt.id)
          .any((PromptVersion v) => v.promptText.toLowerCase().contains(needle));
      return prompt.title.toLowerCase().contains(needle) ||
          prompt.description.toLowerCase().contains(needle) ||
          matchesVersionText;
    }).toList();
    matches.sort((Prompt a, Prompt b) => b.updatedAt.compareTo(a.updatedAt));
    return Future.wait(matches.map(_attach));
  }

  @override
  Future<Prompt?> findById(String id) async {
    final Prompt? prompt = store[id];
    return prompt == null ? null : _attach(prompt);
  }

  Future<Prompt> _attach(Prompt prompt) async {
    final List<PromptVersion> versions = _versionRepository.versionsFor(prompt.id);
    final List<PromptGroup> groups = await _groupRepository.fetchGroupsForPrompt(prompt.id);
    return prompt.copyWith(
      previewVersion: versions.isEmpty ? null : versions.first,
      versionCount: versions.length,
      groups: groups,
    );
  }

  @override
  Future<void> save(Prompt prompt) async {
    store[prompt.id] = prompt;
  }

  @override
  Future<void> delete(Prompt prompt) async {
    store.remove(prompt.id);
    final List<String> versionIds =
        _versionRepository.versionsFor(prompt.id).map((PromptVersion v) => v.id).toList();
    await _versionRepository.deleteByIds(versionIds);
    await _groupRepository.removePromptFromAllGroups(prompt.id);
  }
}

Future<Widget> buildTestApp(
  InMemoryPromptRepository repository,
  InMemoryPromptVersionRepository versionRepository,
  InMemoryPromptGroupRepository groupRepository,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  return MultiProvider(
    providers: <SingleChildWidget>[
      Provider<ImageStorageService>(
        create: (BuildContext context) => ImageStorageService(),
      ),
      Provider<ImagePickerService>(
        create: (BuildContext context) => ImagePickerService(),
      ),
      Provider<PromptRepository>.value(value: repository),
      Provider<PromptVersionRepository>.value(value: versionRepository),
      Provider<PromptGroupRepository>.value(value: groupRepository),
      ChangeNotifierProvider<ThemeController>(
        create: (BuildContext context) => ThemeController(preferences),
      ),
      ChangeNotifierProvider<PromptsController>(
        create: (BuildContext context) => PromptsController(repository)..load(),
      ),
      ChangeNotifierProvider<GroupsController>(
        create: (BuildContext context) => GroupsController(groupRepository)..load(),
      ),
    ],
    child: const PromptLibraryApp(),
  );
}

Future<void> fillEditor(
  WidgetTester tester, {
  required String title,
  String description = '',
  required String promptText,
}) async {
  final Finder fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), title);
  if (description.isNotEmpty) {
    await tester.enterText(fields.at(1), description);
  }
  await tester.enterText(fields.at(2), promptText);
  await tester.pump();
}

Future<void> createPrompt(
  WidgetTester tester, {
  required String title,
  String description = '',
  required String promptText,
}) async {
  await tester.tap(find.text('Create'));
  await tester.pumpAndSettle();
  await fillEditor(
    tester,
    title: title,
    description: description,
    promptText: promptText,
  );
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryPromptRepository repository;
  late InMemoryPromptVersionRepository versionRepository;
  late InMemoryPromptGroupRepository groupRepository;

  setUp(() {
    versionRepository = InMemoryPromptVersionRepository();
    groupRepository = InMemoryPromptGroupRepository();
    repository = InMemoryPromptRepository(versionRepository, groupRepository);
  });

  Future<Widget> buildApp() => buildTestApp(repository, versionRepository, groupRepository);

  testWidgets('shows the empty state when no prompts are saved', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    expect(find.text('No prompts yet'), findsOneWidget);
    expect(find.text('Create Prompt'), findsOneWidget);
  });

  testWidgets('creates a prompt and lists it on the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await createPrompt(
      tester,
      title: 'Cinematic Fantasy Character',
      description: 'Character portrait prompt for cinematic artwork.',
      promptText: 'Create a highly detailed cinematic fantasy portrait.',
    );

    expect(find.text('Prompt saved'), findsOneWidget);
    expect(find.text('Cinematic Fantasy Character'), findsOneWidget);
    expect(
      find.text('Character portrait prompt for cinematic artwork.'),
      findsOneWidget,
    );
    expect(repository.store.length, 1);
    expect(versionRepository.versions.length, 1);
  });

  testWidgets('refuses to save without a title and a prompt', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Add a title for this prompt.'), findsOneWidget);
    expect(find.text('Write the prompt before saving.'), findsOneWidget);
    expect(find.text('New Prompt'), findsOneWidget);
    expect(repository.store, isEmpty);
  });

  testWidgets('filters the list as the user types a search', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await createPrompt(
      tester,
      title: 'Cinematic Character',
      promptText: 'A cinematic portrait.',
    );
    await createPrompt(
      tester,
      title: 'Product Mockup',
      promptText: 'A clean studio product shot.',
    );

    await tester.enterText(find.byType(TextField).first, 'studio');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Product Mockup'), findsOneWidget);
    expect(find.text('Cinematic Character'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Product Mockup'), findsOneWidget);
    expect(find.text('Cinematic Character'), findsOneWidget);
  });

  testWidgets('opens details and copies only the prompt text', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await createPrompt(
      tester,
      title: 'Cinematic Character',
      description: 'Portrait prompt.',
      promptText: 'A cinematic portrait with dramatic lighting.',
    );

    await tester.tap(find.text('Cinematic Character'));
    await tester.pumpAndSettle();

    expect(
      find.text('A cinematic portrait with dramatic lighting.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    final MethodCall copyCall = platformCalls.firstWhere(
      (MethodCall call) => call.method == 'Clipboard.setData',
    );
    expect(
      (copyCall.arguments as Map<Object?, Object?>)['text'],
      'A cinematic portrait with dramatic lighting.',
    );
    expect(find.text("Prompt copied"), findsOneWidget);
  });

  testWidgets('copies only the prompt text directly from the prompt card on the home screen', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await createPrompt(
      tester,
      title: 'Images to Dress',
      description: 'Extract Dress from One or Multiple Images references',
      promptText: 'Direct prompt content to be copied only.',
    );

    expect(find.widgetWithText(AppBar, 'Prompts'), findsOneWidget);
    expect(find.text('Images to Dress'), findsOneWidget);
    expect(
      find.text('Extract Dress from One or Multiple Images references'),
      findsOneWidget,
    );

    final Finder copyButton = find.byTooltip('Copy prompt');
    expect(copyButton, findsOneWidget);

    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    final MethodCall copyCall = platformCalls.firstWhere(
      (MethodCall call) => call.method == 'Clipboard.setData',
    );
    expect(
      (copyCall.arguments as Map<Object?, Object?>)['text'],
      'Direct prompt content to be copied only.',
    );
    expect(find.text('Prompt copied'), findsOneWidget);

    // Ensure tapping copy did not open prompt details
    expect(find.widgetWithText(AppBar, 'Prompts'), findsOneWidget);
    expect(find.text('Direct prompt content to be copied only.'), findsNothing);
  });

  testWidgets('edits an existing prompt without creating a duplicate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await createPrompt(
      tester,
      title: 'Cinematic Character',
      promptText: 'A cinematic portrait.',
    );
    final Prompt original = repository.store.values.single;

    await tester.tap(find.text('Cinematic Character'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Prompt'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Moody Portrait');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Prompt updated'), findsOneWidget);
    expect(find.text('Moody Portrait'), findsOneWidget);
    expect(repository.store.length, 1);

    final Prompt updated = repository.store.values.single;
    expect(updated.id, original.id);
    expect(updated.createdAt, original.createdAt);
    expect(versionRepository.versionsFor(updated.id).single.promptText, 'A cinematic portrait.');
    expect(
      updated.updatedAt.isBefore(original.updatedAt),
      isFalse,
    );
  });

  testWidgets('adds a custom input and shows it on the details screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await fillEditor(
      tester,
      title: 'Studio Product Shot',
      promptText: 'A clean studio product shot.',
    );

    await tester.dragUntilVisible(
      find.text('Add Input'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Input'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Model'),
      'Model',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Midjourney'),
      'Midjourney',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Midjourney'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Studio Product Shot'));
    await tester.pumpAndSettle();

    expect(find.text('OTHER INPUTS'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Midjourney'), findsOneWidget);
    expect(
      versionRepository.versions.values.single.customInputs.single.name,
      'Model',
    );
  });

  testWidgets('deletes a prompt after confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await createPrompt(
      tester,
      title: 'Cinematic Character',
      promptText: 'A cinematic portrait.',
    );
    await tester.tap(find.text('Cinematic Character'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Prompt options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete Prompt?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Prompt deleted'), findsOneWidget);
    expect(find.text('No prompts yet'), findsOneWidget);
    expect(repository.store, isEmpty);
    expect(versionRepository.versions, isEmpty);
  });

  testWidgets('keeps saved prompts when the app is started again', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await createPrompt(
      tester,
      title: 'Cinematic Character',
      description: 'Portrait prompt.',
      promptText: 'A cinematic portrait.',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Cinematic Character'), findsOneWidget);
    expect(find.text('Portrait prompt.'), findsOneWidget);
  });

  testWidgets('warns before discarding unsaved editor changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Half finished');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('New Prompt'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Discard'));
    await tester.pumpAndSettle();

    expect(find.text('No prompts yet'), findsOneWidget);
    expect(repository.store, isEmpty);
  });

  testWidgets('leaves an untouched editor without asking', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('No prompts yet'), findsOneWidget);
  });

  testWidgets('renders prompts whose image files are unavailable', (
    WidgetTester tester,
  ) async {
    final DateTime createdAt = DateTime(2026, 9, 1);
    final DateTime updatedAt = DateTime(2026, 9, 2);
    final Prompt prompt = Prompt(
      id: 'stored-prompt',
      title: 'Has images',
      description: 'Its files are gone.',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    repository.store[prompt.id] = prompt;
    versionRepository.versions['stored-prompt-v1'] = PromptVersion(
      id: 'stored-prompt-v1',
      promptId: prompt.id,
      label: 'Version 1',
      orderIndex: 0,
      promptText: 'A prompt whose images went missing.',
      referenceImages: const <String>['missing-one.jpg'],
      outputImages: const <String>['missing-two.jpg'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Has images'), findsOneWidget);
    expect(find.text('2 images'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Has images'));
    await tester.pumpAndSettle();

    expect(find.text('REFERENCE IMAGES'), findsOneWidget);
    expect(find.text('EXAMPLE OUTPUTS'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
