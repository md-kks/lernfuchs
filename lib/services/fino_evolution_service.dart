import 'dart:math' as math;
import 'dart:ui';

import '../core/services/storage_service.dart';

class FinoStyle {
  final int stage;
  final bool hasNecklace;
  final int necklaceCount;
  final bool hasEyeGlow;
  final Color eyeGlowColor;
  final bool hasGoldenTailTip;
  final bool hasBook;
  final double earAngleModifier;
  final double bodyScaleModifier;

  const FinoStyle({
    required this.stage,
    required this.hasNecklace,
    required this.necklaceCount,
    required this.hasEyeGlow,
    required this.eyeGlowColor,
    required this.hasGoldenTailTip,
    required this.hasBook,
    required this.earAngleModifier,
    required this.bodyScaleModifier,
  });

  static FinoStyle forStage(int stage) {
    final clamped = stage.clamp(0, 4).toInt();
    return FinoStyle(
      stage: clamped,
      hasNecklace: clamped >= 1,
      necklaceCount: clamped > 3 ? 3 : clamped,
      hasEyeGlow: clamped >= 3,
      eyeGlowColor: clamped >= 4
          ? const Color(0x66ADD8E6)
          : const Color(0x3399CCFF),
      hasGoldenTailTip: clamped >= 4,
      hasBook: clamped == 4,
      earAngleModifier: (clamped - 2) * 2.5 * math.pi / 180,
      bodyScaleModifier: 0.92 + clamped * 0.02,
    );
  }
}

class FinoEvolutionService {
  int get currentStage {
    return StorageService.instance.getIntValue(
      'fino_evolution_stage',
      defaultValue: 0,
    );
  }

  FinoStyle get style => FinoStyle.forStage(currentStage);

  Future<bool> checkAndAdvance() async {
    final storage = StorageService.instance;
    final worldsCompleted = [1, 2, 3, 4]
        .where((world) => storage.getStringValue('world_${world}_completed_at') != null)
        .length;
    final newStage = worldsCompleted.clamp(0, 4).toInt();
    if (newStage > currentStage) {
      await storage.setOnboardingValue('fino_evolution_stage', newStage);
      return true;
    }
    return false;
  }
}
