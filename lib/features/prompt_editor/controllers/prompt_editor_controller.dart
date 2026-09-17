import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/prompt_group_repository.dart';
import '../../../data/repositories/prompt_version_repository.dart';
import '../../../models/custom_input.dart';
import '../../../models/prompt.dart';
import '../../../models/prompt_group.dart';
import '../../../models/prompt_version.dart';
import '../../../shared/services/image_picker_service.dart';
import '../../../shared/services/image_storage_service.dart';
import '../../prompts/controllers/prompts_controller.dart';

enum PromptImageTarget { reference, output }

/// One version's in-progress edit state: its own prompt text, image lists
/// and custom inputs, tracked independently so each version can be edited
/// without disturbing the others.
class PromptVersionDraft {
  PromptVersionDraft({
    required this.id,
    required String label,
    required String promptText,
    List<String>? referenceImages,
    List<String>? outputImages,
    List<CustomInput>? customInputs,
  })  : labelController = TextEditingController(text: label),
        promptTextController = TextEditingController(text: promptText),
        referenceImages = List<String>.of(referenceImages ?? const <String>[]),
        outputImages = List<String>.of(outputImages ?? const <String>[]),
        customInputs = List<CustomInput>.of(customInputs ?? const <CustomInput>[]);

  final String id;
  final TextEditingController labelController;
  final TextEditingController promptTextController;
  final List<String> referenceImages;
  final List<String> outputImages;
  final List<CustomInput> customInputs;
  final Set<String> importedFiles = <String>{};
  final Set<String> discardedFiles = <String>{};

  String get label => labelController.text.trim();

  List<String> _listFor(PromptImageTarget target) {
    return target == PromptImageTarget.reference ? referenceImages : outputImages;
  }

  void dispose() {
    labelController.dispose();
    promptTextController.dispose();
  }
}

class PromptEditorController extends ChangeNotifier {
  PromptEditorController({
    required this._promptsController,
    required this._versionRepository,
    required this._groupRepository,
    required this._imageStorage,
    required this._imagePicker,
    Prompt? existing,
  })  : _existing = existing,
        titleController = TextEditingController(text: existing?.title ?? ''),
        descriptionController =
            TextEditingController(text: existing?.description ?? '') {
    if (existing == null) {
      _versions.add(_newDraft(label: 'Version 1'));
      _isLoading = false;
    } else {
      unawaited(_loadExisting(existing));
    }
  }

  final PromptsController _promptsController;
  final PromptVersionRepository _versionRepository;
  final PromptGroupRepository _groupRepository;
  final ImageStorageService _imageStorage;
  final ImagePickerService _imagePicker;
  final Prompt? _existing;

  final TextEditingController titleController;
  final TextEditingController descriptionController;

  final List<PromptVersionDraft> _versions = <PromptVersionDraft>[];
  final List<String> _removedVersionIds = <String>[];
  final Set<String> _selectedGroupIds = <String>{};

  List<PromptVersion> _originalVersions = const <PromptVersion>[];
  Set<String> _originalGroupIds = const <String>{};

  int _activeVersionIndex = 0;
  bool _isDisposed = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isImporting = false;
  bool _isSaved = false;
  String? _loadError;

  bool get isEditing => _existing != null;

  bool get isLoading => _isLoading;

  String? get loadError => _loadError;

  bool get isSaving => _isSaving;

  bool get isImporting => _isImporting;

  bool get supportsCamera => _imagePicker.supportsCamera;

  List<PromptVersionDraft> get versions => List<PromptVersionDraft>.unmodifiable(_versions);

  int get activeVersionIndex => _activeVersionIndex;

  PromptVersionDraft get activeVersion => _versions[_activeVersionIndex];

  Set<String> get selectedGroupIds => Set<String>.unmodifiable(_selectedGroupIds);

  List<String> get referenceImages => List<String>.unmodifiable(activeVersion.referenceImages);

  List<String> get outputImages => List<String>.unmodifiable(activeVersion.outputImages);

  List<CustomInput> get customInputs => List<CustomInput>.unmodifiable(activeVersion.customInputs);

  bool get hasUnsavedChanges {
    if (_isLoading) {
      return false;
    }
    final Prompt? existing = _existing;
    if (existing == null) {
      final PromptVersionDraft draft = _versions.single;
      return titleController.text.trim().isNotEmpty ||
          descriptionController.text.trim().isNotEmpty ||
          draft.promptTextController.text.trim().isNotEmpty ||
          draft.referenceImages.isNotEmpty ||
          draft.outputImages.isNotEmpty ||
          draft.customInputs.isNotEmpty ||
          _selectedGroupIds.isNotEmpty;
    }
    if (titleController.text != existing.title ||
        descriptionController.text != existing.description ||
        !setEquals(_selectedGroupIds, _originalGroupIds) ||
        _versions.length != _originalVersions.length) {
      return true;
    }
    for (int index = 0; index < _versions.length; index++) {
      final PromptVersionDraft draft = _versions[index];
      final PromptVersion original = _originalVersions[index];
      if (draft.id != original.id ||
          draft.label != original.label ||
          draft.promptTextController.text != original.promptText ||
          !listEquals(draft.referenceImages, original.referenceImages) ||
          !listEquals(draft.outputImages, original.outputImages) ||
          !listEquals(draft.customInputs, original.customInputs)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadExisting(Prompt existing) async {
    try {
      final List<PromptVersion> versions = await _versionRepository.fetchForPrompt(existing.id);
      final List<PromptGroup> groups = await _groupRepository.fetchGroupsForPrompt(existing.id);
      _originalVersions = versions;
      _originalGroupIds = groups.map((PromptGroup group) => group.id).toSet();
      _versions.addAll(versions.map(_draftFromVersion));
      if (_versions.isEmpty) {
        _versions.add(_newDraft(label: 'Version 1'));
      }
      _selectedGroupIds.addAll(_originalGroupIds);
    } on Object {
      _loadError = 'Could not load this prompt.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  PromptVersionDraft _draftFromVersion(PromptVersion version) {
    return PromptVersionDraft(
      id: version.id,
      label: version.label,
      promptText: version.promptText,
      referenceImages: version.referenceImages,
      outputImages: version.outputImages,
      customInputs: version.customInputs,
    );
  }

  PromptVersionDraft _newDraft({required String label, PromptVersionDraft? duplicateFrom}) {
    return PromptVersionDraft(
      id: const Uuid().v4(),
      label: label,
      promptText: duplicateFrom?.promptTextController.text ?? '',
      referenceImages: duplicateFrom?.referenceImages,
      outputImages: duplicateFrom?.outputImages,
      customInputs: duplicateFrom?.customInputs,
    );
  }

  void addVersion({bool duplicateActive = false}) {
    final PromptVersionDraft draft = _newDraft(
      label: 'Version ${_versions.length + 1}',
      duplicateFrom: duplicateActive ? activeVersion : null,
    );
    _versions.add(draft);
    _activeVersionIndex = _versions.length - 1;
    _notify();
  }

  void selectVersion(int index) {
    if (index < 0 || index >= _versions.length || index == _activeVersionIndex) {
      return;
    }
    _activeVersionIndex = index;
    _notify();
  }

  void renameVersion(int index, String label) {
    if (index < 0 || index >= _versions.length) {
      return;
    }
    _versions[index].labelController.text = label;
    _notify();
  }

  void removeVersion(int index) {
    if (_versions.length <= 1 || index < 0 || index >= _versions.length) {
      return;
    }
    final PromptVersionDraft removed = _versions.removeAt(index);
    final bool wasPersisted = _originalVersions.any((PromptVersion v) => v.id == removed.id);
    if (wasPersisted) {
      _removedVersionIds.add(removed.id);
    } else if (removed.importedFiles.isNotEmpty) {
      unawaited(_imageStorage.deleteImages(removed.importedFiles.toList(growable: false)));
    }
    removed.dispose();
    if (_activeVersionIndex >= _versions.length) {
      _activeVersionIndex = _versions.length - 1;
    }
    _notify();
  }

  void toggleGroup(String groupId) {
    if (!_selectedGroupIds.remove(groupId)) {
      _selectedGroupIds.add(groupId);
    }
    _notify();
  }

  Future<void> addImages(PromptImageTarget target, PromptImageSource source) async {
    if (_isImporting) {
      return;
    }
    final List<String> picked = await _imagePicker.pickImages(source);
    if (picked.isEmpty) {
      return;
    }
    _isImporting = true;
    _notify();
    try {
      final List<String> imported = await _imageStorage.importImages(picked);
      final PromptVersionDraft draft = activeVersion;
      draft.importedFiles.addAll(imported);
      draft._listFor(target).addAll(imported);
    } finally {
      _isImporting = false;
      _notify();
    }
  }

  Future<void> removeImage(PromptImageTarget target, int index) async {
    final PromptVersionDraft draft = activeVersion;
    final List<String> images = draft._listFor(target);
    if (index < 0 || index >= images.length) {
      return;
    }
    final String fileName = images.removeAt(index);
    _notify();
    if (draft.importedFiles.remove(fileName)) {
      await _imageStorage.deleteImage(fileName);
    } else {
      draft.discardedFiles.add(fileName);
    }
  }

  void addCustomInput(CustomInput input) {
    activeVersion.customInputs.add(input);
    _notify();
  }

  void updateCustomInput(int index, CustomInput input) {
    final List<CustomInput> inputs = activeVersion.customInputs;
    if (index < 0 || index >= inputs.length) {
      return;
    }
    inputs[index] = input;
    _notify();
  }

  void removeCustomInput(int index) {
    final List<CustomInput> inputs = activeVersion.customInputs;
    if (index < 0 || index >= inputs.length) {
      return;
    }
    inputs.removeAt(index);
    _notify();
  }

  Future<Prompt?> save() async {
    if (_isSaving) {
      return null;
    }
    _isSaving = true;
    _notify();
    try {
      final DateTime now = DateTime.now();
      final Prompt? existing = _existing;
      final String promptId = existing?.id ?? const Uuid().v4();
      final Prompt prompt = existing == null
          ? Prompt(
              id: promptId,
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              createdAt: now,
              updatedAt: now,
            )
          : existing.copyWith(
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              updatedAt: now,
            );
      final List<PromptVersion> versionsToSave = <PromptVersion>[];
      for (int index = 0; index < _versions.length; index++) {
        final PromptVersionDraft draft = _versions[index];
        final PromptVersion? original =
            _originalVersions.where((PromptVersion v) => v.id == draft.id).firstOrNull;
        versionsToSave.add(PromptVersion(
          id: draft.id,
          promptId: promptId,
          label: draft.label.isEmpty ? 'Version ${index + 1}' : draft.label,
          orderIndex: index,
          promptText: draft.promptTextController.text.trim(),
          referenceImages: List<String>.of(draft.referenceImages),
          outputImages: List<String>.of(draft.outputImages),
          customInputs: List<CustomInput>.of(draft.customInputs),
          createdAt: original?.createdAt ?? now,
          updatedAt: now,
        ));
      }
      // Versions and group membership are persisted before the prompt row so
      // that, by the time PromptsController.save() reloads the list, the
      // preview/version-count/group joins it reads already reflect them.
      await _versionRepository.saveAll(versionsToSave);
      await _versionRepository.deleteByIds(_removedVersionIds);
      await _groupRepository.setGroupsForPrompt(promptId, _selectedGroupIds);
      await _promptsController.save(prompt);

      _isSaved = true;
      for (final PromptVersionDraft draft in _versions) {
        final List<String> removable = draft.discardedFiles.toList(growable: false);
        draft.discardedFiles.clear();
        draft.importedFiles.clear();
        await _imageStorage.deleteImages(removable);
      }
      return prompt;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  void _notify() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    titleController.dispose();
    descriptionController.dispose();
    if (!_isSaved) {
      for (final PromptVersionDraft draft in _versions) {
        if (draft.importedFiles.isNotEmpty) {
          unawaited(_imageStorage.deleteImages(draft.importedFiles.toList(growable: false)));
        }
      }
    }
    for (final PromptVersionDraft draft in _versions) {
      draft.dispose();
    }
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
