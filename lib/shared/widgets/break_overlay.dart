import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/health_service.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';

/// Overlay für die 20/20-Augenpause.
///
/// Wird narrativ eingebettet ("Fino braucht eine Pause") und fordert
/// das Kind auf, 20 Sekunden lang in die Ferne zu schauen.
class BreakOverlay extends ConsumerStatefulWidget {
  const BreakOverlay({super.key});

  @override
  ConsumerState<BreakOverlay> createState() => _BreakOverlayState();
}

class _BreakOverlayState extends ConsumerState<BreakOverlay> {
  int _secondsLeft = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Pause kann nicht übersprungen werden
      child: Scaffold(
        backgroundColor: AppColors.primary.withAlpha(240),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🦊💤', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Zeit für eine Augenpause!',
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fino ist ein bisschen müde vom Laufen. Schau jetzt für 20 Sekunden aus dem Fenster oder in die Ferne, um deine Augen zu entspannen!',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_secondsLeft > 0)
                  Text(
                    'Noch $_secondsLeft Sekunden...',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      ref.read(healthServiceProvider.notifier).completeBreak();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Weiter geht\'s!'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
