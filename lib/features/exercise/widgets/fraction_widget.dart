import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Bruch-Widget mit CustomPaint-Tortendiagramm — Kl.4.
///
/// Drei Aufgaben-Subtypes, gesteuert über [TaskModel.metadata]`['subType']`:
/// - `"read"`: Torte ist vorgegeben → Kind liest Bruch ab (Multiple-Choice)
/// - `"identify"`: Bruch ist vorgegeben → Kind wählt passendes Bild
/// - `"add"`: Zwei gleichnamige Brüche werden addiert (Freitext-Eingabe)
///
/// Genutzt von [FractionTemplate] (topic: `brueche`, Kl.4).
class FractionWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const FractionWidget({super.key, required this.task, required this.onChanged});

  @override
  State<FractionWidget> createState() => _FractionWidgetState();
}

class _FractionWidgetState extends State<FractionWidget> {
  dynamic _selected;
  final _controller = TextEditingController();

  int get _numerator => widget.task.metadata['numerator'] as int? ?? 1;
  int get _denominator => widget.task.metadata['denominator'] as int? ?? 2;
  String get _type => widget.task.metadata['type'] as String? ?? 'read';
  List<dynamic> get _choices =>
      (widget.task.metadata['choices'] as List?)?.cast<dynamic>() ?? [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final val = int.tryParse(_controller.text.trim());
      widget.onChanged(val);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tortendiagramm
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _FractionPainter(
              numerator: _numerator,
              denominator: _denominator,
              primaryColor: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_numerator / $_denominator',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        if (_type == 'read') ...[
          // Eingabefeld für Zähler/Nenner
          SizedBox(
            width: 120,
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: '?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary, width: 3),
                ),
              ),
            ),
          ),
        ] else if (_type == 'identify') ...[
          // Multiple Choice für Bruch-Auswahl
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _choices.map((choice) {
              final isSelected = _selected == choice;
              return GestureDetector(
                onTap: () {
                  setState(() => _selected = choice);
                  widget.onChanged(choice);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withAlpha(80),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    choice.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          // Addition: freie Eingabe
          SizedBox(
            width: 120,
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: '?',
                suffixText: '/${_denominator}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FractionPainter extends CustomPainter {
  final int numerator;
  final int denominator;
  final Color primaryColor;

  const _FractionPainter({
    required this.numerator,
    required this.denominator,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi / denominator;

    final filledPaint = Paint()..color = primaryColor;
    final emptyPaint = Paint()
      ..color = primaryColor.withAlpha(40);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < denominator; i++) {
      final paint = i < numerator ? filledPaint : emptyPaint;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + i * sweepAngle,
        sweepAngle,
        true,
        borderPaint,
      );
    }

    // Außenring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_FractionPainter old) =>
      old.numerator != numerator || old.denominator != denominator;
}
