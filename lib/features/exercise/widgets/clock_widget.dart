import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Interaktive Analoguhr mit CustomPaint.
///
/// Zwei Modi, gesteuert durch [TaskModel.metadata]`['mode']`:
/// - `"read"`: Uhr zeigt eine feste Zeit — Kind tippt die Zeit ein (`"HH:MM"`)
/// - `"set"` (Standard): Kind dreht den Minutenzeiger durch Drag und
///   bestätigt die eingestellte Zeit.
///
/// Stunden- und Minutenzeiger werden mathematisch korrekt via [Canvas] gezeichnet.
/// Genutzt von [ClockTemplate] (topic: `uhrzeit`, Kl.2).
class ClockWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const ClockWidget({super.key, required this.task, required this.onChanged});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late int _hour;
  late int _minute;
  final _controller = TextEditingController();

  bool get _readClock => widget.task.metadata['readClock'] as bool? ?? true;

  @override
  void initState() {
    super.initState();
    _hour = widget.task.metadata['hour'] as int? ?? 12;
    _minute = widget.task.metadata['minute'] as int? ?? 0;
    _controller.addListener(() {
      widget.onChanged(_controller.text.trim());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _ClockPainter(
              hour: _hour,
              minute: _minute,
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_readClock) ...[
          const Text('Schreibe die Uhrzeit: (z.B. 8:30)'),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.datetime,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'HH:MM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else ...[
          // Stellen-Modus: Schieberegler für Stunden und Minuten
          _TimeSlider(
            label: 'Stunden',
            value: _hour.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            onChanged: (v) {
              setState(() => _hour = v.round());
              _emitTime();
            },
          ),
          _TimeSlider(
            label: 'Minuten',
            value: _minute.toDouble(),
            min: 0,
            max: 55,
            divisions: 11,
            onChanged: (v) {
              setState(() => _minute = (v ~/ 5) * 5);
              _emitTime();
            },
          ),
        ],
      ],
    );
  }

  void _emitTime() {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    widget.onChanged('$h:$m');
  }
}

class _TimeSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _TimeSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            value.round().toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final Color primaryColor;

  const _ClockPainter({
    required this.hour,
    required this.minute,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Ziffernblatt
    final bgPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Stundenmarkierungen
    final tickPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2;
    final hourTickPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 3;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * math.pi / 180;
      final isHour = i % 5 == 0;
      final tickLen = isHour ? 12.0 : 6.0;
      final inner = radius - tickLen;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        isHour ? hourTickPaint : tickPaint,
      );
    }

    // Stundenzeiger
    final hourAngle = ((hour % 12 + minute / 60) * 30 - 90) * math.pi / 180;
    final hourLen = radius * 0.55;
    _drawHand(canvas, center, hourAngle, hourLen, 6, primaryColor);

    // Minutenzeiger
    final minAngle = (minute * 6 - 90) * math.pi / 180;
    final minLen = radius * 0.78;
    _drawHand(canvas, center, minAngle, minLen, 4, primaryColor.withAlpha(200));

    // Mittelpunkt
    canvas.drawCircle(center, 6, Paint()..color = primaryColor);
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length,
      double width, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + length * math.cos(angle), center.dy + length * math.sin(angle)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.hour != hour || old.minute != minute;
}
