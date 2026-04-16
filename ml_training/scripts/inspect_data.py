import numpy as np
import matplotlib.pyplot as plt
from extra_keras_datasets import emnist

def inspect():
    print("--- EMNIST Vokal-Inspektion ---")
    print("Lade EMNIST Letters Datensatz...")
    (x_train, y_train), (x_test, y_test) = emnist.load_data(type='letters')
    
    # EMNIST Letters mapping: 1=A, 2=B, ..., 26=Z
    vowel_map = {1: 'A', 5: 'E', 9: 'I', 15: 'O', 21: 'U'}
    vowel_labels = list(vowel_map.keys())
    
    mask = np.isin(y_train, vowel_labels)
    x_vowels = x_train[mask]
    y_vowels = y_train[mask]
    
    print(f"Gesamtanzahl Vokale im Training: {len(x_vowels)}")
    for label, char in vowel_map.items():
        count = np.sum(y_vowels == label)
        print(f"  - {char} (Label {label}): {count} Beispiele")

    plt.figure(figsize=(15, 6))
    for i, (label, char) in enumerate(vowel_map.items()):
        idx = np.where(y_train == label)[0][0]
        
        # Original (wie in EMNIST Datei)
        img_orig = x_train[idx]
        plt.subplot(2, 5, i + 1)
        plt.imshow(img_orig, cmap='gray')
        plt.title(f"EMNIST Raw: {char}")
        plt.axis('off')
        
        # Korrigiert (wie das Modell es sehen wird)
        img_fixed = img_orig.T
        plt.subplot(2, 5, i + 6)
        plt.imshow(img_fixed, cmap='gray')
        plt.title(f"Model Input: {char}")
        plt.axis('off')
        
    plt.tight_layout()
    plt.savefig('ml_training/data_inspection.png')
    print("\nVergleichsbild unter 'ml_training/data_inspection.png' gespeichert.")
    print("OBERE REIHE: Rohdaten aus EMNIST (oft rotiert/gespiegelt).")
    print("UNTERE REIHE: Korrigierte Daten (transponiert) für das Training.")

if __name__ == "__main__":
    inspect()
