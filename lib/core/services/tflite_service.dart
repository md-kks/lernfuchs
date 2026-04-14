import 'dart:io';
import 'dart:typed_data';
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

  /// Führt eine Inferenz für gezeichnete Koordinaten durch.
  ///
  /// Erwartet eine Liste von normalisierten Koordinaten (x, y).
  /// Gibt den erkannten Buchstaben/Zahl als String zurück.
  Future<String?> recognize(List<List<double>> input) async {
    if (!_isModelLoaded /* || _interpreter == null */) {
      return null;
    }

    // Hier würde die Vorverarbeitung (Preprocessing) stattfinden:
    // 1. Umwandlung der Koordinaten in einen Tensor (z.B. 28x28 Graustufen-Bild).
    // 2. Normalisierung.

    // Beispielhafter Inferenz-Aufruf:
    // var output = List.filled(26, 0.0).reshape([1, 26]);
    // _interpreter!.run(inputTensor, output);
    // return _mapOutputToChar(output);

    return null; // Platzhalter
  }

  void dispose() {
    // _interpreter?.close();
  }
}
