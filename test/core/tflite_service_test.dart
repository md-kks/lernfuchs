import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/services/tflite_service.dart';

void main() {
  group('TFLiteService Preprocessing', () {
    late TFLiteService service;

    setUp(() {
      service = TFLiteService();
    });

    test('preprocess converts strokes to 28x28 grid', () {
      final strokes = [
        [const Offset(10, 10), const Offset(10, 20)], // Vertical line
      ];
      final size = const Size(100, 100);
      
      final tensor = service.preprocess(strokes, size);
      
      expect(tensor.length, 784); // 28 * 28
      expect(tensor.any((v) => v > 0), isTrue);
    });

    test('preprocess handles empty strokes', () {
      final tensor = service.preprocess([], const Size(100, 100));
      expect(tensor.every((v) => v == 0), isTrue);
    });
  });
}
