# ML Training Workflow (Handschrifterkennung)

Dieses Dokument beschreibt den Prozess zum Trainieren und Exportieren von Machine-Learning-Modellen für die Handschrifterkennung in LernFuchs.

## 1. Übersicht
Der Workflow befindet sich im Verzeichnis `ml_training/` und ist als lokal ausführbares Python-Paket konzipiert. Er deckt die gesamte Pipeline von der Dateninspektion bis zum TFLite-Export ab.

## 2. Datenbasis
- **Datensatz:** EMNIST (Letters-Subset).
- **Zielklassen:** Aktuell fokussiert auf Vokale (A, E, I, O, U).
- **Orientierung:** Das Skript korrigiert die standardmäßig transponierte Speicherung von EMNIST-Bildern (`img.T`), um sie mit der App-Pipeline kompatibel zu machen.

## 3. Modellarchitektur
Verwendet wird ein Convolutional Neural Network (CNN) mit folgendem Aufbau:
- **Input:** 28x28x1 Graustufen (Float32, 0.0 bis 1.0).
- **Feature Extraction:** 2x Conv2D (32/64 Filter) mit ReLU und MaxPooling.
- **Regularisierung:** Dropout (0.5).
- **Output:** Dense (Softmax) mit 5 Ausgängen.

## 4. Ausführung des Workflows
Detaillierte Anweisungen befinden sich in `ml_training/README.md`.
1. **Setup:** Erstellen eines `venv` und Installation der `requirements.txt` (TensorFlow, Scikit-learn, Seaborn, etc.).
2. **Inspektion:** Ausführung von `scripts/inspect_data.py` zur Verifizierung der Orientierung.
3. **Training:** Ausführung von `scripts/train_vowels.py`. Erzeugt:
   - `models/vowel_classifier.keras` (Vollständiges Modell)
   - `models/vowel_classifier.tflite` (Optimiert für On-Device)
   - `models/confusion_matrix.png` (Evaluationsbericht)
   - `models/metadata.json` (Klassenmapping & Parameter)

## 5. Integration in die App
Die Datei `vowel_classifier.tflite` wird nach `assets/ml/handwriting.tflite` kopiert. Das `HandwritingWidget` nutzt die in `metadata.json` definierte Vorverarbeitung und Klassenreihenfolge.
