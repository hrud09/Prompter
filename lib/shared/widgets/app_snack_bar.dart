import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final ThemeData theme = Theme.of(context);
  final bool isDark = theme.brightness == Brightness.dark;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        backgroundColor: isError
            ? AppColors.coralRed
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        content: Row(
          children: <Widget>[
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? Colors.white : AppColors.sunnyAmber,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(milliseconds: isError ? 3500 : 2000),
      ),
    );
}
