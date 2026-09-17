import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/custom_input.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';
import '../../../shared/widgets/section_label.dart';

class CustomInputsSection extends StatelessWidget {
  const CustomInputsSection({
    super.key,
    required this.inputs,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<CustomInput> inputs;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionLabel('Other inputs', optional: true),
        Text(
          'Extra details such as model, style or aspect ratio.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        for (int index = 0; index < inputs.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _CustomInputTile(
              input: inputs[index],
              onEdit: () => onEdit(index),
              onRemove: () => onRemove(index),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        BouncingWrapper(
          onTap: onAdd,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.electricBlue,
              side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add Input',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomInputTile extends StatelessWidget {
  const _CustomInputTile({
    required this.input,
    required this.onEdit,
    required this.onRemove,
  });

  final CustomInput input;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return BouncingWrapper(
      onTap: onEdit,
      lowerBound: 0.98,
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: AppColors.cardShadow(isDark: isDark),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.sm, 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      input.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (input.value.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        input.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onRemove,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.coralRed,
                  ),
                ),
                tooltip: 'Remove input',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
