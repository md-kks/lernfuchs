import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service zur Gesundheitsprävention (20/20-Regel und Screen-Time).
///
/// Überwacht die aktive Nutzungszeit und triggert Pausen-Events.
class HealthService extends StateNotifier<HealthState> {
  Timer? _breakTimer;
  DateTime? _lastBreak;

  static const breakInterval = Duration(minutes: 20);
  static const breakDuration = Duration(seconds: 20);

  HealthService() : super(HealthState()) {
    _startTimer();
  }

  void _startTimer() {
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      _lastBreak ??= now;

      final timeSinceLastBreak = now.difference(_lastBreak!);
      if (timeSinceLastBreak >= breakInterval) {
        state = state.copyWith(needsBreak: true);
      }
    });
  }

  /// Markiert die Pause als erledigt und startet den Timer neu.
  void completeBreak() {
    _lastBreak = DateTime.now();
    state = state.copyWith(needsBreak: false);
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    super.dispose();
  }
}

class HealthState {
  final bool needsBreak;
  final Duration totalSessionTime;

  HealthState({
    this.needsBreak = false,
    this.totalSessionTime = Duration.zero,
  });

  HealthState copyWith({bool? needsBreak, Duration? totalSessionTime}) {
    return HealthState(
      needsBreak: needsBreak ?? this.needsBreak,
      totalSessionTime: totalSessionTime ?? this.totalSessionTime,
    );
  }
}

final healthServiceProvider = StateNotifierProvider<HealthService, HealthState>((ref) {
  return HealthService();
});
