import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'lern_fuchs_world_game.dart';
import 'world_map_background.dart';
import 'world_quest_node.dart';

class StoryPopupComponent extends PositionComponent
    with HasGameReference<LernFuchsWorldGame>, TapCallbacks {
  final WorldQuestNode node;
  final int nodeIndex;
  final VoidCallback onQuestStart;

  Rect _buttonRect = Rect.zero;

  StoryPopupComponent({
    required this.node,
    required this.nodeIndex,
    required this.onQuestStart,
  }) : super(priority: 4);

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final screen = Size(game.size.x, game.size.y);
    final sc = WorldMapBackground.uniformScale(game.size);
    final dyslexia = game.accessibility.dyslexiaMode;
    final nodePoint = WorldMapBackground.nodePositionToVector(
      screen,
      nodeIndex,
    );
    final popupSize = Size(math.min(screen.width * 0.72, 280 * sc), 126 * sc);
    final below = nodePoint.y <= screen.height * 0.5;
    var left = nodePoint.x + 34 * sc;
    var top = below
        ? nodePoint.y + 42 * sc
        : nodePoint.y - popupSize.height - 74 * sc;
    left = left.clamp(8 * sc, screen.width - popupSize.width - 8 * sc);
    top = top.clamp(8 * sc, screen.height - popupSize.height - 8 * sc);

    final rect = Rect.fromLTWH(left, top, popupSize.width, popupSize.height);
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(8 * sc));
    final postPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2 * sc;
    canvas.drawLine(Offset(rect.left + 24 * sc, rect.bottom), Offset(nodePoint.x - 5 * sc, nodePoint.y), postPaint);
    canvas.drawLine(Offset(rect.right - 24 * sc, rect.bottom), Offset(nodePoint.x + 5 * sc, nodePoint.y), postPaint);
    canvas.drawRRect(outer, Paint()..color = const Color(0xFF3E2108));
    for (var i = 1; i <= 4; i++) {
      final y = rect.top + i * rect.height / 5;
      canvas.drawLine(
        Offset(rect.left + 8 * sc, y),
        Offset(rect.right - 8 * sc, y + math.sin(i) * 2 * sc),
        Paint()
          ..color = Colors.orange.withValues(alpha: 0.08)
          ..strokeWidth = sc,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, 4 * sc, rect.height),
      Paint()..color = const Color(0xFFFF8F00),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * sc,
    );
    _drawFinoFace(canvas, Offset(rect.left + 17 * sc, rect.top + 17 * sc), sc);
    _drawText(
      canvas,
      node.label,
      Offset(rect.left + 34 * sc, rect.top + 9 * sc),
      rect.width - 38 * sc,
      const Color(0xFFFF8F00),
      14 * sc,
      FontWeight.w800,
      dyslexiaMode: dyslexia,
    );
    _drawText(
      canvas,
      node.storyText,
      Offset(rect.left + 12 * sc, rect.top + 34 * sc),
      rect.width - 24 * sc,
      const Color(0xFFE8D5B0),
      11 * sc,
      FontWeight.w600,
      maxLines: 3,
      dyslexiaMode: dyslexia,
    );

    _buttonRect = Rect.fromLTWH(
      rect.left + 18 * sc,
      rect.bottom - 40 * sc,
      rect.width - 36 * sc,
      32 * sc,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(_buttonRect, Radius.circular(7 * sc)),
      Paint()..color = const Color(0xFF1B5E20),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        _buttonRect.deflate(3 * sc),
        Radius.circular(5 * sc),
      ),
      Paint()..color = const Color(0xFF2E7D32),
    );
    _drawText(
      canvas,
      '▶  Quest starten',
      Offset(_buttonRect.left, _buttonRect.top + 8 * sc),
      _buttonRect.width,
      const Color(0xFFE8F5E9),
      13 * sc,
      FontWeight.w800,
      align: TextAlign.center,
      dyslexiaMode: dyslexia,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_buttonRect.contains(event.localPosition.toOffset())) {
      removeFromParent();
      onQuestStart();
    }
  }
}

void _drawFinoFace(Canvas canvas, Offset center, double sc) {
  canvas.drawCircle(center, 10 * sc, Paint()..color = const Color(0xFFEF6C00));
  for (final sign in const [-1.0, 1.0]) {
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + sign * 6 * sc, center.dy - 7 * sc)
        ..lineTo(center.dx + sign * 11 * sc, center.dy - 16 * sc)
        ..lineTo(center.dx + sign * 2 * sc, center.dy - 11 * sc)
        ..close(),
      Paint()..color = const Color(0xFFEF6C00),
    );
  }
  canvas.drawOval(
    Rect.fromCenter(center: center.translate(0, 2 * sc), width: 12 * sc, height: 10 * sc),
    Paint()..color = const Color(0xFFFFFDE7),
  );
  canvas.drawCircle(center.translate(-3 * sc, -2 * sc), 1.4 * sc, Paint()..color = const Color(0xFF1A1A1A));
  canvas.drawCircle(center.translate(3 * sc, -2 * sc), 1.4 * sc, Paint()..color = const Color(0xFF1A1A1A));
}

class OvaMapBubbleComponent extends PositionComponent
    with HasGameReference<LernFuchsWorldGame> {
  final WorldQuestNode completedNode;
  final WorldQuestNode nextNode;
  final int edgeIndex;
  double _elapsed = 0;

  OvaMapBubbleComponent({
    required this.completedNode,
    required this.nextNode,
    required this.edgeIndex,
  }) : super(priority: 3);

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= 2.5) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final screen = Size(game.size.x, game.size.y);
    final sc = WorldMapBackground.uniformScale(game.size);
    final dyslexia = game.accessibility.dyslexiaMode;
    final fade = _elapsed <= 2.1
        ? 1.0
        : (1 - ((_elapsed - 2.1) / 0.4)).clamp(0.0, 1.0);
    final nodePoint = WorldMapBackground.nodePositionToVector(
      screen,
      nextNode.order,
    );
    final mid = WorldMapBackground.edgePointToVector(screen, edgeIndex, 0.5);
    final center = Offset(mid.x, mid.y - 34 * sc);

    canvas.drawCircle(
      Offset(nodePoint.x, nodePoint.y),
      28 * sc,
      Paint()..color = Color.fromRGBO(130, 220, 90, 0.18 * fade),
    );
    final ovaY = game.accessibility.calmMode
        ? center.dy
        : center.dy + math.sin(_elapsed * 12) * 2 * sc;
    _drawOva(canvas, center.dx, ovaY, sc, fade);

    final rect = Rect.fromLTWH(
      (center.dx - 102 * sc).clamp(8 * sc, screen.width - 204 * sc),
      (center.dy - 72 * sc).clamp(8 * sc, screen.height - 76 * sc),
      204 * sc,
      64 * sc,
    );
    final bubble = RRect.fromRectAndRadius(rect, Radius.circular(7 * sc));
    canvas.drawRRect(bubble, Paint()..color = const Color(0xFF3E2108).withValues(alpha: fade));
    for (var i = 1; i <= 4; i++) {
      final y = rect.top + i * rect.height / 5;
      canvas.drawLine(
        Offset(rect.left + 8 * sc, y),
        Offset(rect.right - 8 * sc, y + math.sin(i) * sc),
        Paint()
          ..color = Colors.orange.withValues(alpha: 0.08 * fade)
          ..strokeWidth = sc,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, 4 * sc, rect.height),
      Paint()..color = const Color(0xFFFF8F00).withValues(alpha: fade),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * sc,
    );

    _drawText(
      canvas,
      'Gut gemacht!',
      Offset(rect.left + 10 * sc, rect.top + 8 * sc),
      rect.width - 20 * sc,
      const Color(0xFFFF8F00).withValues(alpha: fade),
      7.5 * sc,
      FontWeight.w800,
      dyslexiaMode: dyslexia,
    );
    _drawText(
      canvas,
      '${nextNode.label} öffnet sich!',
      Offset(rect.left + 10 * sc, rect.top + 27 * sc),
      rect.width - 20 * sc,
      const Color(0xFFE8D5B0).withValues(alpha: fade),
      7 * sc,
      FontWeight.w600,
      dyslexiaMode: dyslexia,
    );
    _drawText(
      canvas,
      'Fino kann weiterziehen.',
      Offset(rect.left + 10 * sc, rect.top + 43 * sc),
      rect.width - 20 * sc,
      const Color(0xFFE8D5B0).withValues(alpha: fade),
      7 * sc,
      FontWeight.w600,
      dyslexiaMode: dyslexia,
    );
  }

  void _drawOva(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double opacity,
  ) {
    final body = Paint()
      ..color = const Color(0xFFFF8F00).withValues(alpha: opacity);
    final dark = Paint()
      ..color = const Color(0xFF5D4037).withValues(alpha: opacity);
    canvas.drawCircle(Offset(cx, cy), 7 * scale, body);
    canvas.drawPath(
      Path()
        ..moveTo(cx - 4 * scale, cy - 5 * scale)
        ..lineTo(cx - 9 * scale, cy - 12 * scale)
        ..lineTo(cx - 1 * scale, cy - 8 * scale)
        ..close(),
      dark,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 4 * scale, cy - 5 * scale)
        ..lineTo(cx + 9 * scale, cy - 12 * scale)
        ..lineTo(cx + 1 * scale, cy - 8 * scale)
        ..close(),
      dark,
    );
    final eye = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: opacity);
    canvas.drawCircle(
      Offset(cx - 2.5 * scale, cy - 1 * scale),
      1.2 * scale,
      eye,
    );
    canvas.drawCircle(
      Offset(cx + 2.5 * scale, cy - 1 * scale),
      1.2 * scale,
      eye,
    );
    canvas.drawCircle(
      Offset(cx - 2 * scale, cy - 1.5 * scale),
      0.45 * scale,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      Offset(cx + 3 * scale, cy - 1.5 * scale),
      0.45 * scale,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
  }
}

void _drawText(
  Canvas canvas,
  String text,
  Offset offset,
  double width,
  Color color,
  double fontSize,
  FontWeight weight, {
  TextAlign align = TextAlign.start,
  int maxLines = 1,
  bool dyslexiaMode = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.08,
        fontFamily: dyslexiaMode ? 'OpenDyslexic' : null,
        letterSpacing: dyslexiaMode ? fontSize * 0.08 : null,
      ),
    ),
    textAlign: align,
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: width);
  painter.paint(canvas, offset);
}
