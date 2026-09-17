import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onCreate,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color barColor =
        isDark ? const Color(0xFF0F172A) : AppColors.electricBlue;

    return Container(
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: barColor.withValues(alpha: isDark ? 0.4 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _NavItem(
                  icon: Icons.article_outlined,
                  selectedIcon: Icons.article_rounded,
                  label: 'Prompts',
                  isSelected: currentIndex == 0,
                  onTap: () => onSelect(0),
                ),
              ),
              Expanded(
                child: _CreateItem(onTap: onCreate),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.tune_rounded,
                  selectedIcon: Icons.tune_rounded,
                  label: 'Settings',
                  isSelected: currentIndex == 1,
                  onTap: () => onSelect(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color activeColor = AppColors.sunnyAmber;
    final Color inactiveColor = Colors.white.withValues(alpha: 0.65);
    final Color color = isSelected ? activeColor : inactiveColor;

    return BouncingWrapper(
      onTap: onTap,
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11.5,
                  letterSpacing: 0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateItem extends StatelessWidget {
  const _CreateItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return BouncingWrapper(
      onTap: onTap,
      lowerBound: 0.92,
      child: Semantics(
        button: true,
        label: 'Create prompt',
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 60,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sunnyAmber,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: Color(0xFF1E1400),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Create',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.sunnyAmber,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
