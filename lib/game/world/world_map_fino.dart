import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/fino_evolution_service.dart';
import '../../services/season_service.dart';
import 'lern_fuchs_world_game.dart';
import 'world_map_background.dart';

class WorldMapFinoComponent extends PositionComponent
    with HasGameRef<LernFuchsWorldGame> {
  WorldMapFinoComponent()
    : super(size: Vector2.all(80), anchor: Anchor.center, priority: 2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final screenSize = Size(gameRef.size.x, gameRef.size.y);
    final scale = WorldMapBackground.uniformScale(gameRef.size);
    position =
        WorldMapBackground.nodePositionToVector(screenSize, 0) -
        Vector2(0, 42 * scale);
  }

  void moveToMapPoint(Vector2 mapPoint, {double hopOffset = 0}) {
    final scale = WorldMapBackground.uniformScale(gameRef.size);
    position = mapPoint - Vector2(0, 42 * scale + hopOffset);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sc = WorldMapBackground.uniformScale(gameRef.size);
    final style = gameRef.finoStyle;
    final bodyScale = sc * style.bodyScaleModifier;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    _drawRotatedOval(
      canvas,
      Offset(16 * sc, 10 * sc),
      15 * sc,
      8 * sc,
      0.3,
      const Color(0xFFD84315),
    );
    if (style.hasGoldenTailTip) {
      canvas.drawCircle(
        Offset(25 * sc, 14 * sc),
        5 * sc,
        Paint()..color = const Color(0x66FFD700),
      );
    }
    _drawRotatedOval(
      canvas,
      Offset(25 * sc, 14 * sc),
      6 * sc,
      4 * sc,
      0.3,
      style.hasGoldenTailTip ? const Color(0xFFFFD700) : const Color(0xFFFFFDE7),
    );

    if (style.hasBook) {
      canvas.drawCircle(Offset(-4 * sc, 4 * sc), 12 * sc, Paint()..color = const Color(0x26FFD700));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(-9 * sc, 2 * sc), width: 8 * sc, height: 10 * sc),
          Radius.circular(2 * sc),
        ),
        Paint()..color = const Color(0xFF3E2108),
      );
      canvas.drawRect(
        Rect.fromLTWH(-6 * sc, -3 * sc, 1.5 * sc, 10 * sc),
        Paint()..color = const Color(0xFFFFD700),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 5 * bodyScale),
        width: 26 * bodyScale,
        height: 20 * bodyScale,
      ),
      Paint()..color = const Color(0xFFE64A19),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 7 * bodyScale),
        width: 14 * bodyScale,
        height: 14 * bodyScale,
      ),
      Paint()..color = const Color(0xFFFFFDE7),
    );

    canvas.drawCircle(
      Offset(0, -8 * bodyScale),
      12 * bodyScale,
      Paint()..color = const Color(0xFFEF6C00),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -6 * bodyScale),
        width: 14 * bodyScale,
        height: 16 * bodyScale,
      ),
      Paint()..color = const Color(0xFFFFFDE7),
    );
    if (gameRef.season?.specialDay == SpecialDay.halloween) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, 3 * sc),
          width: 31 * sc,
          height: 48 * sc,
        ),
        Paint()..color = Colors.white.withOpacity(0.72),
      );
      canvas.drawCircle(Offset(-5 * sc, -7 * sc), 2 * sc, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(5 * sc, -7 * sc), 2 * sc, Paint()..color = Colors.black);
    }

    canvas.save();
    canvas.rotate(style.earAngleModifier);
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(sign * 10 * bodyScale, -16 * bodyScale)
          ..lineTo(sign * 17 * bodyScale, -28 * bodyScale)
          ..lineTo(sign * 3 * bodyScale, -21 * bodyScale)
          ..close(),
        Paint()..color = const Color(0xFFEF6C00),
      );
      canvas.drawPath(
        Path()
          ..moveTo(sign * 10 * bodyScale, -18 * bodyScale)
          ..lineTo(sign * 14 * bodyScale, -25 * bodyScale)
          ..lineTo(sign * 5 * bodyScale, -21 * bodyScale)
          ..close(),
        Paint()..color = const Color(0xFFFF8F00),
      );
    }
    canvas.restore();

    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(-4 * bodyScale, -9 * bodyScale), 2.5 * bodyScale, eyePaint);
    canvas.drawCircle(Offset(4 * bodyScale, -9 * bodyScale), 2.5 * bodyScale, eyePaint);
    canvas.drawCircle(Offset(-3 * sc, -10 * sc), sc, shinePaint);
    canvas.drawCircle(Offset(5 * sc, -10 * sc), sc, shinePaint);
    if (style.hasEyeGlow) {
      canvas.drawCircle(Offset(-4 * bodyScale, -9 * bodyScale), 3.5 * bodyScale, Paint()..color = style.eyeGlowColor);
      canvas.drawCircle(Offset(4 * bodyScale, -9 * bodyScale), 3.5 * bodyScale, Paint()..color = style.eyeGlowColor);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -4 * bodyScale),
        width: 5 * bodyScale,
        height: 4 * bodyScale,
      ),
      eyePaint,
    );

    if (style.hasNecklace) {
      _drawNecklace(canvas, sc, style);
    }

    canvas.restore();
  }

  void _drawNecklace(Canvas canvas, double sc, FinoStyle style) {
    final cord = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * sc;
    final rect = Rect.fromCenter(
      center: Offset(0, 3 * sc),
      width: 22 * sc,
      height: 16 * sc,
    );
    canvas.drawArc(rect, 0.05 * math.pi, 0.9 * math.pi, false, cord);
    final count = style.necklaceCount.clamp(1, 3);
    for (var i = 0; i < count; i++) {
      final dx = (i - (count - 1) / 2) * 6 * sc;
      final p = Offset(dx, 10 * sc - (count == 1 ? 0 : (i - 1).abs() * 2 * sc));
      canvas.drawCircle(p, 4 * sc, Paint()..color = const Color(0x4D29B6F6));
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - 2.5 * sc)
          ..lineTo(p.dx + 2.5 * sc, p.dy)
          ..lineTo(p.dx, p.dy + 2.5 * sc)
          ..lineTo(p.dx - 2.5 * sc, p.dy)
          ..close(),
        Paint()..color = const Color(0xFF29B6F6),
      );
    }
  }

  void _drawRotatedOval(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    double rotation,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      Paint()..color = color,
    );
    canvas.restore();
  }
}
