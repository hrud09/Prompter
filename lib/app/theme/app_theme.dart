import 'package:flutter/material.dart';

class AppRadius {
  const AppRadius._();

  static const double card = 24;
  static const double field = 18;
  static const double thumbnail = 18;
  static const double sheet = 32;
  static const double pill = 100;
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppColors {
  const AppColors._();

  static const Color electricBlue = Color(0xFF0D76FE);
  static const Color electricBlueLight = Color(0xFF388BFF);
  static const Color electricBlueDark = Color(0xFF075BC7);

  static const Color sunnyAmber = Color(0xFFFFB800);
  static const Color sunnyAmberLight = Color(0xFFFFCA3A);
  static const Color sunnyAmberDark = Color(0xFFE6A600);

  static const Color royalIndigo = Color(0xFF534BE8);
  static const Color royalIndigoLight = Color(0xFF7069F7);

  static const Color coralRed = Color(0xFFEE4343);
  static const Color coralRedLight = Color(0xFFFF6B6B);

  static const Color cloudBackground = Color(0xFFF3F6FC);
  static const Color cloudSurface = Colors.white;
  static const Color darkScaffold = Color(0xFF0A0F1D);
  static const Color darkCard = Color(0xFF131A2B);

  static List<BoxShadow> cardShadow({bool isDark = false}) => <BoxShadow>[
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFF0D76FE).withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> pillShadow({Color? color}) => <BoxShadow>[
        BoxShadow(
          color: (color ?? sunnyAmber).withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: AppColors.electricBlue,
      brightness: brightness,
    );
    final ColorScheme scheme = base.copyWith(
      primary: isLight ? AppColors.electricBlue : AppColors.electricBlueLight,
      onPrimary: Colors.white,
      primaryContainer: isLight
          ? const Color(0xFFE5EFFF)
          : const Color(0xFF162544),
      onPrimaryContainer: isLight
          ? AppColors.electricBlueDark
          : const Color(0xFF99C4FF),
      secondary: AppColors.sunnyAmber,
      onSecondary: const Color(0xFF2C1E00),
      secondaryContainer: isLight
          ? const Color(0xFFFFF6D6)
          : const Color(0xFF3D2D00),
      onSecondaryContainer: isLight
          ? const Color(0xFF6B4800)
          : const Color(0xFFFFDE80),
      tertiary: AppColors.royalIndigo,
      onTertiary: Colors.white,
      tertiaryContainer: isLight
          ? const Color(0xFFEEEDFE)
          : const Color(0xFF221F5A),
      onTertiaryContainer: isLight
          ? AppColors.royalIndigo
          : const Color(0xFFC7C5FD),
      error: AppColors.coralRed,
      onError: Colors.white,
      surface: isLight ? AppColors.cloudBackground : AppColors.darkScaffold,
      surfaceContainerLowest: isLight ? Colors.white : AppColors.darkCard,
      surfaceContainerLow: isLight
          ? const Color(0xFFFAFBFE)
          : const Color(0xFF172033),
      surfaceContainer: isLight
          ? Colors.white
          : const Color(0xFF1B263C),
      surfaceContainerHigh: isLight
          ? const Color(0xFFEBF1FB)
          : const Color(0xFF222F4B),
      outlineVariant: isLight
          ? const Color(0xFFE0E7F5)
          : const Color(0xFF2A3959),
    );
    final TextTheme textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 16,
        ),
        border: _fieldBorder(scheme.outlineVariant),
        enabledBorder: _fieldBorder(scheme.outlineVariant),
        focusedBorder: _fieldBorder(scheme.primary, width: 2.0),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 2.0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? const Color(0xFF1E293B) : const Color(0xFF26334D),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        iconColor: scheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final TextTheme base = Typography.material2021(colorScheme: scheme)
        .black
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.48,
        letterSpacing: -0.1,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.48,
        letterSpacing: -0.1,
      ),
      bodySmall: base.bodySmall?.copyWith(
        height: 1.42,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
