import 'package:flutter/material.dart';

/// Farbwelten pro Klassenstufe + globale App-Farben
class AppColors {
  AppColors._();

  // Globale Markenfarben
  static const primary = Color(0xFFE8703A); // Fuchs-Orange
  static const primaryDark = Color(0xFFC45A28);
  static const onPrimary = Colors.white;

  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFFC107);

  static const background = Color(0xFFFFF8F0);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF2D2D2D);
  static const onSurfaceMuted = Color(0xFF8A8A8A);

  // Klassenstufen-Farbwelten
  static const grade1 = GradeColors(
    primary: Color(0xFF42A5F5), // Hellblau
    secondary: Color(0xFFBBDEFB),
    accent: Color(0xFF1565C0),
    background: Color(0xFFF3F9FF),
  );

  static const grade2 = GradeColors(
    primary: Color(0xFF66BB6A), // Grün
    secondary: Color(0xFFC8E6C9),
    accent: Color(0xFF2E7D32),
    background: Color(0xFFF3FBF3),
  );

  static const grade3 = GradeColors(
    primary: Color(0xFFFFB300), // Gelb/Amber
    secondary: Color(0xFFFFECB3),
    accent: Color(0xFFE65100),
    background: Color(0xFFFFFBF0),
  );

  static const grade4 = GradeColors(
    primary: Color(0xFFAB47BC), // Lila
    secondary: Color(0xFFE1BEE7),
    accent: Color(0xFF6A1B9A),
    background: Color(0xFFFAF3FC),
  );

  static GradeColors forGrade(int grade) {
    return switch (grade) {
      1 => grade1,
      2 => grade2,
      3 => grade3,
      4 => grade4,
      _ => grade1,
    };
  }
}

class GradeColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;

  const GradeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
  });
}
