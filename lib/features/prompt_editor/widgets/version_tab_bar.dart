import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';

enum VersionTabMenuAction { rename, duplicate, delete }

/// Horizontal chip row for switching between a prompt's versions.
///
/// In edit mode ([onAdd] provided) it also offers adding, renaming,
/// duplicating and deleting versions via long-press. When [onAdd] is null
/// it renders as a read-only selector (used on the details screen).
class VersionTabBar extends StatelessWidget {
  const VersionTabBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onSelect,
    this.onAdd,
    this.onMenuAction,
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;
  final void Function(int index, VersionTabMenuAction action)? onMenuAction;

  bool get _isEditable => onAdd != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (int index = 0; index < labels.length; index++) ...<Widget>[
            _VersionChip(
              label: labels[index],
              isActive: index == activeIndex,
              onTap: () => onSelect(index),
              onLongPress: _isEditable && onMenuAction != null
                  ? () => _showMenu(context, index)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (_isEditable)
            _AddVersionChip(onTap: onAdd!),
        ],
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, int index) async {
    final VersionTabMenuAction? action = await showModalBottomSheet<VersionTabMenuAction>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline_rounded),
                title: const Text('Rename version'),
                onTap: () => Navigator.of(sheetContext).pop(VersionTabMenuAction.rename),
              ),
              ListTile(
                leading: const Icon(Icons.copy_all_rounded),
                title: const Text('Duplicate as new version'),
                onTap: () => Navigator.of(sheetContext).pop(VersionTabMenuAction.duplicate),
              ),
              if (labels.length > 1)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.coralRed),
                  title: const Text(
                    'Delete version',
                    style: TextStyle(color: AppColors.coralRed, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(VersionTabMenuAction.delete),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (action != null) {
      onMenuAction?.call(index, action);
    }
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return BouncingWrapper(
      onTap: onTap,
      onLongPress: onLongPress,
      lowerBound: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.electricBlue
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AddVersionChip extends StatelessWidget {
  const _AddVersionChip({required this.onTap});

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
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.electricBlue.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.add_rounded, size: 16, color: AppColors.electricBlue),
            const SizedBox(width: 4),
            Text(
              'Version',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.electricBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
