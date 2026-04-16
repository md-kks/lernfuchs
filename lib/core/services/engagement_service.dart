import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/engagement_engine.dart';

/// Service zur Echtzeit-Überwachung des Engagements (EDDA).
class EngagementService extends StateNotifier<EngagementState> {
  Timer? _monitorTimer;
  int _idleSeconds = 0;
  int _currentErrors = 0;
  int _taskComplexity = 1;

  EngagementService() : super(const EngagementState());

  /// Startet die Überwachung für eine neue Aufgabe.
  void startTask(int difficulty) {
    _monitorTimer?.cancel();
    _idleSeconds = 0;
    _currentErrors = 0;
    _taskComplexity = difficulty;
    state = const EngagementState(); // Zurücksetzen auf 100% Engagement

    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _idleSeconds++;
      _updateScore();
    });
  }

  /// Registriert eine Interaktion (Klick, Zeichnen), setzt den Idle-Timer zurück.
  void recordInteraction() {
    if (_idleSeconds > 0) {
      _idleSeconds = 0;
      _updateScore();
    }
  }

  /// Registriert einen Fehlerversuch.
  void recordError() {
    _currentErrors++;
    _updateScore();
  }

  void _updateScore() {
    final score = EddaEngine.calculateEngagementScore(
      idleTimeSeconds: _idleSeconds,
      errorCount: _currentErrors,
      taskComplexity: _taskComplexity,
    );

    state = state.copyWith(
      score: score,
      isInSleepPhase: _idleSeconds < EddaEngine.sleepPhaseDuration,
      interventionTriggered: EddaEngine.needsIntervention(score),
    );
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }
}

final engagementServiceProvider = StateNotifierProvider<EngagementService, EngagementState>((ref) {
  return EngagementService();
});
