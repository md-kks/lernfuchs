import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'lern_fuchs_world_game.dart';
import 'world_map_background.dart';
import 'world_quest_node.dart';

class WorldMapNodeComponent extends PositionComponent
    with HasGameRef<LernFuchsWorldGame>, TapCallbacks {
  WorldQuestNode questNode;
  final int nodeIndex;

  WorldMapNodeComponent({required this.questNode, required this.nodeIndex})
    : super(size: Vector2.all(100), anchor: Anchor.center, priority: 1);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final screenSize = Size(gameRef.size.x, gameRef.size.y);
    position = WorldMapBackground.nodePositionToVector(screenSize, nodeIndex);
  }

  void updateQuestNode(WorldQuestNode node) {
    questNode = node;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sc = WorldMapBackground.uniformScale(gameRef.size);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    _drawPlatform(canvas, sc);
    _drawIcon(canvas, sc);
    if (questNode.state == QuestNodeState.completed) _drawCrystal(canvas, sc);
    if (questNode.state == QuestNodeState.nextAvailable) _drawSparkle(canvas, sc);
    _drawLabel(canvas, sc);
    canvas.restore();
  }

  void _drawPlatform(Canvas canvas, double sc) {
    final motorScale = gameRef.accessibility.motorMode ? 1.18 : 1.0;
    final r = (questNode.state == QuestNodeState.lockedFar ? 10 * sc : 32 * sc) *
        motorScale;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(4 * sc, 8 * sc),
        width: r * 2,
        height: r * 0.76,
      ),
      Paint()..color = const Color(0x47000000),
    );

    if (questNode.state == QuestNodeState.current) {
      _drawRing(canvas, r + 12 * sc, 7 * sc, _calm(const Color(0x73FFB400)));
      _drawRing(canvas, r + 5 * sc, 3.5 * sc, _calm(const Color(0xB3FFC832)));
    } else if (questNode.state == QuestNodeState.nextAvailable) {
      _drawRing(canvas, r + 9 * sc, 5 * sc, _calm(const Color(0x7382DC5A)));
    }

    final outerColor = switch (questNode.state) {
      QuestNodeState.lockedNear => const Color(0xFF2A3A2A),
      QuestNodeState.lockedFar => const Color(0xFF1E1E1E),
      QuestNodeState.completed => const Color(0xFF3D2B1A),
      QuestNodeState.nextAvailable => const Color(0xFF2D4A1E),
      QuestNodeState.expedition => const Color(0xFF5D4037),
      _ => const Color(0xFF6B4420),
    };
    final innerColor = switch (questNode.state) {
      QuestNodeState.lockedNear => const Color(0xFF3A4A3A),
      QuestNodeState.lockedFar => const Color(0xFF2A2A2A),
      QuestNodeState.completed => const Color(0xFF5D3D28),
      QuestNodeState.current => const Color(0xFFE8A800),
      QuestNodeState.nextAvailable => const Color(0xFF4E8038),
      QuestNodeState.expedition => const Color(0xFFFF8F00),
    };

    canvas.drawCircle(Offset.zero, r, Paint()..color = outerColor);
    canvas.drawCircle(Offset.zero, r - 5 * sc, Paint()..color = innerColor);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(-6 * sc, -8 * sc), radius: 7 * sc),
      0.8,
      1.5,
      false,
      Paint()
        ..color = const Color(0x38FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * sc
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawRing(Canvas canvas, double radius, double width, Color color) {
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _drawIcon(Canvas canvas, double sc) {
    if (questNode.state == QuestNodeState.lockedFar) {
      return;
    }
    if (questNode.state == QuestNodeState.expedition) {
      _drawCampfire(canvas, sc);
      return;
    }
    if (questNode.state == QuestNodeState.lockedNear) {
      _drawLeaf(canvas, sc);
      return;
    }

    if (questNode.state == QuestNodeState.completed) {
      final path = Path()
        ..moveTo(-9 * sc, 1 * sc)
        ..lineTo(-3 * sc, 8 * sc)
        ..lineTo(9 * sc, -6 * sc);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFE082)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 * sc
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      return;
    }

    switch (questNode.type) {
      case QuestNodeType.start:
      case QuestNodeType.clearing:
        canvas.drawPath(
          _starPath(12 * sc, 5 * sc),
          Paint()
            ..color = questNode.state == QuestNodeState.current
                ? Colors.white
                : const Color(0xFFE8F5E9),
        );
        return;
      case QuestNodeType.tree:
        canvas.drawCircle(
          Offset(0, -5 * sc),
          10 * sc,
          Paint()..color = const Color(0xFF1B5E20),
        );
        canvas.drawCircle(
          Offset(-3 * sc, -8 * sc),
          6 * sc,
          Paint()..color = const Color(0xFF2E7D32),
        );
        canvas.drawCircle(
          Offset(2 * sc, -10 * sc),
          4 * sc,
          Paint()..color = const Color(0xFF388E3C),
        );
        canvas.drawRect(
          Rect.fromLTWH(-2.5 * sc, 4 * sc, 5 * sc, 7 * sc),
          Paint()..color = const Color(0xFF3E2108),
        );
        return;
      case QuestNodeType.bridge:
        final paint = Paint()
          ..color = questNode.state == QuestNodeState.current
              ? Colors.white
              : const Color(0xFFE8F5E9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.7 * sc
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(0, 8 * sc), radius: 11 * sc),
          math.pi,
          math.pi,
          false,
          paint,
        );
        canvas.drawLine(Offset(-7 * sc, 8 * sc), Offset(-7 * sc, 0), paint);
        canvas.drawLine(Offset(7 * sc, 8 * sc), Offset(7 * sc, 0), paint);
        final wave = Path()
          ..moveTo(-12 * sc, 10 * sc)
          ..cubicTo(-6 * sc, 6 * sc, -3 * sc, 14 * sc, 2 * sc, 10 * sc)
          ..cubicTo(6 * sc, 7 * sc, 9 * sc, 13 * sc, 13 * sc, 9 * sc);
        canvas.drawPath(wave, paint);
        return;
      case QuestNodeType.lake:
        final paint = Paint()
          ..color = questNode.state == QuestNodeState.current
              ? Colors.white
              : const Color(0xFFE8F5E9);
        canvas.drawCircle(Offset(0, 4 * sc), 9 * sc, paint);
        canvas.drawPath(
          Path()
            ..moveTo(0, -10 * sc)
            ..lineTo(-6.5 * sc, 1 * sc)
            ..lineTo(6.5 * sc, 1 * sc)
            ..close(),
          paint,
        );
        canvas.drawCircle(
          Offset(4 * sc, 5 * sc),
          1.5 * sc,
          Paint()..color = Colors.white.withAlpha(160),
        );
        return;
    }
  }

  Color _calm(Color color) {
    if (!gameRef.accessibility.calmMode) return color;
    return color.withAlpha((color.alpha * 0.5).round());
  }

  void _drawLeaf(Canvas canvas, double sc) {
    final leafPaint = Paint()
      ..color = const Color(0xFF5A7A5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * sc
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-10 * sc, 8 * sc)
      ..quadraticBezierTo(-8 * sc, -12 * sc, 11 * sc, -10 * sc)
      ..quadraticBezierTo(13 * sc, 7 * sc, -8 * sc, 9 * sc)
      ..moveTo(-7 * sc, 7 * sc)
      ..quadraticBezierTo(0, 0, 9 * sc, -8 * sc);
    canvas.drawPath(path, leafPaint);
  }

  void _drawCrystal(Canvas canvas, double sc) {
    final path = Path()
      ..moveTo(0, -43 * sc)
      ..lineTo(7 * sc, -35 * sc)
      ..lineTo(0, -25 * sc)
      ..lineTo(-7 * sc, -35 * sc)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF29B6F6));
    canvas.drawLine(
      Offset(0, -43 * sc),
      Offset(0, -25 * sc),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = sc,
    );
  }

  void _drawSparkle(Canvas canvas, double sc) {
    canvas.save();
    canvas.translate(0, -38 * sc);
    if (!gameRef.accessibility.calmMode) {
      canvas.rotate(DateTime.now().millisecondsSinceEpoch / 900);
    }
    final sparkle = Path()
      ..moveTo(0, -8 * sc)
      ..lineTo(2.5 * sc, -2.5 * sc)
      ..lineTo(8 * sc, 0)
      ..lineTo(2.5 * sc, 2.5 * sc)
      ..lineTo(0, 8 * sc)
      ..lineTo(-2.5 * sc, 2.5 * sc)
      ..lineTo(-8 * sc, 0)
      ..lineTo(-2.5 * sc, -2.5 * sc)
      ..close();
    canvas.drawPath(sparkle, Paint()..color = const Color(0xFFFFD700));
    canvas.restore();
  }

  Path _starPath(double outerRadius, double innerRadius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _drawLabel(Canvas canvas, double sc) {
    final py = 40 * sc;
    final textColor = switch (questNode.state) {
      QuestNodeState.lockedNear => const Color(0xFF6D8A6D),
      QuestNodeState.lockedFar => Colors.transparent,
      QuestNodeState.completed => const Color(0xFFFFD180),
      QuestNodeState.expedition => const Color(0xFFFF8F00),
      _ => const Color(0xFFB9F0BC),
    };
    if (questNode.state == QuestNodeState.lockedFar) return;
    final bgColor = switch (questNode.state) {
      QuestNodeState.lockedNear => const Color(0xB1121A12),
      QuestNodeState.lockedFar => Colors.transparent,
      QuestNodeState.completed => const Color(0xE114140A),
      QuestNodeState.expedition => const Color(0xE13E2108),
      _ => const Color(0xE1051605),
    };
    final painter = TextPainter(
      text: TextSpan(
        text: questNode.state == QuestNodeState.lockedNear ? '???' : questNode.label,
        style: TextStyle(
          color: textColor,
          fontSize: 14 * sc,
          fontWeight: FontWeight.bold,
          fontFamily: gameRef.accessibility.dyslexiaMode ? 'OpenDyslexic' : null,
          letterSpacing: gameRef.accessibility.dyslexiaMode ? 14 * sc * 0.08 : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final padding = 5 * sc;
    final rect = Rect.fromCenter(
      center: Offset(0, py),
      width: painter.width + padding * 2,
      height: painter.height + 4 * sc,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(3 * sc)),
      Paint()..color = bgColor,
    );
    painter.paint(canvas, Offset(-painter.width / 2, py - painter.height / 2));
  }

  void _drawCampfire(Canvas canvas, double sc) {
    final logPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.save();
    canvas.rotate(-0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, 11 * sc), width: 28 * sc, height: 7 * sc),
        Radius.circular(3 * sc),
      ),
      logPaint,
    );
    canvas.restore();
    canvas.save();
    canvas.rotate(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, 11 * sc), width: 28 * sc, height: 7 * sc),
        Radius.circular(3 * sc),
      ),
      logPaint,
    );
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(0, -18 * sc)
        ..quadraticBezierTo(13 * sc, -2 * sc, 0, 12 * sc)
        ..quadraticBezierTo(-13 * sc, -2 * sc, 0, -18 * sc),
      Paint()..color = const Color(0xFFFF6F00),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -10 * sc)
        ..quadraticBezierTo(7 * sc, 0, 0, 8 * sc)
        ..quadraticBezierTo(-7 * sc, 0, 0, -10 * sc),
      Paint()..color = const Color(0xFFFFC107),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (questNode.state == QuestNodeState.lockedFar ||
        questNode.state == QuestNodeState.lockedNear) {
      return;
    }
    gameRef.onNodeTapped(questNode);
  }
}
