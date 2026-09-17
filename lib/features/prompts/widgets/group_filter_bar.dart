import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/prompt_group.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';

class GroupFilterBar extends StatelessWidget {
  const GroupFilterBar({
    super.key,
    required this.groups,
    required this.selectedGroupId,
    required this.onSelect,
    required this.onCreate,
  });

  final List<PromptGroup> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: <Widget>[
          _FilterChip(
            label: 'All',
            isSelected: selectedGroupId == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final PromptGroup group in groups) ...<Widget>[
            _FilterChip(
              label: group.name,
              isSelected: selectedGroupId == group.id,
              onTap: () => onSelect(group.id),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          _NewGroupFilterChip(onTap: onCreate),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return BouncingWrapper(
      onTap: onTap,
      lowerBound: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.royalIndigo
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NewGroupFilterChip extends StatelessWidget {
  const _NewGroupFilterChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncingWrapper(
      onTap: onTap,
      lowerBound: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.royalIndigo.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: const Icon(Icons.add_rounded, size: 16, color: AppColors.royalIndigo),
      ),
    );
  }
}
