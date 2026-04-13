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
    _drawLabel(canvas, sc);
    canvas.restore();
  }

  void _drawPlatform(Canvas canvas, double sc) {
    final r = 32 * sc;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(4 * sc, 8 * sc),
        width: r * 2,
        height: r * 0.76,
      ),
      Paint()..color = const Color(0x47000000),
    );

    if (questNode.state == QuestNodeState.current) {
      _drawRing(canvas, r + 12 * sc, 7 * sc, const Color(0x73FFB400));
      _drawRing(canvas, r + 5 * sc, 3.5 * sc, const Color(0xB3FFC832));
    } else if (questNode.state == QuestNodeState.available) {
      _drawRing(canvas, r + 9 * sc, 5 * sc, const Color(0x7382DC5A));
    }

    final outerColor = switch (questNode.state) {
      QuestNodeState.locked => const Color(0xFF3F5A64),
      QuestNodeState.completed => const Color(0xFF5D3D28),
      _ => const Color(0xFF6B4420),
    };
    final innerColor = switch (questNode.state) {
      QuestNodeState.locked => const Color(0xFF6E8F9A),
      QuestNodeState.completed => const Color(0xFF8B6550),
      QuestNodeState.current => const Color(0xFFE8A800),
      QuestNodeState.available => const Color(0xFFA07850),
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
    if (questNode.state == QuestNodeState.locked) {
      _drawLock(canvas, sc);
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
          Paint()..color = const Color(0xFFFF8F00),
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
          ..color = const Color(0xFF29B6F6)
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
        final paint = Paint()..color = const Color(0xFF29B6F6);
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

  void _drawLock(Canvas canvas, double sc) {
    final shacklePaint = Paint()
      ..color = const Color(0xFF9DBEC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * sc
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, -4 * sc),
        width: 15 * sc,
        height: 15 * sc,
      ),
      math.pi,
      math.pi,
      false,
      shacklePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, 3 * sc),
          width: 20 * sc,
          height: 16 * sc,
        ),
        Radius.circular(3 * sc),
      ),
      Paint()..color = const Color(0xFF7A9EAB),
    );
    canvas.drawCircle(
      Offset(0, 3 * sc),
      2.2 * sc,
      Paint()..color = const Color(0xFF9DBEC8),
    );
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
      QuestNodeState.locked => const Color(0xFF9EC8D5),
      QuestNodeState.completed => const Color(0xFFFFD180),
      _ => const Color(0xFFB9F0BC),
    };
    final bgColor = switch (questNode.state) {
      QuestNodeState.locked => const Color(0xE1142834),
      QuestNodeState.completed => const Color(0xE114140A),
      _ => const Color(0xE1051605),
    };
    final painter = TextPainter(
      text: TextSpan(
        text: questNode.label,
        style: TextStyle(
          color: textColor,
          fontSize: 14 * sc,
          fontWeight: FontWeight.bold,
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

  @override
  void onTapUp(TapUpEvent event) {
    gameRef.onNodeTapped(questNode);
  }
}
