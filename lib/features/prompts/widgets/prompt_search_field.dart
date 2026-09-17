import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

class PromptSearchField extends StatelessWidget {
  const PromptSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppColors.cardShadow(isDark: isDark),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (BuildContext context, TextEditingValue value, Widget? child) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search prompts...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: AppColors.electricBlue,
                ),
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        onPressed: onClear,
                        icon: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        tooltip: 'Clear search',
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
