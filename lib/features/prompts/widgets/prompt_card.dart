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

  static const int _maxThumbnails = 3;
  static const double _thumbnailSize = 42;

  final Prompt prompt;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<String> previews = (prompt.previewVersion?.allImages ?? const <String>[])
        .take(_maxThumbnails)
        .toList(growable: false);
    final int imageCount = prompt.previewVersion?.imageCount ?? 0;

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
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: prompt.description.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Text(
                              prompt.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.4,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  IconButton(
                    tooltip: 'Copy prompt',
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
                ],
              ),
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
                  for (final String fileName in previews)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LocalImageView(
                          fileName: fileName,
                          width: _thumbnailSize,
                          height: _thumbnailSize,
                          decodeWidth: _thumbnailSize,
                        ),
                      ),
                    ),
                  if (imageCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        _imageCountLabel(imageCount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark ? AppColors.electricBlueLight : AppColors.electricBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
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

  static String _imageCountLabel(int count) {
    return count == 1 ? '1 image' : '$count images';
  }
}
