import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/prompt_group.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';
import '../../../shared/widgets/section_label.dart';
import 'new_group_sheet.dart';

class GroupPickerSection extends StatelessWidget {
  const GroupPickerSection({
    super.key,
    required this.groups,
    required this.selectedGroupIds,
    required this.onToggle,
    required this.onCreate,
  });

  final List<PromptGroup> groups;
  final Set<String> selectedGroupIds;
  final ValueChanged<String> onToggle;
  final ValueChanged<PromptGroup> onCreate;

  Future<void> _createGroup(BuildContext context) async {
    final PromptGroup? created = await showNewGroupSheet(context);
    if (created != null) {
      onCreate(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionLabel('Groups', optional: true),
        Text(
          'Organize this prompt into one or more groups.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final PromptGroup group in groups)
              _GroupChip(
                label: group.name,
                isSelected: selectedGroupIds.contains(group.id),
                onTap: () => onToggle(group.id),
              ),
            _NewGroupChip(onTap: () => _createGroup(context)),
          ],
        ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isSelected) ...<Widget>[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewGroupChip extends StatelessWidget {
  const _NewGroupChip({required this.onTap});

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
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.royalIndigo.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.add_rounded, size: 16, color: AppColors.royalIndigo),
            const SizedBox(width: 4),
            Text(
              'New group',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.royalIndigo,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
