import 'package:flame/components.dart';
import 'package:flutter/material.dart';

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

  void moveToMapPoint(Vector2 mapPoint) {
    final scale = WorldMapBackground.uniformScale(gameRef.size);
    position = mapPoint - Vector2(0, 42 * scale);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sc = WorldMapBackground.uniformScale(gameRef.size);
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
    _drawRotatedOval(
      canvas,
      Offset(25 * sc, 14 * sc),
      6 * sc,
      4 * sc,
      0.3,
      const Color(0xFFFFFDE7),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 5 * sc),
        width: 26 * sc,
        height: 20 * sc,
      ),
      Paint()..color = const Color(0xFFE64A19),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 7 * sc),
        width: 14 * sc,
        height: 14 * sc,
      ),
      Paint()..color = const Color(0xFFFFFDE7),
    );

    canvas.drawCircle(
      Offset(0, -8 * sc),
      12 * sc,
      Paint()..color = const Color(0xFFEF6C00),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -6 * sc),
        width: 14 * sc,
        height: 16 * sc,
      ),
      Paint()..color = const Color(0xFFFFFDE7),
    );

    for (final sign in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(sign * 10 * sc, -16 * sc)
          ..lineTo(sign * 17 * sc, -28 * sc)
          ..lineTo(sign * 3 * sc, -21 * sc)
          ..close(),
        Paint()..color = const Color(0xFFEF6C00),
      );
      canvas.drawPath(
        Path()
          ..moveTo(sign * 10 * sc, -18 * sc)
          ..lineTo(sign * 14 * sc, -25 * sc)
          ..lineTo(sign * 5 * sc, -21 * sc)
          ..close(),
        Paint()..color = const Color(0xFFFF8F00),
      );
    }

    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(-4 * sc, -9 * sc), 2.5 * sc, eyePaint);
    canvas.drawCircle(Offset(4 * sc, -9 * sc), 2.5 * sc, eyePaint);
    canvas.drawCircle(Offset(-3 * sc, -10 * sc), sc, shinePaint);
    canvas.drawCircle(Offset(5 * sc, -10 * sc), sc, shinePaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -4 * sc),
        width: 5 * sc,
        height: 4 * sc,
      ),
      eyePaint,
    );

    canvas.restore();
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
