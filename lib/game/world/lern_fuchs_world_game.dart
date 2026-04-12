import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'world_quest_node.dart';

class LernFuchsWorldGame extends FlameGame {
  final ValueChanged<WorldQuestNode> onQuestNodeTapped;
  final _questNodeComponents = <_QuestNodeComponent>[];
  Map<String, dynamic> _worldState = {};

  LernFuchsWorldGame({required this.onQuestNodeTapped});

  static const questNodes = [
    WorldQuestNode(
      id: 'prolog',
      questId: 'prolog_ovas_ruf',
      title: 'Ovas Ruf',
      subtitle: 'Prolog im Fluesterwald',
      mapPosition: Offset(120, 335),
    ),
    WorldQuestNode(
      id: 'zahlenpfad',
      questId: 'main_zahlenpfad',
      title: 'Zahlenpfad',
      subtitle: 'Hauptquest: Zahlen bis 10',
      mapPosition: Offset(235, 235),
    ),
    WorldQuestNode(
      id: 'buchstabenhain',
      questId: 'main_buchstabenhain',
      title: 'Buchstabenhain',
      subtitle: 'Hauptquest: Buchstaben',
      mapPosition: Offset(430, 170),
    ),
    WorldQuestNode(
      id: 'silbenquelle',
      questId: 'side_silbenquelle',
      title: 'Silbenquelle',
      subtitle: 'Nebenquest: Silben',
      mapPosition: Offset(175, 115),
    ),
    WorldQuestNode(
      id: 'musterlichtung',
      questId: 'side_musterlichtung',
      title: 'Musterlichtung',
      subtitle: 'Nebenquest: Muster',
      mapPosition: Offset(420, 385),
    ),
  ];

  @override
  Color backgroundColor() => const Color(0xFFBFE7D2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(_WorldMapBackground());
    world.add(_PlayerPlaceholder(position: Vector2(90, 330)));

    for (final node in questNodes) {
      final component = _QuestNodeComponent(
        questNode: node,
        onTapped: onQuestNodeTapped,
      );
      _questNodeComponents.add(component);
      world.add(component);
    }
  }

  void updateWorldState(Map<String, dynamic> worldState) {
    _worldState = {..._worldState, ...worldState};
    for (final component in _questNodeComponents) {
      component.completed =
          _worldState['${component.questNode.id}_node_state'] == 'completed';
    }
  }
}

class _WorldMapBackground extends PositionComponent {
  _WorldMapBackground()
    : super(position: Vector2.zero(), size: Vector2(640, 480));

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final skyPaint = Paint()..color = const Color(0xFFBFE7D2);
    canvas.drawRect(Offset.zero & Size(size.x, size.y), skyPaint);

    final meadowPaint = Paint()..color = const Color(0xFF7FC77B);
    final pathPaint = Paint()
      ..color = const Color(0xFFE5C27A)
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(Rect.fromLTWH(-80, 250, size.x + 160, 280), meadowPaint);

    final path = Path()
      ..moveTo(120, 335)
      ..quadraticBezierTo(165, 280, 235, 235)
      ..quadraticBezierTo(330, 170, 430, 170)
      ..moveTo(235, 235)
      ..quadraticBezierTo(195, 175, 175, 115)
      ..moveTo(235, 235)
      ..quadraticBezierTo(340, 310, 420, 385);
    canvas.drawPath(path, pathPaint);

    final treePaint = Paint()..color = const Color(0xFF3D8E55);
    for (final point in const [
      Offset(70, 120),
      Offset(120, 90),
      Offset(180, 95),
      Offset(330, 105),
      Offset(560, 120),
      Offset(510, 330),
      Offset(460, 430),
      Offset(90, 420),
    ]) {
      canvas.drawCircle(point, 26, treePaint);
    }
  }
}

class _PlayerPlaceholder extends PositionComponent {
  _PlayerPlaceholder({required super.position})
    : super(size: Vector2.all(52), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final bodyPaint = Paint()..color = const Color(0xFFFF8F3D);
    final facePaint = Paint()..color = const Color(0xFFFFD3A1);
    final outlinePaint = Paint()
      ..color = const Color(0xFF2F2F2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, 24, bodyPaint);
    canvas.drawCircle(center.translate(0, -4), 15, facePaint);
    canvas.drawCircle(center, 24, outlinePaint);
    canvas.drawCircle(
      center.translate(-5, -7),
      2,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      center.translate(5, -7),
      2,
      Paint()..color = Colors.black,
    );
  }
}

class _QuestNodeComponent extends PositionComponent with TapCallbacks {
  final WorldQuestNode questNode;
  final ValueChanged<WorldQuestNode> onTapped;
  bool completed = false;

  _QuestNodeComponent({required this.questNode, required this.onTapped})
    : super(
        position: Vector2(questNode.mapPosition.dx, questNode.mapPosition.dy),
        size: Vector2.all(86),
        anchor: Anchor.center,
      );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final shadowPaint = Paint()..color = Colors.black.withAlpha(45);
    final nodePaint = Paint()
      ..color = completed ? const Color(0xFF8DD86E) : const Color(0xFFFFD95A);
    final ringPaint = Paint()
      ..color = const Color(0xFF6B4E16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final iconPaint = Paint()..color = const Color(0xFFB65B2A);

    canvas.drawCircle(center.translate(0, 4), 30, shadowPaint);
    canvas.drawCircle(center, 30, nodePaint);
    canvas.drawCircle(center, 30, ringPaint);
    canvas.drawCircle(center.translate(0, -5), 8, iconPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 12), width: 28, height: 12),
        const Radius.circular(6),
      ),
      iconPaint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapped(questNode);
  }
}
