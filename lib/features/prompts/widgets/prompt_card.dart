import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/prompt.dart';
import '../../../models/prompt_group.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';
import '../../../shared/widgets/local_image_view.dart';

enum PromptCardAction { edit, delete }

class PromptCard extends StatelessWidget {
  const PromptCard({
    super.key,
    required this.prompt,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    this.onCopy,
  });

  static const double _previewBoxSize = 88;

  final Prompt prompt;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<String> referenceImages =
        prompt.previewVersion?.referenceImages ?? const <String>[];
    final List<String> outputImages = prompt.previewVersion?.outputImages ?? const <String>[];

    return BouncingWrapper(
      onTap: onOpen,
      onLongPress: onEdit,
      lowerBound: 0.97,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: AppColors.cardShadow(isDark: isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 16, AppSpacing.sm, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        prompt.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy prompt',
                    visualDensity: VisualDensity.compact,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.copy_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    onPressed: () => _handleCopy(context),
                  ),
                  PopupMenuButton<PromptCardAction>(
                    tooltip: 'Prompt options',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    onSelected: (PromptCardAction action) {
                      switch (action) {
                        case PromptCardAction.edit:
                          onEdit();
                        case PromptCardAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<PromptCardAction>>[
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
                ],
              ),
              if (referenceImages.isNotEmpty || outputImages.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _ImagePreviewGroup(
                        label: 'Reference',
                        images: referenceImages,
                        size: _previewBoxSize,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ImagePreviewGroup(
                        label: 'Output',
                        images: outputImages,
                        size: _previewBoxSize,
                      ),
                    ),
                  ],
                ),
              ],
              if (prompt.groups.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final PromptGroup group in prompt.groups.take(2))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.royalIndigo.withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          group.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? AppColors.royalIndigoLight : AppColors.royalIndigo,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  if (prompt.versionCount > 1)
                    Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.royalIndigo.withValues(alpha: isDark ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${prompt.versionCount} versions',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark ? AppColors.royalIndigoLight : AppColors.royalIndigo,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      DateFormatter.compact(prompt.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCopy(BuildContext context) async {
    if (onCopy != null) {
      onCopy!();
      return;
    }
    await HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: prompt.previewVersion?.promptText ?? ''));
    if (context.mounted) {
      showAppSnackBar(context, 'Prompt copied');
    }
  }

}

class _ImagePreviewGroup extends StatelessWidget {
  const _ImagePreviewGroup({
    required this.label,
    required this.images,
    required this.size,
  });

  final String label;
  final List<String> images;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    if (images.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: <Widget>[
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: LocalImageView(
                fileName: images.first,
                width: size,
                height: size,
                decodeWidth: size,
              ),
            ),
            if (images.length > 1)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '+${images.length - 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
