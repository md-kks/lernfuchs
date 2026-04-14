import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/fino_evolution_service.dart';

class BaumhausPainter extends CustomPainter {
  final int baumhausStage;
  final List<String> items;
  final FinoStyle finoStyle;
  final double breathT;
  final double revealT;

  const BaumhausPainter({
    required this.baumhausStage,
    required this.items,
    required this.finoStyle,
    required this.breathT,
    this.revealT = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sc = math.min(size.width / 360, size.height / 720);
    _drawBase(canvas, size, sc);
    _drawTree(canvas, size, sc);
    _drawStage(canvas, size, sc);
    _drawItems(canvas, size, sc);
    _drawFinoAtBaumhaus(canvas, size, sc);
  }

  void _drawBase(Canvas canvas, Size size, double sc) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6BA3BE), Color(0xFF9DC49F)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.80, size.width, size.height * 0.20),
      Paint()..color = const Color(0xFF3D6B2E),
    );
    final grass = Paint()
      ..color = const Color(0xFF5A8A40)
      ..strokeWidth = 1.2 * sc
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 34; i++) {
      final x = (10 + i * 11) * sc;
      final y = size.height * 0.83 + (i % 5) * 6 * sc;
      canvas.drawLine(Offset(x, y), Offset(x + 3 * sc, y - 9 * sc), grass);
    }
    if (baumhausStage >= 4) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x0FFF9632));
    }
  }

  void _drawTree(Canvas canvas, Size size, double sc) {
    final trunk = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.55),
      width: 104 * sc,
      height: size.height * 0.60,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(trunk, Radius.circular(24 * sc)),
      Paint()..color = const Color(0xFF3E2108),
    );
    final rootPaint = Paint()
      ..color = const Color(0xFF2A1600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * sc
      ..strokeCap = StrokeCap.round;
    for (final sign in const [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final start = Offset(size.width / 2 + sign * 22 * sc, size.height * 0.80);
        canvas.drawPath(
          Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(
              start.dx + sign * (30 + i * 18) * sc,
              start.dy + (6 + i * 7) * sc,
              start.dx + sign * (72 + i * 28) * sc,
              start.dy + (20 + i * 8) * sc,
            ),
          rootPaint,
        );
      }
    }
    final canopyPaint = Paint()..color = const Color(0xFF245228);
    for (final c in [
      Offset(size.width * 0.34, size.height * 0.20),
      Offset(size.width * 0.54, size.height * 0.16),
      Offset(size.width * 0.68, size.height * 0.24),
      Offset(size.width * 0.42, size.height * 0.30),
      Offset(size.width * 0.60, size.height * 0.34),
    ]) {
      canvas.drawCircle(c, 58 * sc, canopyPaint);
      canvas.drawCircle(c.translate(8 * sc, -8 * sc), 42 * sc, Paint()..color = const Color(0xFF2E6B34));
    }
  }

  void _drawStage(Canvas canvas, Size size, double sc) {
    final center = Offset(size.width / 2, size.height * 0.48);
    final opening = Rect.fromCenter(
      center: center,
      width: 112 * sc,
      height: 92 * sc,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 92 * sc, height: 74 * sc),
      Paint()..color = const Color(0xFF1A0A00),
    );

    if (baumhausStage == 0) {
      _drawText(canvas, '?', center.translate(-8 * sc, -72 * sc), 28 * sc, const Color(0xFFFF8F00), 28 * sc, FontWeight.w900);
      return;
    }

    canvas.drawRect(
      Rect.fromLTWH(opening.left + 14 * sc, opening.center.dy + 20 * sc, opening.width - 28 * sc, 10 * sc),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawRect(
      Rect.fromLTWH(opening.left + 18 * sc, opening.top + 22 * sc, opening.width - 36 * sc, 46 * sc),
      Paint()..color = const Color(0xFF4A3020),
    );
    canvas.drawRect(
      Rect.fromLTWH(opening.right - 36 * sc, opening.top + 32 * sc, 16 * sc, 18 * sc),
      Paint()..color = const Color(0xFF1A0A00),
    );
    _drawCampfire(canvas, center.translate(-24 * sc, 30 * sc), sc);

    if (baumhausStage >= 2) {
      _drawDoorAndRoof(canvas, center, sc);
      _drawBooks(canvas, opening.topRight.translate(-42 * sc, 42 * sc), sc);
      _drawBrumm(canvas, center.translate(26 * sc, 48 * sc), sc * 0.58);
    }
    if (baumhausStage >= 3) {
      _drawUpperRoom(canvas, size, sc);
    }
    if (baumhausStage >= 4) {
      _drawCrystalTower(canvas, size, sc);
      _drawGreatBook(canvas, center.translate(0, -8 * sc), sc);
    }
  }

  void _drawDoorAndRoof(Canvas canvas, Offset center, double sc) {
    final roofPaints = [const Color(0xFF5D4037), const Color(0xFF4A3020)];
    for (var i = 0; i < 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center.translate((i - 2) * 21 * sc, -58 * sc), width: 20 * sc, height: 13 * sc),
          Radius.circular(3 * sc),
        ),
        Paint()..color = roofPaints[i % 2],
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 24 * sc, center.dy + 34 * sc)
        ..quadraticBezierTo(center.dx, center.dy + 5 * sc, center.dx + 24 * sc, center.dy + 34 * sc)
        ..lineTo(center.dx + 24 * sc, center.dy + 64 * sc)
        ..lineTo(center.dx - 24 * sc, center.dy + 64 * sc)
        ..close(),
      Paint()..color = const Color(0xFF5D4037),
    );
  }

  void _drawUpperRoom(Canvas canvas, Size size, double sc) {
    final room = Rect.fromCenter(center: Offset(size.width / 2 + 38 * sc, size.height * 0.29), width: 92 * sc, height: 60 * sc);
    canvas.drawRRect(
      RRect.fromRectAndRadius(room, Radius.circular(12 * sc)),
      Paint()..color = const Color(0xFF4A3020),
    );
    canvas.drawRect(room.deflate(14 * sc), Paint()..color = const Color(0xFF1A0A00));
    _drawOva(canvas, room.center.translate(0, -2 * sc), sc * 0.65);
    canvas.drawRect(
      Rect.fromCenter(center: room.center.translate(18 * sc, -2 * sc), width: 28 * sc, height: 6 * sc),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawCircle(room.center.translate(33 * sc, -2 * sc), 5 * sc, Paint()..color = const Color(0xFF29B6F6));
    final ladderX = size.width / 2 - 54 * sc;
    final ladderTop = size.height * 0.40;
    final ladderBottom = size.height * 0.72;
    final ladderPaint = Paint()
      ..color = const Color(0xFFC8AA82)
      ..strokeWidth = 2 * sc;
    canvas.drawLine(Offset(ladderX, ladderTop), Offset(ladderX - 18 * sc, ladderBottom), ladderPaint);
    canvas.drawLine(Offset(ladderX + 18 * sc, ladderTop), Offset(ladderX, ladderBottom), ladderPaint);
    for (var i = 0; i < 7; i++) {
      final y = ladderTop + i * 26 * sc;
      canvas.drawLine(Offset(ladderX - 2 * sc, y), Offset(ladderX + 18 * sc, y), ladderPaint);
    }
    _drawBrumm(canvas, Offset(ladderX + 2 * sc, ladderTop + 105 * sc), sc * 0.46);
  }

  void _drawCrystalTower(Canvas canvas, Size size, double sc) {
    final top = Offset(size.width / 2 + 26 * sc, size.height * 0.10);
    canvas.drawCircle(top, 60 * sc * revealT, Paint()..color = const Color(0x2629B6F6));
    for (var i = 0; i < 3; i++) {
      final p = top.translate(0, i * 16 * sc);
      _drawDiamond(canvas, p, 13 * sc, const Color(0xFF29B6F6));
    }
  }

  void _drawItems(Canvas canvas, Size size, double sc) {
    final center = Offset(size.width / 2, size.height * 0.48);
    if (items.contains('baumhaus_bank')) {
      canvas.drawRect(Rect.fromCenter(center: center.translate(-18 * sc, 68 * sc), width: 42 * sc, height: 8 * sc), Paint()..color = const Color(0xFF8D6E63));
      canvas.drawRect(Rect.fromLTWH(center.dx - 35 * sc, center.dy + 73 * sc, 5 * sc, 18 * sc), Paint()..color = const Color(0xFF5D4037));
      canvas.drawRect(Rect.fromLTWH(center.dx + 9 * sc, center.dy + 73 * sc, 5 * sc, 18 * sc), Paint()..color = const Color(0xFF5D4037));
    }
    if (items.contains('baumhaus_laterne')) {
      final p = center.translate(0, -70 * sc);
      canvas.drawLine(
        p,
        p.translate(0, 12 * sc),
        Paint()
          ..color = const Color(0xFF3E2108)
          ..strokeWidth = sc,
      );
      canvas.drawCircle(p.translate(0, 20 * sc), 9 * sc, Paint()..color = const Color(0x66FFD700));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, 20 * sc), width: 12 * sc, height: 16 * sc), Radius.circular(4 * sc)),
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
    if (items.contains('baumhaus_kristall_blau')) {
      _drawDiamond(canvas, center.translate(34 * sc, 24 * sc), 12 * sc, const Color(0xFF29B6F6));
    }
  }

  void _drawFinoAtBaumhaus(Canvas canvas, Size size, double sc) {
    final y = baumhausStage == 0 ? size.height * 0.78 : size.height * 0.57;
    final x = baumhausStage >= 1 ? size.width / 2 - 14 * sc : size.width / 2;
    final tailGlow = items.contains('baumhaus_goldener_schwanz');
    final effective = tailGlow ? FinoStyle.forStage(4) : finoStyle;
    _drawFino(canvas, Offset(x, y + math.sin(breathT * math.pi * 2) * 3 * sc), sc * 1.1, effective);
  }

  void _drawFino(Canvas canvas, Offset p, double sc, FinoStyle style) {
    final body = sc * style.bodyScaleModifier;
    canvas.save();
    canvas.translate(p.dx, p.dy);
    _drawRotatedOval(canvas, Offset(16 * sc, 10 * sc), 15 * sc, 8 * sc, 0.3, const Color(0xFFD84315));
    _drawRotatedOval(canvas, Offset(25 * sc, 14 * sc), 6 * sc, 4 * sc, 0.3, style.hasGoldenTailTip ? const Color(0xFFFFD700) : const Color(0xFFFFFDE7));
    if (style.hasGoldenTailTip) canvas.drawCircle(Offset(25 * sc, 14 * sc), 5 * sc, Paint()..color = const Color(0x66FFD700));
    if (style.hasBook) _drawGreatBook(canvas, Offset(-8 * sc, 0), sc * 0.55);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 5 * body), width: 26 * body, height: 20 * body), Paint()..color = const Color(0xFFE64A19));
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 7 * body), width: 14 * body, height: 14 * body), Paint()..color = const Color(0xFFFFFDE7));
    canvas.drawCircle(Offset(0, -8 * body), 12 * body, Paint()..color = const Color(0xFFEF6C00));
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -6 * body), width: 14 * body, height: 16 * body), Paint()..color = const Color(0xFFFFFDE7));
    canvas.save();
    canvas.rotate(style.earAngleModifier);
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawPath(Path()..moveTo(sign * 10 * body, -16 * body)..lineTo(sign * 17 * body, -28 * body)..lineTo(sign * 3 * body, -21 * body)..close(), Paint()..color = const Color(0xFFEF6C00));
      canvas.drawPath(Path()..moveTo(sign * 10 * body, -18 * body)..lineTo(sign * 14 * body, -25 * body)..lineTo(sign * 5 * body, -21 * body)..close(), Paint()..color = const Color(0xFFFF8F00));
    }
    canvas.restore();
    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    for (final eye in [Offset(-4 * body, -9 * body), Offset(4 * body, -9 * body)]) {
      canvas.drawCircle(eye, 2.5 * body, eyePaint);
      if (style.hasEyeGlow) canvas.drawCircle(eye, 3.5 * body, Paint()..color = style.eyeGlowColor);
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -4 * body), width: 5 * body, height: 4 * body), eyePaint);
    if (style.hasNecklace) _drawNecklace(canvas, sc, style);
    canvas.restore();
  }

  void _drawNecklace(Canvas canvas, double sc, FinoStyle style) {
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, 3 * sc), width: 22 * sc, height: 16 * sc),
      0.05 * math.pi,
      0.9 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * sc,
    );
    for (var i = 0; i < style.necklaceCount.clamp(1, 3); i++) {
      _drawDiamond(canvas, Offset((i - (style.necklaceCount - 1) / 2) * 6 * sc, 10 * sc), 5 * sc, const Color(0xFF29B6F6));
    }
  }

  void _drawCampfire(Canvas canvas, Offset p, double sc) {
    canvas.drawPath(Path()..moveTo(p.dx, p.dy - 14 * sc)..quadraticBezierTo(p.dx + 10 * sc, p.dy, p.dx, p.dy + 10 * sc)..quadraticBezierTo(p.dx - 10 * sc, p.dy, p.dx, p.dy - 14 * sc), Paint()..color = const Color(0xFFFF6F00));
    canvas.drawPath(Path()..moveTo(p.dx, p.dy - 7 * sc)..quadraticBezierTo(p.dx + 5 * sc, p.dy, p.dx, p.dy + 6 * sc)..quadraticBezierTo(p.dx - 5 * sc, p.dy, p.dx, p.dy - 7 * sc), Paint()..color = const Color(0xFFFFC107));
  }

  void _drawBooks(Canvas canvas, Offset p, double sc) {
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(p.dx + i * 5 * sc, p.dy - i * 3 * sc, 5 * sc, 18 * sc), Paint()..color = [const Color(0xFF795548), const Color(0xFF8D6E63), const Color(0xFFFF8F00)][i]);
    }
  }

  void _drawGreatBook(Canvas canvas, Offset p, double sc) {
    canvas.drawCircle(p, 16 * sc, Paint()..color = const Color(0x26FFD700));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 24 * sc, height: 18 * sc), Radius.circular(4 * sc)), Paint()..color = const Color(0xFF3E2108));
    canvas.drawRect(Rect.fromCenter(center: p.translate(8 * sc, 0), width: 3 * sc, height: 18 * sc), Paint()..color = const Color(0xFFFFD700));
  }

  void _drawBrumm(Canvas canvas, Offset p, double sc) {
    canvas.drawOval(Rect.fromCenter(center: p.translate(0, 8 * sc), width: 36 * sc, height: 44 * sc), Paint()..color = const Color(0xFF795548));
    canvas.drawCircle(p.translate(0, -18 * sc), 20 * sc, Paint()..color = const Color(0xFF795548));
    canvas.drawCircle(p.translate(-7 * sc, -21 * sc), 2.4 * sc, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(p.translate(7 * sc, -21 * sc), 2.4 * sc, Paint()..color = const Color(0xFF1A1A1A));
  }

  void _drawOva(Canvas canvas, Offset p, double sc) {
    canvas.drawCircle(p, 14 * sc, Paint()..color = const Color(0xFFFF8F00));
    canvas.drawPath(Path()..moveTo(p.dx - 9 * sc, p.dy - 11 * sc)..lineTo(p.dx - 17 * sc, p.dy - 24 * sc)..lineTo(p.dx - 2 * sc, p.dy - 16 * sc)..close(), Paint()..color = const Color(0xFF5D4037));
    canvas.drawPath(Path()..moveTo(p.dx + 9 * sc, p.dy - 11 * sc)..lineTo(p.dx + 17 * sc, p.dy - 24 * sc)..lineTo(p.dx + 2 * sc, p.dy - 16 * sc)..close(), Paint()..color = const Color(0xFF5D4037));
  }

  void _drawDiamond(Canvas canvas, Offset p, double height, Color color) {
    canvas.drawCircle(p, height * 0.65, Paint()..color = color.withOpacity(0.24));
    canvas.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - height / 2)
        ..lineTo(p.dx + height * 0.35, p.dy)
        ..lineTo(p.dx, p.dy + height / 2)
        ..lineTo(p.dx - height * 0.35, p.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  void _drawRotatedOval(Canvas canvas, Offset center, double rx, double ry, double rotation, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), Paint()..color = color);
    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, Offset offset, double width, Color color, double fontSize, FontWeight weight) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant BaumhausPainter oldDelegate) {
    return oldDelegate.baumhausStage != baumhausStage ||
        oldDelegate.items != items ||
        oldDelegate.finoStyle.stage != finoStyle.stage ||
        oldDelegate.breathT != breathT ||
        oldDelegate.revealT != revealT;
  }
}
