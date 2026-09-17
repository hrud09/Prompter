import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../../../models/custom_input.dart';
import '../../../models/prompt.dart';
import '../../../shared/services/image_picker_service.dart';
import '../../../shared/services/image_storage_service.dart';
import '../../../shared/widgets/adaptive_body.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/section_label.dart';
import '../../prompts/controllers/prompts_controller.dart';
import '../controllers/prompt_editor_controller.dart';
import '../widgets/custom_input_sheet.dart';
import '../widgets/custom_inputs_section.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/prompt_images_section.dart';

class PromptEditorScreen extends StatefulWidget {
  const PromptEditorScreen({super.key, this.prompt});

  final Prompt? prompt;

  @override
  State<PromptEditorScreen> createState() => _PromptEditorScreenState();
}

class _PromptEditorScreenState extends State<PromptEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final PromptEditorController _controller;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _controller = PromptEditorController(
      promptsController: context.read<PromptsController>(),
      imageStorage: context.read<ImageStorageService>(),
      imagePicker: context.read<ImagePickerService>(),
      existing: widget.prompt,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      showAppSnackBar(
        context,
        'Add a title and a prompt before saving.',
        isError: true,
      );
      return;
    }
    try {
      final Prompt? saved = await _controller.save();
      if (!mounted || saved == null) {
        return;
      }
      Navigator.of(context).pop(true);
    } on PromptRepositoryException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.message, isError: true);
      }
    }
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) {
      return;
    }
    if (!_controller.hasUnsavedChanges) {
      Navigator.of(context).pop(false);
      return;
    }
    final bool discard = await showConfirmationDialog(
      context,
      title: 'Discard changes?',
      message: 'Your edits to this prompt will not be saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );
    if (discard && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _addImages(PromptImageTarget target) async {
    final bool isReference = target == PromptImageTarget.reference;
    final PromptImageSource? source = await showImageSourceSheet(
      context,
      title: isReference ? 'Add Reference Image' : 'Add Example Output',
      allowCamera: _controller.supportsCamera,
    );
    if (source == null || !mounted) {
      return;
    }
    try {
      await _controller.addImages(target, source);
    } on ImagePickerFailure catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.message, isError: true);
      }
    } on ImageStorageException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.message, isError: true);
      }
    }
  }

  Future<void> _addCustomInput() async {
    final CustomInput? input = await showCustomInputSheet(context);
    if (input != null) {
      _controller.addCustomInput(input);
    }
  }

  Future<void> _editCustomInput(int index) async {
    final List<CustomInput> inputs = _controller.customInputs;
    if (index >= inputs.length) {
      return;
    }
    final CustomInput? updated = await showCustomInputSheet(
      context,
      initial: inputs[index],
    );
    if (updated != null) {
      _controller.updateCustomInput(index, updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_controller.isEditing ? 'Edit Prompt' : 'New Prompt'),
          actions: <Widget>[
            ListenableBuilder(
              listenable: _controller,
              builder: (BuildContext context, Widget? child) {
                if (_controller.isSaving) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.sunnyAmber,
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: BouncingWrapper(
                    onTap: _handleSave,
                    child: FilledButton(
                      onPressed: _handleSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sunnyAmber,
                        foregroundColor: const Color(0xFF1E1400),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        minimumSize: const Size(0, 38),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: SafeArea(
          child: AdaptiveBody(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: _EditorForm(
                controller: _controller,
                onAddImages: _addImages,
                onAddCustomInput: _addCustomInput,
                onEditCustomInput: _editCustomInput,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorForm extends StatelessWidget {
  const _EditorForm({
    required this.controller,
    required this.onAddImages,
    required this.onAddCustomInput,
    required this.onEditCustomInput,
  });

  final PromptEditorController controller;
  final ValueChanged<PromptImageTarget> onAddImages;
  final VoidCallback onAddCustomInput;
  final ValueChanged<int> onEditCustomInput;

  String? _requiredValidator(String? value, String message) {
    return (value ?? '').trim().isEmpty ? message : null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        48,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: <Widget>[
        const SectionLabel('Basics'),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            boxShadow: AppColors.cardShadow(isDark: isDark),
          ),
          child: TextFormField(
            controller: controller.titleController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: 'Prompt title'),
            validator: (String? value) =>
                _requiredValidator(value, 'Add a title for this prompt.'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            boxShadow: AppColors.cardShadow(isDark: isDark),
          ),
          child: TextFormField(
            controller: controller.descriptionController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Short description (optional)',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionLabel('Prompt'),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            boxShadow: AppColors.cardShadow(isDark: isDark),
          ),
          child: TextFormField(
            controller: controller.promptTextController,
            minLines: 8,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Write the full prompt here...',
            ),
            validator: (String? value) =>
                _requiredValidator(value, 'Write the prompt before saving.'),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, Widget? child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PromptImagesSection(
                  label: 'Reference images',
                  helperText: 'Images you use as input or inspiration.',
                  images: controller.referenceImages,
                  isBusy: controller.isImporting,
                  onAdd: () => onAddImages(PromptImageTarget.reference),
                  onOpen: (int index) => AppRouter.openImageViewer(
                    context,
                    imageFileNames: controller.referenceImages,
                    initialIndex: index,
                  ),
                  onRemove: (int index) =>
                      controller.removeImage(PromptImageTarget.reference, index),
                ),
                const SizedBox(height: AppSpacing.xl),
                PromptImagesSection(
                  label: 'Example outputs',
                  helperText: 'Images produced with this prompt.',
                  images: controller.outputImages,
                  isBusy: controller.isImporting,
                  onAdd: () => onAddImages(PromptImageTarget.output),
                  onOpen: (int index) => AppRouter.openImageViewer(
                    context,
                    imageFileNames: controller.outputImages,
                    initialIndex: index,
                  ),
                  onRemove: (int index) =>
                      controller.removeImage(PromptImageTarget.output, index),
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomInputsSection(
                  inputs: controller.customInputs,
                  onAdd: onAddCustomInput,
                  onEdit: onEditCustomInput,
                  onRemove: controller.removeCustomInput,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
