import 'package:flutter/material.dart';
import '../shared/constants/app_colors.dart';
import '../shared/constants/app_text_styles.dart';

/// App-Themes für LernFuchs.
///
/// ### Verfügbare Themes
/// - [AppTheme.light]: Standard-Theme (warme Fuchs-Orange Akzente, Nunito-Schrift).
/// - [AppTheme.highContrast]: Barrierefreiheits-Theme mit verstärkten Kontrasten
///   (schwarzer Hintergrund, weiße Schrift, kräftige Akzentfarben).
/// - [AppTheme.forGrade]: Überschreibt die Primärfarbe für eine Klassenstufe.
///
/// ### Schriftgröße
/// Wird nicht im Theme gesteuert, sondern via [TextScaler] im [MediaQuery]
/// in `main.dart` — so skalieren alle Texte konsistent und unabhängig vom Theme.
class AppTheme {
  AppTheme._();

  /// Standard-Theme: helles Layout mit warmer Fuchs-Orange-Palette.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Nunito',
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          headlineLarge: AppTextStyles.headlineLarge,
          headlineMedium: AppTextStyles.headlineMedium,
          titleLarge: AppTextStyles.titleLarge,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          labelLarge: AppTextStyles.labelLarge,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.onSurface,
        ),
      );

  /// Hochkontrast-Theme für Barrierefreiheit.
  ///
  /// Verwendet einen dunklen Hintergrund mit weißem Text und kräftigen
  /// Akzentfarben, um die Lesbarkeit für sehbeeinträchtigte Nutzer zu verbessern.
  static ThemeData get highContrast => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFFFB74D),
          onPrimary: Colors.black,
          secondary: Color(0xFF81D4FA),
          onSecondary: Colors.black,
          error: Color(0xFFEF9A9A),
          onError: Colors.black,
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Nunito',
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          headlineLarge: AppTextStyles.headlineLarge,
          headlineMedium: AppTextStyles.headlineMedium,
          titleLarge: AppTextStyles.titleLarge,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          labelLarge: AppTextStyles.labelLarge,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 56),
            backgroundColor: const Color(0xFFFFB74D),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF444444)),
          ),
          color: const Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
      );

  /// Theme für eine bestimmte Klassenstufe (überschreibt Primärfarbe).
  ///
  /// Wird in [ExerciseScreen] und [SubjectOverviewScreen] verwendet um
  /// die Farbe an die Klassenstufe anzupassen.
  static ThemeData forGrade(int grade) {
    final gradeColors = AppColors.forGrade(grade);
    return light.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: gradeColors.primary,
        brightness: Brightness.light,
        primary: gradeColors.primary,
        onPrimary: Colors.white,
        secondary: gradeColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
      scaffoldBackgroundColor: gradeColors.background,
    );
  }
}
