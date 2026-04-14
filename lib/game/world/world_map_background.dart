import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/season_service.dart';
import 'lern_fuchs_world_game.dart';
import 'world_quest_node.dart';

class WorldMapBackground extends Component with HasGameRef<LernFuchsWorldGame> {
  static const referenceSize = Size(400, 660);

  static const nodePositions = [
    Offset(130 / 400, 570 / 660),
    Offset(200 / 400, 415 / 660),
    Offset(92 / 400, 262 / 660),
    Offset(295 / 400, 308 / 660),
    Offset(210 / 400, 115 / 660),
  ];

  static const edges = [(0, 1), (1, 2), (1, 3), (2, 3), (2, 4), (3, 4)];

  static const controlPoints = [
    Offset(158 / 400, 500 / 660),
    Offset(140 / 400, 345 / 660),
    Offset(250 / 400, 390 / 660),
    Offset(190 / 400, 290 / 660),
    Offset(165 / 400, 258 / 660),
    Offset(256 / 400, 215 / 660),
  ];

  static const sequentialEdges = [0, 1, 3, 5];

  WorldMapBackground() : super(priority: 0);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenSize = Size(gameRef.size.x, gameRef.size.y);
    final season = gameRef.season;
    final backgroundPaint = Paint()
      ..color = season?.season == Season.winter
          ? const Color(0xFF8ABCB0)
          : const Color(0xFF9DC49F);
    canvas.drawRect(Offset.zero & screenSize, backgroundPaint);

    final patchPaint = Paint()..color = const Color(0x1AFFF8D7);
    for (final patch in const [
      (70.0, 105.0, 84.0),
      (330.0, 94.0, 92.0),
      (84.0, 598.0, 104.0),
      (332.0, 486.0, 118.0),
    ]) {
      canvas.drawCircle(
        _point(screenSize, patch.$1, patch.$2),
        _radius(screenSize, patch.$3),
        patchPaint,
      );
    }

    for (final tree in const [
      (30.0, 215.0, 44.0),
      (68.0, 158.0, 36.0),
      (362.0, 192.0, 50.0),
      (395.0, 152.0, 39.0),
      (382.0, 570.0, 42.0),
      (14.0, 488.0, 40.0),
      (16.0, 138.0, 34.0),
      (378.0, 442.0, 36.0),
    ]) {
      _drawTree(canvas, screenSize, tree.$1, tree.$2, tree.$3, true);
    }

    _drawClearing(canvas, screenSize);
    _drawPaths(canvas, screenSize);

    for (final tree in const [
      (44.0, 398.0, 56.0),
      (355.0, 262.0, 60.0),
      (370.0, 508.0, 48.0),
      (46.0, 552.0, 52.0),
      (325.0, 140.0, 58.0),
      (155.0, 107.0, 44.0),
    ]) {
      _drawTree(canvas, screenSize, tree.$1, tree.$2, tree.$3, false);
    }

    _drawAmbient(canvas, screenSize);
    _drawTree(canvas, screenSize, -5, 548, 68, false);
    _drawTree(canvas, screenSize, 408, 538, 64, false);
    if (season != null) _drawSeasonalExtras(canvas, screenSize, season);
  }

  void _drawClearing(Canvas canvas, Size screenSize) {
    final outer = _oval(screenSize, 205, 388, 165, 245);
    final inner = _oval(screenSize, 205, 376, 120, 195);
    canvas.drawOval(outer, Paint()..color = const Color(0xFF3D6B2E));
    canvas.drawOval(inner, Paint()..color = const Color(0xFF4E8038));

    final sc = _scale(screenSize);
    final grassPaint = Paint()
      ..color = const Color(0x66305F28)
      ..strokeWidth = 1.4 * sc
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 35; i++) {
      final angle = i * 0.82;
      final x = 205 + math.sin(angle) * (28 + (i % 7) * 13);
      final y = 382 + math.cos(angle * 1.37) * (26 + (i % 5) * 22);
      final p1 = _point(screenSize, x, y);
      final p2 = p1.translate(
        math.cos(angle) * 5 * sc,
        -math.sin(angle * 0.7).abs() * 7 * sc,
      );
      canvas.drawLine(p1, p2, grassPaint);
    }
  }

  void _drawPaths(Canvas canvas, Size screenSize) {
    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final endState = gameRef.stateForOrder(edge.$2);
      final start = _fractional(screenSize, nodePositions[edge.$1]);
      final end = _fractional(screenSize, nodePositions[edge.$2]);
      final control = _fractional(screenSize, controlPoints[i]);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

      if (endState == QuestNodeState.lockedNear ||
          endState == QuestNodeState.lockedFar) {
        final color = endState == QuestNodeState.lockedNear
            ? const Color(0x665A7A5A)
            : const Color(0x264A4A4A);
        _drawDottedPath(canvas, path, screenSize, color);
        continue;
      }

      for (final stroke in const [
        (18.0, Color(0xFF4A2E00)),
        (13.0, Color(0xFF9E7B60)),
        (5.0, Color(0x72C8AA82)),
      ]) {
        canvas.drawPath(
          path,
          Paint()
            ..color = stroke.$2
            ..style = PaintingStyle.stroke
            ..strokeWidth = _radius(screenSize, stroke.$1)
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawDottedPath(Canvas canvas, Path path, Size screenSize, Color color) {
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _radius(screenSize, 4)
      ..strokeCap = StrokeCap.round;
    for (var distance = 0.0; distance < metric.length; distance += 14 * _scale(screenSize)) {
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) canvas.drawPoints(PointMode.points, [tangent.position], paint);
    }
  }

  void _drawAmbient(Canvas canvas, Size screenSize) {
    for (final mushroom in const [
      (168.0, 530.0),
      (252.0, 375.0),
      (315.0, 452.0),
    ]) {
      _drawMushroom(canvas, screenSize, mushroom.$1, mushroom.$2);
    }

    for (final flower in const [
      (322.0, 482.0),
      (88.0, 452.0),
      (222.0, 542.0),
    ]) {
      _drawFlower(canvas, screenSize, flower.$1, flower.$2);
    }
  }

  void _drawMushroom(Canvas canvas, Size screenSize, double x, double y) {
    final sc = _scale(screenSize);
    final stemPaint = Paint()..color = const Color(0xFFFFF4D8);
    final capPaint = Paint()..color = const Color(0xFFD84315);
    final spotPaint = Paint()..color = const Color(0xFFFFF8E1);
    final base = _point(screenSize, x, y);
    canvas.drawRect(
      Rect.fromCenter(
        center: base.translate(0, -4 * sc),
        width: 5 * sc,
        height: 9 * sc,
      ),
      stemPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: base.translate(0, -8 * sc),
        width: 17 * sc,
        height: 13 * sc,
      ),
      math.pi,
      math.pi,
      true,
      capPaint,
    );
    canvas.drawCircle(base.translate(-3 * sc, -10 * sc), 1.4 * sc, spotPaint);
    canvas.drawCircle(base.translate(3 * sc, -11 * sc), 1.2 * sc, spotPaint);
  }

  void _drawFlower(Canvas canvas, Size screenSize, double x, double y) {
    final sc = _scale(screenSize);
    final center = _point(screenSize, x, y);
    final petalPaint = Paint()..color = const Color(0xFFFFF176);
    final middlePaint = Paint()..color = const Color(0xFFFF8F00);
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      canvas.drawCircle(
        center.translate(math.cos(a) * 3 * sc, math.sin(a) * 3 * sc),
        2 * sc,
        petalPaint,
      );
    }
    canvas.drawCircle(center, 1.5 * sc, middlePaint);
  }

  void _drawTree(
    Canvas canvas,
    Size screenSize,
    double cx,
    double bot,
    double r,
    bool dark,
  ) {
    final center = _point(screenSize, cx, bot);
    final rr = _radius(screenSize, r);
    final th = rr * 0.8;
    final tw = rr * 0.13;
    final ty = center.dy - th;
    final trunkColor = dark ? const Color(0xFF2E1A00) : const Color(0xFF3D2200);
    final colors = dark
        ? const [
            Color(0xFF1C3D22),
            Color(0xFF235A2A),
            Color(0xFF2C7035),
            Color(0xFF348040),
          ]
        : const [
            Color(0xFF245228),
            Color(0xFF2E6B34),
            Color(0xFF3A8040),
            Color(0xFF4A9450),
          ];

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(4 * _sx(screenSize), 0),
        width: rr * 1.1,
        height: rr * 0.34,
      ),
      Paint()..color = const Color(0x2E000000),
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - tw / 2, ty, tw, th),
      Paint()..color = trunkColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 5 * _sx(screenSize), ty),
        width: rr * 1.36,
        height: rr * 0.4,
      ),
      Paint()..color = const Color(0x23000000),
    );

    for (final circle in [
      (-0.28, 0.15, 0.65, colors[0]),
      (0.22, 0.12, 0.60, colors[0]),
      (0.00, 0.00, 1.00, colors[1]),
      (-0.22, -0.30, 0.58, colors[2]),
      (0.05, -0.52, 0.36, colors[3]),
    ]) {
      canvas.drawCircle(
        Offset(center.dx + circle.$1 * rr, ty + circle.$2 * rr),
        circle.$3 * rr,
        Paint()..color = circle.$4,
      );
    }
    if (gameRef.season?.season == Season.winter) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + 0.05 * rr, ty - 0.52 * rr),
          width: rr * 0.36 * 1.4,
          height: rr * 0.36 * 0.3,
        ),
        Paint()..color = const Color(0xE6F0F8FF),
      );
    }
  }

  void _drawSeasonalExtras(
    Canvas canvas,
    Size screenSize,
    SeasonContext context,
  ) {
    final sc = _scale(screenSize);
    final daySeed = _dayOfYear(DateTime.now());
    final t = (DateTime.now().millisecondsSinceEpoch % 3000) / 3000.0;

    switch (context.season) {
      case Season.spring:
        _drawSpringExtras(canvas, screenSize, sc, daySeed, t);
      case Season.autumn:
        _drawAutumnExtras(canvas, screenSize, sc, daySeed, t);
      case Season.winter:
        _drawWinterExtras(canvas, screenSize, sc, daySeed, t);
      case Season.summer:
        break;
    }

    if (context.isEvening || context.isNight) {
      canvas.drawRect(
        Offset.zero & screenSize,
        Paint()..color = const Color(0x1F001428),
      );
      final random = math.Random(daySeed + 55);
      for (var i = 0; i < 8; i++) {
        final p = Offset(
          screenSize.width * (0.15 + random.nextDouble() * 0.7),
          screenSize.height * (0.18 + random.nextDouble() * 0.55),
        );
        canvas.drawCircle(
          p.translate(math.sin(t * math.pi * 2 + i) * 3 * sc, 0),
          2 * sc,
          Paint()..color = const Color(0xB3FFFF64),
        );
      }
    }

    switch (context.specialDay) {
      case SpecialDay.christmas:
        _drawChristmasExtras(canvas, screenSize, sc);
      case SpecialDay.halloween:
        _drawHalloweenExtras(canvas, screenSize, sc);
      case SpecialDay.birthday:
        _drawBirthdayExtras(canvas, screenSize, sc, daySeed);
      case SpecialDay.newYear:
        _drawConfetti(canvas, screenSize, sc, daySeed + 99, const Color(0xFFFFD700));
      case null:
        break;
    }
  }

  void _drawSpringExtras(Canvas canvas, Size size, double sc, int seed, double t) {
    final random = math.Random(seed);
    final petalPaint = Paint()..color = const Color(0xD9FFB6C1);
    for (var i = 0; i < 8; i++) {
      final p = Offset(
        size.width * random.nextDouble(),
        size.height * (0.10 + random.nextDouble() * 0.45),
      ).translate(math.sin(t * math.pi * 2 + i) * 5 * sc, 0);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 4 * sc, height: 7 * sc),
        petalPaint,
      );
      canvas.restore();
    }
    for (var i = 0; i < 2; i++) {
      final p = _point(size, 122 + i * 132, 270 + i * 60);
      final wing = Paint()
        ..color = i == 0 ? const Color(0xFFFF8F00) : const Color(0xFFCE93D8);
      final flap = 1 + math.sin(t * math.pi * 8 + i) * 0.25;
      canvas.drawOval(
        Rect.fromCenter(center: p.translate(-4 * sc, 0), width: 7 * sc, height: 10 * sc * flap),
        wing,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p.translate(4 * sc, 0), width: 7 * sc, height: 10 * sc * flap),
        wing,
      );
    }
  }

  void _drawAutumnExtras(Canvas canvas, Size size, double sc, int seed, double t) {
    final random = math.Random(seed + 11);
    final colors = const [Color(0xFFD84315), Color(0xFFFF8F00), Color(0xFF8D6E63)];
    for (var i = 0; i < 12; i++) {
      final p = Offset(
        size.width * random.nextDouble(),
        size.height * (0.10 + random.nextDouble() * 0.70),
      ).translate(0, math.sin(t * math.pi * 2 + i) * 3 * sc);
      _drawLeaf(canvas, p, 5 * sc, colors[i % colors.length]);
    }
    for (final p in [_point(size, 44, 398), _point(size, 355, 262), _point(size, 325, 140)]) {
      canvas.drawOval(
        Rect.fromCenter(center: p.translate(0, 18 * sc), width: 34 * sc, height: 10 * sc),
        Paint()..color = colors[random.nextInt(colors.length)].withOpacity(0.6),
      );
    }
  }

  void _drawWinterExtras(Canvas canvas, Size size, double sc, int seed, double t) {
    final random = math.Random(seed + 22);
    final paint = Paint()
      ..color = const Color(0xB3FFFFFF)
      ..strokeWidth = 1.2 * sc
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final p = Offset(
        size.width * random.nextDouble(),
        size.height * (0.06 + random.nextDouble() * 0.72),
      ).translate(0, math.sin(t * math.pi * 2 + i) * 4 * sc);
      final r = (3 + random.nextDouble() * 2) * sc;
      for (var a = 0; a < 3; a++) {
        final angle = a * math.pi / 3;
        canvas.drawLine(
          p.translate(math.cos(angle) * r, math.sin(angle) * r),
          p.translate(-math.cos(angle) * r, -math.sin(angle) * r),
          paint,
        );
      }
    }
    final icePaint = Paint()..color = const Color(0xCCB8E6FF);
    for (final x in [112.0, 168.0, 238.0, 286.0]) {
      final top = _point(size, x, 450);
      canvas.drawPath(
        Path()
          ..moveTo(top.dx - 3 * sc, top.dy)
          ..lineTo(top.dx + 3 * sc, top.dy)
          ..lineTo(top.dx, top.dy + 18 * sc)
          ..close(),
        icePaint,
      );
    }
  }

  void _drawChristmasExtras(Canvas canvas, Size size, double sc) {
    final lights = const [Color(0xFFFF0000), Color(0xFF00CC00), Color(0xFFFFD700)];
    final start = _point(size, 322, 92);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        start.translate((i - 2.5) * 11 * sc, math.sin(i * 0.8) * 7 * sc),
        3 * sc,
        Paint()..color = lights[i % lights.length],
      );
    }
  }

  void _drawHalloweenExtras(Canvas canvas, Size size, double sc) {
    for (final p in [_point(size, 112, 586), _point(size, 152, 575)]) {
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 20 * sc, height: 16 * sc),
        Paint()..color = const Color(0xFFFF6F00),
      );
      canvas.drawCircle(p.translate(-4 * sc, -2 * sc), 1.5 * sc, Paint()..color = const Color(0xFF3E2108));
      canvas.drawCircle(p.translate(4 * sc, -2 * sc), 1.5 * sc, Paint()..color = const Color(0xFF3E2108));
      canvas.drawLine(
        p.translate(-5 * sc, 4 * sc),
        p.translate(5 * sc, 4 * sc),
        Paint()
          ..color = const Color(0xFF3E2108)
          ..strokeWidth = sc,
      );
    }
  }

  void _drawBirthdayExtras(Canvas canvas, Size size, double sc, int seed) {
    _drawConfetti(canvas, size, sc, seed + 77, const Color(0xFFFFD700));
    _drawTextBubble(
      canvas,
      'Alles Gute zum Geburtstag!',
      _point(size, 214, 88),
      150 * sc,
      10 * sc,
    );
  }

  void _drawConfetti(Canvas canvas, Size size, double sc, int seed, Color fallback) {
    final random = math.Random(seed);
    final colors = [fallback, const Color(0xFFFF8F00), const Color(0xFF29B6F6), const Color(0xFFCE93D8)];
    for (var i = 0; i < 18; i++) {
      final p = Offset(size.width * random.nextDouble(), size.height * random.nextDouble() * 0.7);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 3 * sc, height: 6 * sc),
        Paint()..color = colors[i % colors.length],
      );
      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, Offset p, double size, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - size)
        ..quadraticBezierTo(p.dx + size, p.dy, p.dx, p.dy + size)
        ..quadraticBezierTo(p.dx - size, p.dy, p.dx, p.dy - size),
      Paint()..color = color,
    );
  }

  void _drawTextBubble(Canvas canvas, String text, Offset p, double width, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: const Color(0xFFFFD700), fontSize: fontSize, fontWeight: FontWeight.w800),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final rect = Rect.fromLTWH(p.dx - width / 2, p.dy, width, painter.height + 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8 * fontSize / 10)),
      Paint()..color = const Color(0xCC3E2108),
    );
    painter.paint(canvas, Offset(rect.left, rect.top + 5));
  }

  int _dayOfYear(DateTime date) => date.difference(DateTime(date.year)).inDays + 1;

  static Vector2 nodePositionToVector(Size screenSize, int index) {
    final point = _fractional(screenSize, nodePositions[index]);
    return Vector2(point.dx, point.dy);
  }

  static Vector2 edgePointToVector(Size screenSize, int edgeIndex, double t) {
    final edge = edges[edgeIndex];
    final p0 = _fractional(screenSize, nodePositions[edge.$1]);
    final cp = _fractional(screenSize, controlPoints[edgeIndex]);
    final p1 = _fractional(screenSize, nodePositions[edge.$2]);
    final mt = 1 - t;
    final point = Offset(
      mt * mt * p0.dx + 2 * mt * t * cp.dx + t * t * p1.dx,
      mt * mt * p0.dy + 2 * mt * t * cp.dy + t * t * p1.dy,
    );
    return Vector2(point.dx, point.dy);
  }

  static double uniformScale(Vector2 screenSize) {
    return math.min(
      screenSize.x / referenceSize.width,
      screenSize.y / referenceSize.height,
    );
  }

  static Offset _fractional(Size screenSize, Offset point) {
    return Offset(point.dx * screenSize.width, point.dy * screenSize.height);
  }

  static Offset _point(Size screenSize, double x, double y) {
    return Offset(x * screenSize.width / 400, y * screenSize.height / 660);
  }

  static Rect _oval(
    Size screenSize,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final center = _point(screenSize, cx, cy);
    return Rect.fromCenter(
      center: center,
      width: rx * 2 * screenSize.width / 400,
      height: ry * 2 * screenSize.height / 660,
    );
  }

  static double _radius(Size screenSize, double r) => r * _scale(screenSize);

  static double _scale(Size screenSize) {
    return math.min(screenSize.width / 400, screenSize.height / 660);
  }

  static double _sx(Size screenSize) => screenSize.width / 400;
}
