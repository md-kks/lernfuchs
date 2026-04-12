# Feature Flags

## Überblick

Feature Flags in LernFuchs sind in `lib/app/feature_flags.dart` definiert. Alle Flags sind `static const bool` — Compile-Zeit-Konstanten ohne Runtime-Overhead.

Die Klasse `FeatureFlags` hat einen privaten Konstruktor (`const FeatureFlags._()`) und kann nicht instanziiert werden.

## Aktuelle Flags

| Flag | Typ | Default | Status | Beschreibung |
|------|-----|---------|--------|-------------|
| `FeatureFlags.enableGameWorld` | bool | false | Noch nicht in Verhaltenslogik verdrahtet | Schaltet Flame-Spielwelt ein; aktuell nur Placeholder für Flutter+Flame-Migration (siehe `docs/refactor_map.md`) |

## Geplante Verwendung

Das Flag `enableGameWorld` wird künftig wie folgt geprüft:

```dart
if (FeatureFlags.enableGameWorld) {
  // Starte Flame-Spielwelt
  return GameWorldScreen();
} else {
  // Verwende existierende UI
  return ExistingScreen();
}
```

Hinweis: Diese Integration ist noch nicht implementiert.

## Neues Flag hinzufügen

Um ein neues Feature Flag hinzuzufügen:

1. **Konstante in `lib/app/feature_flags.dart` definieren:**
   ```dart
   class FeatureFlags {
     const FeatureFlags._();

     static const bool enableGameWorld = false;
     static const bool enableNewFeature = false;  // Neues Flag
   }
   ```

2. **Flag an relevanten Stellen im Code prüfen:**
   ```dart
   if (FeatureFlags.enableNewFeature) {
     // Neue Logik
   }
   ```

3. **Dieses Dokument (`docs/feature_flags.md`) aktualisieren** — Flag zur Tabelle hinzufügen.

## Design-Entscheidung

- **Compile-Time Konstanten:** Keine Runtime-Evaluierung, optimiert vom Dart Compiler.
- **Kein Dynamic-Config-System:** Flags sind nicht zur Laufzeit veränderbar.
- **Kein A/B-Testing, kein Remote-Config:** Einfaches Modell für die aktuelle Projektstufe.

Sollte später Remote-Config notwendig sein (z.B. für A/B-Testing), müsste ein externer Dienst (Firebase Remote Config, Custom Backend) integriert werden.
