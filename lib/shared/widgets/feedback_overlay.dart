import 'package:flutter/material.dart';

/// Zeigt ein kurzes Richtig/Falsch-Feedback über der Aufgabe
class FeedbackOverlay extends StatelessWidget {
  final bool? isCorrect; // null = kein Feedback
  final String? hint;    // Hinweis bei falscher Antwort

  const FeedbackOverlay({
    super.key,
    this.isCorrect,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    if (isCorrect == null) return const SizedBox.shrink();

    final correct = isCorrect!;
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: correct
              ? const Color(0xFF4CAF50).withAlpha(230)
              : const Color(0xFFE53935).withAlpha(230),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                correct
                    ? 'Super! Das ist richtig! 🎉'
                    : (hint ?? 'Nicht ganz — versuch es nochmal!'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
