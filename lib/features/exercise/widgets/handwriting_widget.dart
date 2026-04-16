import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task_model.dart';
import '../../../core/services/providers.dart';

/// Handschrift-Widget für [TaskType.handwriting] — Buchstaben nachspuren.
///
/// Nutzt den [TFLiteService] zur Erkennung der gezeichneten Buchstaben.
/// Falls der Service nicht bereit ist, erfolgt ein Fallback auf die
/// Coverage-Messung (Flächenabdeckung).
class HandwritingWidget extends ConsumerStatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const HandwritingWidget({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  ConsumerState<HandwritingWidget> createState() => _HandwritingWidgetState();
}

class _HandwritingWidgetState extends ConsumerState<HandwritingWidget> {
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

  void _onPanEnd(DragEndDetails details, Size size) async {
    final stroke = List<Offset>.from(_currentStroke);
    setState(() {
      _strokes.add(stroke);
      _currentStroke = [];
    });

    final tflite = ref.read(tfliteServiceProvider);
    
    // Wir nutzen das neue Preprocessing zur Analyse
    final tensor = tflite.preprocess(_strokes, size);
    
    // 1. TFLite-Erkennung (falls Modell geladen)
    if (tflite.isReady) {
      // (Bestehende Logik zur Modell-Inferenz)
      final normalizedPoints = _strokes
          .expand((s) => s)
          .map((p) => [p.dx / size.width, p.dy / size.height])
          .toList();

      final result = await tflite.recognize(normalizedPoints);
      if (result != null && result.toLowerCase() == _letter.toLowerCase()) {
        _setTraced();
        return;
      }
    }

    // 2. Verbessertes Heuristik-Matching (Target Grids)
    if (_checkTargetMatching(tensor)) {
      _setTraced();
      return;
    }

    // 3. Fallback: Allgemeine Coverage-Messung
    final coverage = _computeCoverage(size);
    if (!_traced && coverage >= _coverageThreshold) {
      _setTraced();
    }
  }

  void _setTraced() {
    if (_traced) return;
    setState(() => _traced = true);
    widget.onChanged('traced');
  }

  /// Prüft, ob die Striche zum Muster des erwarteten Buchstabens passen.
  bool _checkTargetMatching(Float32List tensor) {
    final targets = _targetGrids[_letter.toUpperCase()];
    if (targets == null) return false;

    int hits = 0;
    int totalTargets = 0;
    int misses = 0;

    // 1. Treffer prüfen (Hits)
    for (int ty = 0; ty < 5; ty++) {
      for (int tx = 0; tx < 5; tx++) {
        final isTarget = targets[ty][tx] == 1;
        if (!isTarget) continue;
        
        totalTargets++;
        
        // Zentriere den Suchbereich (0, 6, 13, 20, 27 für 5 Punkte auf 28 Pixeln)
        final centerX = (tx * 27 / 4).round();
        final centerY = (ty * 27 / 4).round();
        
        bool hit = false;
        // Suche in einer 9x9 Umgebung (Radius 4)
        for (int y = centerY - 4; y <= centerY + 4; y++) {
          for (int x = centerX - 4; x <= centerX + 4; x++) {
            if (x >= 0 && x < 28 && y >= 0 && y < 28 && tensor[y * 28 + x] > 0) {
              hit = true;
              break;
            }
          }
          if (hit) break;
        }
        if (hit) hits++;
      }
    }

    // 2. Fehler prüfen (Misses / Scribble-Schutz)
    // Wir zählen Punkte, die belegt sind, aber weit weg von jedem Zielpunkt liegen.
    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        if (tensor[y * 28 + x] > 0) {
          bool nearTarget = false;
          for (int ty = 0; ty < 5; ty++) {
            for (int tx = 0; tx < 5; tx++) {
              if (targets[ty][tx] == 1) {
                final ctx = (tx * 27 / 4).round();
                final cty = (ty * 27 / 4).round();
                // Wenn Punkt im Radius von 3 um irgendeinen Zielpunkt liegt -> OK
                if ((x - ctx).abs() <= 3 && (y - cty).abs() <= 3) {
                  nearTarget = true;
                  break;
                }
              }
            }
            if (nearTarget) break;
          }
          if (!nearTarget) misses++;
        }
      }
    }

    final hitRate = hits / totalTargets;
    // Mindestens 60% Treffer UND weniger als 40 "verbotene" Pixel (ca. 5% der Fläche)
    return hitRate >= 0.60 && misses < 40;
  }

  /// Ziel-Gitter (5x5) für die häufigsten Buchstaben (A, E, I, O, U).
  /// 1 = Punkt muss durchfahren werden, 0 = egal.
  static const Map<String, List<List<int>>> _targetGrids = {
    'A': [
      [0, 0, 1, 0, 0],
      [0, 1, 0, 1, 0],
      [0, 1, 1, 1, 0],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
    ],
    'E': [
      [1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0],
      [1, 1, 1, 1, 0],
      [1, 0, 0, 0, 0],
      [1, 1, 1, 1, 1],
    ],
    'I': [
      [0, 1, 1, 1, 0],
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
    ],
    'O': [
      [0, 1, 1, 1, 0],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [0, 1, 1, 1, 0],
    ],
    'U': [
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [0, 1, 1, 1, 0],
    ],
  };

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
