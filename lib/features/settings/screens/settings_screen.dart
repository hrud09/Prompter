import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_info.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/adaptive_body.dart';
import '../../../shared/widgets/section_label.dart';
import '../controllers/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: isDark ? null : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: AdaptiveBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              const SectionLabel('Appearance'),
              Consumer<ThemeController>(
                builder: (
                  BuildContext context,
                  ThemeController controller,
                  Widget? child,
                ) {
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        side: WidgetStateProperty.all<BorderSide>(BorderSide.none),
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return theme.colorScheme.surfaceContainerLowest;
                            }
                            return Colors.transparent;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return isDark ? Colors.white : AppColors.electricBlue;
                            }
                            return theme.colorScheme.onSurfaceVariant;
                          },
                        ),
                        elevation: WidgetStateProperty.resolveWith<double?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return 2.0;
                            }
                            return 0.0;
                          },
                        ),
                        textStyle: WidgetStateProperty.resolveWith<TextStyle?>(
                          (Set<WidgetState> states) {
                            return TextStyle(
                              fontWeight: states.contains(WidgetState.selected)
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 13.5,
                            );
                          },
                        ),
                      ),
                      segments: const <ButtonSegment<ThemeMode>>[
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: <ThemeMode>{controller.themeMode},
                      onSelectionChanged: (Set<ThemeMode> selection) {
                        controller.setThemeMode(selection.first);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionLabel('About'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: AppColors.cardShadow(isDark: isDark),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.electricBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            AppInfo.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'AI Prompt Library',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sunnyAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'v${AppInfo.version}',
                        style: const TextStyle(
                          color: Color(0xFF996B00),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
