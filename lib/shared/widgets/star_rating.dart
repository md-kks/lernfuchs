import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int stars; // 0–3
  final int maxStars;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const StarRating({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.size = 32,
    this.activeColor = const Color(0xFFFFB300),
    this.inactiveColor = const Color(0xFFE0E0E0),
  });

  /// Berechnet Sterne basierend auf Trefferquote (0.0–1.0)
  static int fromAccuracy(double accuracy) {
    if (accuracy >= 0.9) return 3;
    if (accuracy >= 0.6) return 2;
    if (accuracy >= 0.3) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        final active = i < stars;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            active ? Icons.star_rounded : Icons.star_outline_rounded,
            key: ValueKey(active),
            size: size,
            color: active ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}
