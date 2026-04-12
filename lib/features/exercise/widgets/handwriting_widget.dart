import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Handschrift-Widget für [TaskType.handwriting] — Buchstaben nachspuren.
///
/// Zeigt den Ziel-Buchstaben groß und stark verblasst im Hintergrund.
/// Das Kind zeichnet mit dem Finger darüber. Sobald genug Fläche gedeckt ist
/// ([_coverageThreshold]), wird `'traced'` via [onChanged] gemeldet und
/// ein visueller Erfolg-Zustand angezeigt.
///
/// ### Technische Details
/// - Zeichen-Layer: [CustomPainter] mit `List<List<Offset>>`-Strichlisten
/// - Coverage-Messung: Raster von 12×12 Testpunkten über die Zeichenfläche;
///   ein Punkt gilt als gedeckt wenn ein Strich ≤ [_coverageRadius]px entfernt ist
/// - Referenz: großer `Text`-Widget mit sehr niedriger Opacity als Stack-Hintergrund
class HandwritingWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const HandwritingWidget({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  State<HandwritingWidget> createState() => _HandwritingWidgetState();
}

class _HandwritingWidgetState extends State<HandwritingWidget> {
  /// Alle abgeschlossenen Striche (je ein List<Offset>)
  final List<List<Offset>> _strokes = [];

  /// Der aktuell in Bearbeitung befindliche Strich
  List<Offset> _currentStroke = [];

  bool _traced = false;

  static const double _coverageThreshold = 0.35;
  static const double _coverageRadius = 22.0;
  static const int _gridSize = 12;

  String get _letter => widget.task.metadata['letter'] as String? ?? 'A';
  String get _word => widget.task.metadata['word'] as String? ?? '';

  /// Berechnet den Anteil der Referenzfläche, der durch Striche gedeckt ist.
  double _computeCoverage(Size size) {
    if (_strokes.isEmpty && _currentStroke.isEmpty) return 0.0;

    final allPoints = [
      for (final stroke in _strokes) ...stroke,
      ..._currentStroke,
    ];

    int covered = 0;
    final total = _gridSize * _gridSize;

    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        final testPoint = Offset(
          (col + 0.5) * size.width / _gridSize,
          (row + 0.5) * size.height / _gridSize,
        );
        final isNear = allPoints.any((p) {
          final dx = p.dx - testPoint.dx;
          final dy = p.dy - testPoint.dy;
          return math.sqrt(dx * dx + dy * dy) <= _coverageRadius;
        });
        if (isNear) covered++;
      }
    }
    return covered / total;
  }

  void _onPanStart(DragStartDetails details, Size size) {
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
    final coverage = _computeCoverage(size);
    if (!_traced && coverage >= _coverageThreshold) {
      setState(() => _traced = true);
      widget.onChanged('traced');
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _traced = false;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Column(
      children: [
        // Erfolgs-Banner
        if (_traced)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade400, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Super! Du hast "$_letter" wie $_word geschrieben!',
                  style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

        // Zeichenfläche
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _traced ? Colors.green.shade400 : color.withAlpha(100),
                width: _traced ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            height: 280,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onPanStart: (d) => _onPanStart(d, size),
                  onPanUpdate: (d) => _onPanUpdate(d, size),
                  onPanEnd: (d) => _onPanEnd(d, size),
                  child: Stack(
                    children: [
                      // Referenz-Buchstabe (stark verblasst)
                      Center(
                        child: Opacity(
                          opacity: 0.12,
                          child: Text(
                            _letter,
                            style: TextStyle(
                              fontSize: 220,
                              fontWeight: FontWeight.w900,
                              color: color,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      // Hilfslinien (wie Schulheft)
                      CustomPaint(
                        size: size,
                        painter: _GuidelinesPainter(),
                      ),
                      // Zeichnungen des Kindes
                      CustomPaint(
                        size: size,
                        painter: _StrokePainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          strokeColor: _traced
                              ? Colors.green.shade600
                              : color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Löschen-Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _strokes.isEmpty ? null : _clear,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Nochmal'),
            ),
            const SizedBox(width: 16),
            Text(
              'Fahre mit dem Finger den Buchstaben nach!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Malt Schulheft-Hilfslinien (3 horizontale Linien).
class _GuidelinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withAlpha(30)
      ..strokeWidth = 1;

    final positions = [0.25, 0.5, 0.75];
    for (final pos in positions) {
      final y = size.height * pos;
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GuidelinesPainter old) => false;
}

/// Malt alle Strich-Pfade des Kindes.
class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;

  const _StrokePainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in [...strokes, currentStroke]) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      strokes != old.strokes || currentStroke != old.currentStroke;
}
