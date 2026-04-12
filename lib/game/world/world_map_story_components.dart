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
    final nodePoint = WorldMapBackground.nodePositionToVector(
      screen,
      nodeIndex,
    );
    final popupSize = Size(182 * sc, 104 * sc);
    final below = nodePoint.y <= screen.height * 0.5;
    var left = nodePoint.x + 34 * sc;
    var top = below
        ? nodePoint.y + 42 * sc
        : nodePoint.y - popupSize.height - 74 * sc;
    left = left.clamp(8 * sc, screen.width - popupSize.width - 8 * sc);
    top = top.clamp(8 * sc, screen.height - popupSize.height - 8 * sc);

    final rect = Rect.fromLTWH(left, top, popupSize.width, popupSize.height);
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(8 * sc));
    final border = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 * sc;
    canvas.drawRRect(outer, Paint()..color = const Color(0xED0F0800));
    canvas.drawRRect(outer, border);
    canvas.drawCircle(
      Offset(rect.left + 15 * sc, rect.top + 16 * sc),
      6 * sc,
      Paint()..color = const Color(0xFFE64A19),
    );
    _drawText(
      canvas,
      node.label,
      Offset(rect.left + 28 * sc, rect.top + 8 * sc),
      rect.width - 38 * sc,
      const Color(0xFFFF8F00),
      9 * sc,
      FontWeight.w800,
    );
    _drawText(
      canvas,
      node.storyText,
      Offset(rect.left + 12 * sc, rect.top + 28 * sc),
      rect.width - 24 * sc,
      const Color(0xFFE8D5B0),
      7.5 * sc,
      FontWeight.w600,
      maxLines: 3,
    );

    _buttonRect = Rect.fromLTWH(
      rect.left + 18 * sc,
      rect.bottom - 30 * sc,
      rect.width - 36 * sc,
      22 * sc,
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
      Offset(_buttonRect.left, _buttonRect.top + 5 * sc),
      _buttonRect.width,
      const Color(0xFFE8F5E9),
      8.4 * sc,
      FontWeight.w800,
      align: TextAlign.center,
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
    _drawOva(canvas, center.dx, center.dy, sc * 0.78, fade);

    final rect = Rect.fromLTWH(
      (center.dx - 102 * sc).clamp(8 * sc, screen.width - 204 * sc),
      (center.dy - 72 * sc).clamp(8 * sc, screen.height - 76 * sc),
      204 * sc,
      64 * sc,
    );
    final bubble = RRect.fromRectAndRadius(rect, Radius.circular(7 * sc));
    canvas.drawRRect(
      bubble,
      Paint()..color = Color.fromRGBO(20, 10, 0, 0.92 * fade),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = const Color(0xFFFF8F00).withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * sc,
    );
    final pointer = Path()
      ..moveTo(center.dx - 8 * sc, rect.bottom)
      ..lineTo(center.dx + 8 * sc, rect.bottom)
      ..lineTo(center.dx, center.dy - 8 * sc)
      ..close();
    canvas.drawPath(
      pointer,
      Paint()..color = Color.fromRGBO(20, 10, 0, 0.92 * fade),
    );

    _drawText(
      canvas,
      'Gut gemacht, ${completedNode.label}!',
      Offset(rect.left + 10 * sc, rect.top + 8 * sc),
      rect.width - 20 * sc,
      const Color(0xFFFF8F00).withValues(alpha: fade),
      7.5 * sc,
      FontWeight.w800,
    );
    _drawText(
      canvas,
      'Die ${nextNode.label} öffnet sich!',
      Offset(rect.left + 10 * sc, rect.top + 27 * sc),
      rect.width - 20 * sc,
      const Color(0xFFE8D5B0).withValues(alpha: fade),
      7 * sc,
      FontWeight.w600,
    );
    _drawText(
      canvas,
      'Lauf dorthin!',
      Offset(rect.left + 10 * sc, rect.top + 43 * sc),
      rect.width - 20 * sc,
      const Color(0xFFE8D5B0).withValues(alpha: fade),
      7 * sc,
      FontWeight.w600,
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
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.08,
      ),
    ),
    textAlign: align,
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: width);
  painter.paint(canvas, offset);
}
