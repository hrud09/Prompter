import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../../../data/repositories/prompt_version_repository.dart';
import '../../../models/custom_input.dart';
import '../../../models/prompt.dart';
import '../../../models/prompt_group.dart';
import '../../../models/prompt_version.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/adaptive_body.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/image_thumbnail.dart';
import '../../../shared/widgets/section_label.dart';
import '../../prompt_editor/widgets/version_tab_bar.dart';
import '../controllers/prompts_controller.dart';
import '../widgets/prompt_card.dart';

class PromptDetailsScreen extends StatefulWidget {
  const PromptDetailsScreen({super.key, required this.prompt});

  final Prompt prompt;

  @override
  State<PromptDetailsScreen> createState() => _PromptDetailsScreenState();
}

class _PromptDetailsScreenState extends State<PromptDetailsScreen> {
  late Prompt _prompt;
  List<PromptVersion> _versions = const <PromptVersion>[];
  int _activeVersionIndex = 0;
  bool _isLoadingVersions = true;

  @override
  void initState() {
    super.initState();
    _prompt = widget.prompt;
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    try {
      final List<PromptVersion> versions =
          await context.read<PromptVersionRepository>().fetchForPrompt(_prompt.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _versions = versions;
        _activeVersionIndex = _activeVersionIndex.clamp(0, versions.isEmpty ? 0 : versions.length - 1);
        _isLoadingVersions = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _isLoadingVersions = false);
      }
    }
  }

  PromptVersion? get _activeVersion =>
      _versions.isEmpty ? null : _versions[_activeVersionIndex];

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: _activeVersion?.promptText ?? ''));
    if (mounted) {
      showAppSnackBar(context, 'Prompt copied');
    }
  }

  Future<void> _editPrompt() async {
    final bool saved = await AppRouter.openPromptEditor(context, prompt: _prompt);
    if (!saved || !mounted) {
      return;
    }
    showAppSnackBar(context, 'Prompt updated');
    await _reloadPrompt();
  }

  Future<void> _reloadPrompt() async {
    final PromptsController controller = context.read<PromptsController>();
    try {
      final Prompt? updated = await controller.findById(_prompt.id);
      if (!mounted) {
        return;
      }
      if (updated == null) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _prompt = updated);
      await _loadVersions();
    } on PromptRepositoryException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.message, isError: true);
      }
    }
  }

  Future<void> _deletePrompt() async {
    final PromptsController controller = context.read<PromptsController>();
    final bool confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Prompt?',
      highlight: _prompt.title,
      message: 'This prompt and its images will be deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await controller.delete(_prompt);
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Prompt deleted');
      Navigator.of(context).pop();
    } on PromptRepositoryException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PromptVersion? activeVersion = _activeVersion;

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          PopupMenuButton<PromptCardAction>(
            tooltip: 'Prompt options',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_horiz_rounded, size: 20),
            ),
            onSelected: (PromptCardAction action) {
              switch (action) {
                case PromptCardAction.edit:
                  _editPrompt();
                case PromptCardAction.delete:
                  _deletePrompt();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<PromptCardAction>>[
              const PopupMenuItem<PromptCardAction>(
                value: PromptCardAction.edit,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem<PromptCardAction>(
                value: PromptCardAction.delete,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.coralRed,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(
                      color: AppColors.coralRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: AdaptiveBody(
          child: _isLoadingVersions
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    48,
                  ),
                  children: <Widget>[
                    Text(
                      _prompt.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (_prompt.description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _prompt.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Updated ${DateFormatter.full(_prompt.updatedAt)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (final PromptGroup group in _prompt.groups)
                          BouncingWrapper(
                            onTap: () => Navigator.of(context).pop(group.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.royalIndigo.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                group.name,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.royalIndigo,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_versions.length > 1) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      VersionTabBar(
                        labels: <String>[
                          for (final PromptVersion version in _versions) version.label,
                        ],
                        activeIndex: _activeVersionIndex,
                        onSelect: (int index) => setState(() => _activeVersionIndex = index),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    const SectionLabel('Prompt'),
                    _PromptTextBox(text: activeVersion?.promptText ?? ''),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: BouncingWrapper(
                        onTap: _copyPrompt,
                        child: FilledButton.icon(
                          onPressed: _copyPrompt,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.royalIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy'),
                        ),
                      ),
                    ),
                    if ((activeVersion?.referenceImages.isNotEmpty ?? false)) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      _ImageStrip(
                        label: 'Reference images',
                        images: activeVersion!.referenceImages,
                      ),
                    ],
                    if ((activeVersion?.outputImages.isNotEmpty ?? false)) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      _ImageStrip(
                        label: 'Example outputs',
                        images: activeVersion!.outputImages,
                      ),
                    ],
                    if ((activeVersion?.customInputs.isNotEmpty ?? false)) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      const SectionLabel('Other inputs'),
                      _CustomInputsTable(inputs: activeVersion!.customInputs),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    BouncingWrapper(
                      onTap: _editPrompt,
                      child: FilledButton.icon(
                        onPressed: _editPrompt,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sunnyAmber,
                          foregroundColor: const Color(0xFF1E1400),
                          minimumSize: const Size(double.infinity, 54),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PromptTextBox extends StatelessWidget {
  const _PromptTextBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: AppColors.cardShadow(isDark: isDark),
      ),
      child: SelectableText(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.label, required this.images});

  static const double _tileSize = 120;

  final String label;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionLabel(label),
        SizedBox(
          height: _tileSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: images.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              return ImageThumbnail(
                fileName: images[index],
                size: _tileSize,
                semanticLabel: '$label image ${index + 1}',
                onTap: () => AppRouter.openImageViewer(
                  context,
                  imageFileNames: images,
                  initialIndex: index,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomInputsTable extends StatelessWidget {
  const _CustomInputsTable({required this.inputs});

  final List<CustomInput> inputs;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: AppColors.cardShadow(isDark: isDark),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < inputs.length; index++) ...<Widget>[
            if (index > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Text(
                      inputs[index].name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 3,
                    child: Text(
                      inputs[index].value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
