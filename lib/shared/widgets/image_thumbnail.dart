import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'bouncing_wrapper.dart';
import 'local_image_view.dart';

class ImageThumbnail extends StatelessWidget {
  const ImageThumbnail({
    super.key,
    required this.fileName,
    required this.size,
    required this.semanticLabel,
    this.onTap,
    this.onRemove,
  });

  final String fileName;
  final double size;
  final String semanticLabel;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: BouncingWrapper(
              onTap: onTap,
              lowerBound: 0.94,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.thumbnail),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: AppColors.cardShadow(isDark: isDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: scheme.surfaceContainerHigh,
                  child: InkWell(
                    onTap: onTap,
                    child: Semantics(
                      label: semanticLabel,
                      button: onTap != null,
                      child: LocalImageView(
                        fileName: fileName,
                        decodeWidth: size,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: -4,
              right: -4,
              child: _RemoveButton(onPressed: onRemove!),
            ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Remove image',
      button: true,
      child: Tooltip(
        message: 'Remove image',
        child: BouncingWrapper(
          onTap: onPressed,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.coralRed,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.coralRed.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
