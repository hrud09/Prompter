import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../../../models/custom_input.dart';
import '../../../models/prompt.dart';
import '../../../shared/services/image_picker_service.dart';
import '../../../shared/services/image_storage_service.dart';
import '../../prompts/controllers/prompts_controller.dart';

enum PromptImageTarget { reference, output }

class PromptEditorController extends ChangeNotifier {
  PromptEditorController({
    required this._promptsController,
    required this._imageStorage,
    required this._imagePicker,
    Prompt? existing,
  })  : _existing = existing,
        titleController = TextEditingController(text: existing?.title ?? ''),
        descriptionController =
            TextEditingController(text: existing?.description ?? ''),
        promptTextController =
            TextEditingController(text: existing?.promptText ?? ''),
        _referenceImages = List<String>.of(existing?.referenceImages ?? const <String>[]),
        _outputImages = List<String>.of(existing?.outputImages ?? const <String>[]),
        _customInputs =
            List<CustomInput>.of(existing?.customInputs ?? const <CustomInput>[]);

  final PromptsController _promptsController;
  final ImageStorageService _imageStorage;
  final ImagePickerService _imagePicker;
  final Prompt? _existing;

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController promptTextController;

  final List<String> _referenceImages;
  final List<String> _outputImages;
  final List<CustomInput> _customInputs;
  final Set<String> _importedFiles = <String>{};
  final Set<String> _discardedFiles = <String>{};

  bool _isDisposed = false;
  bool _isSaving = false;
  bool _isImporting = false;
  bool _isSaved = false;

  bool get isEditing => _existing != null;

  bool get isSaving => _isSaving;

  bool get isImporting => _isImporting;

  bool get supportsCamera => _imagePicker.supportsCamera;

  List<String> get referenceImages => List<String>.unmodifiable(_referenceImages);

  List<String> get outputImages => List<String>.unmodifiable(_outputImages);

  List<CustomInput> get customInputs => List<CustomInput>.unmodifiable(_customInputs);

  bool get hasUnsavedChanges {
    final Prompt? existing = _existing;
    if (existing == null) {
      return titleController.text.trim().isNotEmpty ||
          descriptionController.text.trim().isNotEmpty ||
          promptTextController.text.trim().isNotEmpty ||
          _referenceImages.isNotEmpty ||
          _outputImages.isNotEmpty ||
          _customInputs.isNotEmpty;
    }
    return titleController.text != existing.title ||
        descriptionController.text != existing.description ||
        promptTextController.text != existing.promptText ||
        !listEquals(_referenceImages, existing.referenceImages) ||
        !listEquals(_outputImages, existing.outputImages) ||
        !listEquals(_customInputs, existing.customInputs);
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
      _importedFiles.addAll(imported);
      _listFor(target).addAll(imported);
    } finally {
      _isImporting = false;
      _notify();
    }
  }

  Future<void> removeImage(PromptImageTarget target, int index) async {
    final List<String> images = _listFor(target);
    if (index < 0 || index >= images.length) {
      return;
    }
    final String fileName = images.removeAt(index);
    _notify();
    if (_importedFiles.remove(fileName)) {
      await _imageStorage.deleteImage(fileName);
    } else {
      _discardedFiles.add(fileName);
    }
  }

  void addCustomInput(CustomInput input) {
    _customInputs.add(input);
    _notify();
  }

  void updateCustomInput(int index, CustomInput input) {
    if (index < 0 || index >= _customInputs.length) {
      return;
    }
    _customInputs[index] = input;
    _notify();
  }

  void removeCustomInput(int index) {
    if (index < 0 || index >= _customInputs.length) {
      return;
    }
    _customInputs.removeAt(index);
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
      final Prompt prompt = existing == null
          ? Prompt(
              id: const Uuid().v4(),
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              promptText: promptTextController.text.trim(),
              referenceImages: List<String>.of(_referenceImages),
              outputImages: List<String>.of(_outputImages),
              customInputs: List<CustomInput>.of(_customInputs),
              createdAt: now,
              updatedAt: now,
            )
          : existing.copyWith(
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              promptText: promptTextController.text.trim(),
              referenceImages: List<String>.of(_referenceImages),
              outputImages: List<String>.of(_outputImages),
              customInputs: List<CustomInput>.of(_customInputs),
              updatedAt: now,
            );
      await _promptsController.save(prompt);
      _isSaved = true;
      final List<String> removable = _discardedFiles.toList(growable: false);
      _discardedFiles.clear();
      _importedFiles.clear();
      await _imageStorage.deleteImages(removable);
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

  List<String> _listFor(PromptImageTarget target) {
    return target == PromptImageTarget.reference ? _referenceImages : _outputImages;
  }

  @override
  void dispose() {
    _isDisposed = true;
    titleController.dispose();
    descriptionController.dispose();
    promptTextController.dispose();
    if (!_isSaved && _importedFiles.isNotEmpty) {
      unawaited(_imageStorage.deleteImages(_importedFiles.toList(growable: false)));
    }
    super.dispose();
  }
}
