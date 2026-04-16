import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/services/tflite_service.dart';

void main() {
  group('Handwriting Heuristics - Robustness Tests', () {
    final tflite = TFLiteService();
    final size = const Size(280, 280);

    // Helper to simulate strokes and get tensor
    Float32List getTensor(List<List<Offset>> strokes) {
      return tflite.preprocess(strokes, size);
    }

    // Helper to check if a tensor matches a letter (manually using the logic from the widget)
    bool matches(Float32List tensor, String letter) {
      final grid = targetGrids[letter.toUpperCase()];
      if (grid == null) return false;

      int hits = 0;
      int totalTargets = 0;
      int misses = 0;

      for (int ty = 0; ty < 5; ty++) {
        for (int tx = 0; tx < 5; tx++) {
          final isTarget = grid[ty][tx] == 1;
          if (!isTarget) continue;
          totalTargets++;

          final centerX = (tx * 27 / 4).round();
          final centerY = (ty * 27 / 4).round();

          bool hit = false;
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

      for (int y = 0; y < 28; y++) {
        for (int x = 0; x < 28; x++) {
          if (tensor[y * 28 + x] > 0) {
            bool nearTarget = false;
            for (int ty = 0; ty < 5; ty++) {
              for (int tx = 0; tx < 5; tx++) {
                if (grid[ty][tx] == 1) {
                  final ctx = (tx * 27 / 4).round();
                  final cty = (ty * 27 / 4).round();
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
      return hitRate >= 0.6 && misses < 40;
    }

    test('Accepts a correctly drawn "I"', () {
      final strokes = [
        [const Offset(140, 40), const Offset(140, 240)], // Vertical bar
        [const Offset(70, 40), const Offset(210, 40)],   // Top bar
        [const Offset(70, 240), const Offset(210, 240)], // Bottom bar
      ];
      final tensor = getTensor(strokes);
      expect(matches(tensor, 'I'), isTrue);
    });

    test('Rejects a completely wrong shape (large circle) for "I"', () {
      final circle = List.generate(40, (i) {
        final a = i * 2 * 3.14 / 40;
        return Offset(140 + 120 * math.cos(a), 140 + 120 * math.sin(a));
      });
      final tensor = getTensor([circle]);
      expect(matches(tensor, 'I'), isFalse);
    });

    test('SUCCESS: Rejects scribbling / full area coloring for "I"', () {
      final strokes = <List<Offset>>[];
      for (double y = 0; y < 280; y += 5) {
        strokes.add([Offset(0, y), Offset(280, y)]);
      }
      final tensor = getTensor(strokes);
      expect(matches(tensor, 'I'), isFalse);
    });

    test('Accepts slightly shifted "I"', () {
      final strokes = [
        [const Offset(150, 50), const Offset(150, 230)],
        [const Offset(80, 50), const Offset(220, 50)],
        [const Offset(80, 230), const Offset(220, 230)],
      ];
      final tensor = getTensor(strokes);
      expect(matches(tensor, 'I'), isTrue);
    });

    test('Accepts "A" with multiple strokes', () {
      final strokes = [
        [const Offset(140, 40), const Offset(40, 240)],  // Left leg
        [const Offset(140, 40), const Offset(240, 240)], // Right leg
        [const Offset(80, 160), const Offset(200, 160)], // Bridge
      ];
      final tensor = getTensor(strokes);
      expect(matches(tensor, 'A'), isTrue);
    });

    test('Handles empty input gracefully', () {
      final tensor = getTensor([]);
      expect(matches(tensor, 'A'), isFalse);
    });
  });
}

// Mirroring the target grids from the widget for testing
const Map<String, List<List<int>>> targetGrids = {
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
