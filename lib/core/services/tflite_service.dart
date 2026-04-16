import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';

/// Service für On-Device Machine Learning via TFLite.
///
/// Wird primär für die Handschrifterkennung im [HandwritingWidget] genutzt.
class TFLiteService {
  // Interpreter? _interpreter;
  bool _isModelLoaded = false;

  static const String _modelPath = 'assets/ml/handwriting.tflite';

  bool get isReady => _isModelLoaded;

  /// Lädt das TFLite-Modell aus den Assets.
  Future<void> loadModel() async {
    try {
      // _interpreter = await Interpreter.fromAsset(_modelPath);
      // _isModelLoaded = true;
    } catch (e) {
      // Falls das Modell fehlt (noch nicht vom Nutzer bereitgestellt),
      // loggen wir den Fehler, stürzen aber nicht ab.
      print('TFLiteService: Modell konnte nicht geladen werden: $e');
      _isModelLoaded = false;
    }
  }

  /// Vorverarbeitung: Wandelt Striche (Strokes) in einen 28x28 Tensor um.
  ///
  /// [strokes] ist eine Liste von Strichen, wobei jeder Strich eine Liste von Offsets ist.
  /// [size] ist die Größe der Zeichenfläche.
  Float32List preprocess(List<List<Offset>> strokes, Size size) {
    final tensor = Float32List(28 * 28);
    if (strokes.isEmpty || size.width == 0 || size.height == 0) return tensor;

    // Wir rastern die Striche auf ein 28x28 Gitter.
    // Jeder Punkt eines Strichs setzt den entsprechenden Pixel auf 1.0.
    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length; i++) {
        final p = stroke[i];
        final x = ((p.dx / size.width) * 27).clamp(0, 27).toInt();
        final y = ((p.dy / size.height) * 27).clamp(0, 27).toInt();
        tensor[y * 28 + x] = 1.0;

        // Interpolation zwischen Punkten (Linienzug füllen)
        if (i > 0) {
          final prev = stroke[i - 1];
          _drawLine(tensor, prev, p, size);
        }
      }
    }

    return tensor;
  }

  /// Zeichnet eine Linie in den 28x28 Tensor (Bresenham-ähnlich).
  void _drawLine(Float32List tensor, Offset p1, Offset p2, Size size) {
    final x1 = (p1.dx / size.width) * 27;
    final y1 = (p1.dy / size.height) * 27;
    final x2 = (p2.dx / size.width) * 27;
    final y2 = (p2.dy / size.height) * 27;

    final dist = (x2 - x1).abs() + (y2 - y1).abs();
    if (dist < 1) return;

    final steps = dist.ceil();
    for (int s = 0; s <= steps; s++) {
      final t = s / steps;
      final x = (x1 + (x2 - x1) * t).clamp(0, 27).toInt();
      final y = (y1 + (y2 - y1) * t).clamp(0, 27).toInt();
      tensor[y * 28 + x] = 1.0;
    }
  }

  /// Führt eine Inferenz für gezeichnete Koordinaten durch.
  ///
  /// Erwartet eine Liste von normalisierten Koordinaten (x, y).
  /// Gibt den erkannten Buchstaben/Zahl als String zurück.
  Future<String?> recognize(List<List<double>> input) async {
    if (!_isModelLoaded /* || _interpreter == null */) {
      return null;
    }
    return null; // Platzhalter
  }

  void dispose() {
    // _interpreter?.close();
  }
}
