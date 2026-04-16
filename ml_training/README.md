# LernFuchs Handwriting ML Training Workflow

Dieses Verzeichnis enthält den Workflow zum Trainieren eines Vokal-Klassifikators (A, E, I, O, U) für die LernFuchs-App.

## Ziel
Ein handgeschriebenes Zeichen (28x28 Graustufen) soll als einer der 5 Vokale erkannt werden.

## Struktur
- `scripts/inspect_data.py`: Hilft dabei, die EMNIST-Daten und deren Orientierung zu verstehen.
- `scripts/train_vowels.py`: Haupt-Trainingsskript (EMNIST laden -> Filtern -> Trainieren -> Export .tflite).
- `models/`: Hier werden die trainierten Modelle (.keras, .tflite) und Metadaten gespeichert.

## Setup & Training
Da TensorFlow und EMNIST groß sind, wird empfohlen, dies in einer lokalen virtuellen Umgebung auszuführen:

```bash
# 1. Navigiere in diesen Ordner
cd ml_training

# 2. Erstelle venv
python3 -m venv venv
source venv/bin/activate

# 3. Installiere Pakete
pip install -r requirements.txt

# 4. Daten prüfen (optional)
python scripts/inspect_data.py

# 5. Modell trainieren und exportieren
python scripts/train_vowels.py
```

## Modell-Details
- **Eingabe:** 28x28 Graustufen-Bild (0.0 - 1.0).
- **Orientierung:** EMNIST-Bilder sind standardmäßig transponiert. Das Skript korrigiert dies, sodass sie zur App-Pipeline passen.
- **Klassen (Mapping):**
  - 0: A
  - 1: E
  - 2: I
  - 3: O
  - 4: U
- **Architektur:** Simples CNN (2 Conv-Layer, Max-Pooling, Dropout, Dense-Softmax).

## Weiteres Vorgehen
Nach erfolgreichem Training kann die Datei `models/vowel_classifier.tflite` in die App unter `assets/ml/handwriting.tflite` kopiert werden.
