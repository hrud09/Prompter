import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';
import '../../../shared/widgets/image_thumbnail.dart';
import '../../../shared/widgets/section_label.dart';

class PromptImagesSection extends StatelessWidget {
  const PromptImagesSection({
    super.key,
    required this.label,
    required this.helperText,
    required this.images,
    required this.isBusy,
    required this.onAdd,
    required this.onOpen,
    required this.onRemove,
  });

  static const double _tileSize = 96;

  final String label;
  final String helperText;
  final List<String> images;
  final bool isBusy;
  final VoidCallback onAdd;
  final ValueChanged<int> onOpen;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionLabel(label, optional: true),
        Text(
          helperText,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            for (int index = 0; index < images.length; index++)
              ImageThumbnail(
                fileName: images[index],
                size: _tileSize,
                semanticLabel: '$label image ${index + 1}',
                onTap: () => onOpen(index),
                onRemove: () => onRemove(index),
              ),
            _AddImageTile(size: _tileSize, isBusy: isBusy, onTap: onAdd),
          ],
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({
    required this.size,
    required this.isBusy,
    required this.onTap,
  });

  final double size;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return BouncingWrapper(
      onTap: isBusy ? null : onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh
              : AppColors.electricBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.thumbnail),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.thumbnail),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.outlineVariant
                    : AppColors.electricBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Semantics(
              label: 'Add image',
              button: true,
              child: Center(
                child: isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.electricBlue,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: AppColors.electricBlue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? theme.colorScheme.onSurface
                                  : AppColors.electricBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
