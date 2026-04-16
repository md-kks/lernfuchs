import os
import json
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from extra_keras_datasets import emnist
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt

# Konfiguration
CLASSES = ['A', 'E', 'I', 'O', 'U']
EMNIST_LABELS = [1, 5, 9, 15, 21] # A, E, I, O, U in EMNIST Letters
IMG_SIZE = 28
MODEL_NAME = "vowel_classifier"

def preprocess_data(x, y):
    # Filtere nur Vokale
    mask = np.isin(y, EMNIST_LABELS)
    x_filtered = x[mask]
    y_filtered = y[mask]
    
    # Re-map Labels auf 0-4
    label_map = {orig: i for i, orig in enumerate(EMNIST_LABELS)}
    y_mapped = np.array([label_map[label] for label in y_filtered])
    
    # EMNIST Orientierung korrigieren (Transpose) und Normalisieren
    # EMNIST ist standardmäßig transponiert gespeichert.
    x_processed = np.array([img.T for img in x_filtered])
    x_processed = x_processed.astype("float32") / 255.0
    x_processed = np.expand_dims(x_processed, -1) # (N, 28, 28, 1)
    
    return x_processed, y_mapped

def build_model():
    model = keras.Sequential([
        keras.Input(shape=(IMG_SIZE, IMG_SIZE, 1)),
        layers.Conv2D(32, kernel_size=(3, 3), activation="relu"),
        layers.MaxPooling2D(pool_size=(2, 2)),
        layers.Conv2D(64, kernel_size=(3, 3), activation="relu"),
        layers.MaxPooling2D(pool_size=(2, 2)),
        layers.Flatten(),
        layers.Dropout(0.5),
        layers.Dense(len(CLASSES), activation="softmax"),
    ])
    model.compile(loss="sparse_categorical_crossentropy", optimizer="adam", metrics=["accuracy"])
    return model

def train():
    print("Lade und filtere Daten...")
    (x_train_raw, y_train_raw), (x_test_raw, y_test_raw) = emnist.load_data(type='letters')
    
    x_train, y_train = preprocess_data(x_train_raw, y_train_raw)
    x_test, y_test = preprocess_data(x_test_raw, y_test_raw)
    
    # Validation Split
    x_train, x_val, y_train, y_val = train_test_split(x_train, y_train, test_size=0.1, random_state=42)
    
    print(f"Training Samples: {len(x_train)}")
    print(f"Validation Samples: {len(x_val)}")
    print(f"Test Samples: {len(x_test)}")
    
    model = build_model()
    model.summary()
    
    print("Starte Training...")
    history = model.fit(
        x_train, y_train, 
        batch_size=64, 
        epochs=10, 
        validation_data=(x_val, y_val)
    )
    
    # Evaluation
    score = model.evaluate(x_test, y_test, verbose=0)
    print(f"\nTest Accuracy: {score[1]:.4f}")
    
    # Confusion Matrix
    from sklearn.metrics import confusion_matrix, classification_report
    y_pred = model.predict(x_test)
    y_pred_classes = np.argmax(y_pred, axis=1)
    
    cm = confusion_matrix(y_test, y_pred_classes)
    print("\nConfusion Matrix:")
    print(cm)
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred_classes, target_names=CLASSES))
    
    # Visualisierung der Confusion Matrix
    plt.figure(figsize=(8, 6))
    import seaborn as sns
    sns.heatmap(cm, annot=True, fmt='d', xticklabels=CLASSES, yticklabels=CLASSES, cmap='Blues')
    plt.xlabel('Vorhergesagt')
    plt.ylabel('Tatsächlich')
    plt.title('Confusion Matrix: Vokal-Klassifikator')
    plt.savefig('ml_training/models/confusion_matrix.png')
    
    # Speichern
    os.makedirs("ml_training/models", exist_ok=True)
    model_path = f"ml_training/models/{MODEL_NAME}.keras"
    model.save(model_path)
    print(f"Keras Modell gespeichert: {model_path}")
    
    # TFLite Export
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    tflite_path = f"ml_training/models/{MODEL_NAME}.tflite"
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"TFLite Modell gespeichert: {tflite_path}")
    
    # Metadaten
    metadata = {
        "model_name": MODEL_NAME,
        "classes": CLASSES,
        "input_shape": [IMG_SIZE, IMG_SIZE, 1],
        "preprocessing": "normalize_0_1, transpose_xy",
        "accuracy": float(score[1]),
        "confidence_threshold": 0.7
    }
    with open("ml_training/models/metadata.json", "w") as f:
        json.dump(metadata, f, indent=4)
    print("Metadaten gespeichert: ml_training/models/metadata.json")

if __name__ == "__main__":
    train()
