# Statusbericht: Implementierung LernFuchs 2.0 (Neuro- und Spielwissenschaft)

Dieses Dokument dokumentiert den aktuellen Umsetzungsstand der in `Lern-App-Konzept_ Neuro- und Spielwissenschaft.md` geforderten neuro-adaptiven und spielwissenschaftlichen Funktionen.

## 1. Bereits implementierte Funktionen (Stand: April 2026)

### A. Neuro-adaptives Elo-Rating (Phase 1)
*   **Elo-Engine (`EloDifficultyEngine`):** Ein Modell zur Schwierigkeitsanpassung, das den Schüler und die Aufgabe als Kontrahenten betrachtet. Es zielt auf die Gewinnwahrscheinlichkeit in der "Zone der proximalen Entwicklung" ab.
*   **Individuelle Progress-Profile:** Das `TopicProgress`-Modell speichert ein dynamisches `eloRating` pro Thema.
*   **In-Session Anpassung:** Die `LearningEngine` aktualisiert das Rating nach jedem Versuch in Echtzeit.

### B. Verschachteltes Lernen / Interleaving (Phase 1)
*   **Verschachtelte Sessions:** Der `TaskGenerator` kann Aufgaben aus verschiedenen Themen (z. B. Mathe + Deutsch) in einer Sitzung mischen (`generateInterleavedSession`).
*   **Quest-Integration:** Quests unterstützen nun Themenlisten für gemischte Herausforderungen.

### C. EDDA-System (Engagement-oriented DDA) (Phase 5)
*   **Engagement-Monitoring:** Der `EngagementService` misst in Echtzeit die Interaktions-Latenz und Fehlerrate.
*   **Sleep Phase:** Das System bleibt in den ersten 15 Sekunden einer Aufgabe passiv, um die Autonomie des Kindes zu wahren.
*   **Active Phase & Intervention:** Sinkt der Engagement-Score unter 0.35, wird eine Intervention ausgelöst.
*   **Concealment (Verdecktheit):** Bei Frustrationsgefahr wird die Schwierigkeit der nächsten Aufgabe automatisch und unbemerkt um eine Stufe gesenkt ("Confidence Boost").
*   **Adaptive VUI:** Mentorin Ova passt ihre Tipps an das Engagement-Level an (proaktivere Hilfe bei niedrigem Score).

### D. Scaffolding & Growth Mindset (Phase 3)
*   **Fade-in Scaffolding:** Automatischer visueller Hinweis und motivierende Sprachausgabe nach Inaktivität.
*   **Growth Mindset Feedback:** VUI-Rückmeldungen wie "Fehler helfen uns beim Lernen" ersetzen rein bestrafende Sounds.

### E. Gesundheitsprävention (Phase 4)
*   **20/20-Regel:** Ein `HealthService` erzwingt alle 20 Minuten eine 20-sekündige Augenpause via `BreakOverlay`.
*   **Narrative Einbettung:** Die Pause ist als "Finos Ruhepause" in die Spielwelt integriert.

### F. TFLite-Handschrifterkennung (Infrastruktur)
*   **ML-Service (`TFLiteService`):** Infrastruktur zum Laden von Modellen und zur Inferenz ist vorbereitet.
*   **Hybrid-Widget:** Das `HandwritingWidget` liefert Koordinaten und nutzt ein Coverage-System als robusten Fallback.

---

## 2. Noch ausstehende oder unvollständige Punkte

### A. TFLite Modell & Preprocessing
*   **Status:** Infrastruktur bereit, physisches Modell fehlt.
*   **Was fehlt:** Einbindung der `handwriting.tflite` Datei und spezifisches Preprocessing (Koordinaten -> Tensor).

### B. Komplexes Base-Building (Baumhaus 2.0)
*   **Status:** Rudimentär vorhanden.
*   **Was fehlt:** Erweitertes Ressourcen-System (Holz, Stein, Blätter) und freie Gestaltungsmöglichkeiten für Möbel/Deko.

### C. Eltern-Dashboard Erweiterung
*   **Status:** Basis vorhanden.
*   **Was fehlt:** Konfigurierbare Screen-Time-Limits und die "Ellenbogen-Regel" (Abstandsmessung via Kamera).

### D. Analoger Transfer (Arbeitsblatt-Drucker)
*   **Status:** Nicht implementiert.
*   **Was fehlt:** PDF-Generator für personalisierte "Fuchstagebuch"-Seiten.

---

## 3. Nächste empfohlene Schritte
1.  **Modell-Integration:** Finalisierung der echten Handschrifterkennung.
2.  **Ressourcen-System:** Ausbau des Baumhaus-Gameplays zur Steigerung der Langzeitmotivation.
3.  **PDF-Service:** Implementierung des analogen Wissenstransfers.
