# Statusbericht: Implementierung LernFuchs 2.0 (Neuro- und Spielwissenschaft)

Dieses Dokument dokumentiert den aktuellen Umsetzungsstand der in `Lern-App-Konzept_ Neuro- und Spielwissenschaft.md` geforderten neuro-adaptiven und spielwissenschaftlichen Funktionen.

## 1. Bereits implementierte Funktionen (Stand: April 2026)

### A. Neuro-adaptives Elo-Rating (Phase 1)
*   **Elo-Engine (`EloDifficultyEngine`):** Ein neues Modell zur Schwierigkeitsanpassung wurde implementiert. Es berechnet die Gewinnwahrscheinlichkeit des Kindes gegen die Aufgabe (Zone der proximalen Entwicklung).
*   **Individuelle Progress-Profile:** Das `TopicProgress`-Modell speichert nun ein dynamisches `eloRating` pro Thema.
*   **In-Session Anpassung:** Die `LearningEngine` und der `StorageService` aktualisieren das Rating nach jedem Versuch (`recordResult`) in Echtzeit.

### B. Verschachteltes Lernen / Interleaving (Phase 1)
*   **Verschachtelte Sessions:** Der `TaskGenerator` kann nun Aufgaben aus verschiedenen Themen (z. B. Mathe + Deutsch) in einer Sitzung mischen (`generateInterleavedSession`).
*   **Quest-Integration:** `QuestDefinition` und `LearningRequest` wurden erweitert, um Themenlisten für "Interleaved Challenges" zu unterstützen.

### C. TFLite-Handschrifterkennung (Phase 2 - Infrastruktur)
*   **ML-Service (`TFLiteService`):** Ein Service zum Laden von `.tflite`-Modellen und zur Inferenz-Vorbereitung wurde erstellt.
*   **Hybrid-Widget:** Das `HandwritingWidget` liefert Koordinaten an den ML-Service und nutzt ein Coverage-System als robusten Fallback.
*   **Pakete:** `tflite_flutter` wurde in die `pubspec.yaml` integriert.

### D. Scaffolding & Growth Mindset (Phase 3)
*   **Fade-in Scaffolding:** Die `LearningChallengeSession` enthält einen 8-Sekunden-Inaktivitäts-Timer, der einen visuellen Hinweis ("Ova's Tipp") und motivierende Sprache triggert.
*   **Growth Mindset Feedback:** Harte Fehler-Sounds wurden durch konstruktive VUI-Rückmeldungen ersetzt (z. B. "Fehler helfen uns beim Lernen"), die nach wiederholten Fehlern spezifischere Strategien vorschlagen.

### E. Gesundheitsprävention (Phase 4)
*   **20/20-Regel:** Ein `HealthService` überwacht die Nutzungszeit. Alle 20 Minuten wird ein unüberspringbares `BreakOverlay` (20 Sekunden) eingeblendet, um Kurzsichtigkeit vorzubeugen.
*   **Narrative Einbettung:** Die Pause wird als "Finos Ruhepause" gerahmt, um den Spielfluss nicht negativ zu unterbrechen.

---

## 2. Noch ausstehende oder unvollständige Punkte

### A. TFLite Modell & Preprocessing
*   **Status:** Infrastruktur bereit, Modell fehlt.
*   **Was fehlt:** Eine trainierte `handwriting.tflite` Datei muss in `assets/ml/` abgelegt werden. Der `TFLiteService` benötigt noch die spezifische Vorverarbeitung (Preprocessing), um die Strich-Koordinaten in das Eingabeformat des Modells (z. B. 28x28 Graustufen-Bild) umzuwandeln.

### B. Komplexes Base-Building (Baumhaus 2.0)
*   **Status:** Rudimentär vorhanden.
*   **Was fehlt:** Das Konzept fordert ein tieferes System mit verschiedenen Ressourcen (Holz, Stein, Blätter) und mehr Gestaltungsfreiheit (Avatar-Customization, Möbel). Aktuell gibt es nur "Sternensamen" und ein festes Upgrade.

### C. Erweiterte Gesundheits-Features
*   **Status:** 20/20-Regel implementiert.
*   **Was fehlt:** Die "Ellenbogen-Regel" (Abstandsmessung via Frontkamera) ist noch nicht umgesetzt. Ebenso fehlen die konfigurierbaren Screen-Time-Limits für Eltern im Dashboard.

### D. EDDA-Algorithmus (Engagement-oriented DDA)
*   **Status:** Simples Zeitlimit (8s) für Scaffolding.
*   **Was fehlt:** Ein echtes EDDA-Monitoring, das die "Sleep Phase" (freies Explorieren ohne Eingriff) und "Active Phase" basierend auf der effektiven Spielzeit pro Zeiteinheit präzise trennt.

### E. Analoger Transfer (Arbeitsblatt-Drucker)
*   **Status:** Nicht implementiert.
*   **Was fehlt:** Ein PDF-Generator-Service, der basierend auf dem Lernerfolg personalisierte "Fuchstagebuch"-Seiten zum Ausdrucken erstellt.

---

## 3. Nächste empfohlene Schritte
1.  **Modell-Integration:** Bereitstellung und Einbindung des TFLite-Modells für echte Zeichen-Erkennung.
2.  **Eltern-Dashboard:** Erweiterung um Screen-Time-Settings und Fortschrittsberichte.
3.  **Ressourcen-System:** Ausbau des Belohnungssystems, um "Stealth Learning" durch kreatives Bauen attraktiver zu machen.
