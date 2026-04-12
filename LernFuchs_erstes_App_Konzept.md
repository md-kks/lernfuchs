# LernFuchs — App-Konzept & Entwicklungsplan

## Grundschul-Lernapp für Mathe & Deutsch (Klasse 1–4)
**Plattformen:** Android + iOS (Flutter)  
**Geschäftsmodell:** Einmalkauf, offline, kein Abo, keine Anmeldung  
**Zielmarkt:** DACH (Deutschland, Österreich, Schweiz)

---

## 1. Marktanalyse

### 1.1 Konkurrenzlandschaft

| App | Modell | Stärken | Schwächen |
|-----|--------|---------|-----------|
| **ANTON** | Freemium + Abo (9,99 €/Jahr) | 10 Mio+ Downloads, alle Fächer, EU-gefördert, datenschutzfreundlich | Offline nur mit Abo, Anmeldung erforderlich, schlichte Grafik, Minispiele lenken ab |
| **Conni Lernspaß** | Einmalkauf (3,99 €) | Starke Marke, kindgerecht, offline | Nur Kl. 1–2, begrenzter Umfang, separate Apps pro Fach |
| **Lernerfolg Grundschule** (Tivola) | Einmalkauf + IAP | Mathe+Deutsch+Englisch, Comenius-Preis | In-App-Käufe pro Klassenstufe, veraltet wirkendes Design |
| **König der Mathematik** | Freemium + Einmalkauf | Gamification, Ranking | Nur Mathe, eher ab Kl. 5, kein Deutsch |
| **Schlaukopf** | Freemium + Abo | Riesiger Fragenkatalog | Viel Werbung in Gratisversion, trockenes Quiz-Format |
| **Klett Grundschul-Apps** | Einmalkauf (2–4 €) | Lehrwerksgebunden, pädagogisch solide | Nur sinnvoll mit Klett-Lehrwerk, teuer als Gesamtpaket |
| **Fiete Math** | Einmalkauf (3,99 €) | Kreatives Konzept, haptisch | Nur Mathe Grundlagen, sehr begrenzt |

### 1.2 Marktlücke — Was fehlt

Die Recherche zeigt eine klare Lücke:

**Es gibt keine App im DACH-Raum, die ALL diese Eigenschaften vereint:**

1. **Einmalkauf** — alle Inhalte Kl. 1–4, Mathe + Deutsch, ein Preis
2. **100% offline** — ohne Abo, ohne Anmeldung, ohne Internet
3. **Kein Tracking** — null Datenerhebung, null Server-Kommunikation
4. **Abwechslungsreiche Aufgabentypen** — über simples Multiple-Choice hinaus
5. **Lehrplanorientiert** — an DACH-Curricula ausgerichtet
6. **Eltern-Dashboard** — ohne Cloud, lokal auf dem Gerät
7. **Druckbare Arbeitsblätter** — PDF-Export direkt aus der App

ANTON kommt dem am nächsten, aber: Abo für Offline, Anmeldung nötig, Minispiele als Zeitfresser. Conni ist zu begrenzt. Klett ist lehrwerksgebunden.

### 1.3 Zielgruppe & Marktgröße

- **Deutschland:** ca. 3 Mio. Grundschulkinder (Kl. 1–4), ca. 2,4 Mio. Haushalte
- **Österreich:** ca. 340.000 Grundschulkinder
- **Schweiz:** ca. 320.000 Grundschulkinder
- **Gesamt DACH:** ~3,6 Mio. Kinder / ~2,9 Mio. Haushalte
- Bei 14,99 € Kaufpreis und 0,5% Marktdurchdringung = **~217.000 €** Umsatz
- Bei 1% Durchdringung = **~434.000 €** Umsatz
- Conni-Apps zeigen: Einmalkauf-Modell funktioniert im deutschsprachigen Grundschulmarkt

### 1.4 Kaufargumente für Eltern

Die stärksten Schmerzpunkte der Eltern (= unsere Verkaufsargumente):

1. **„Mein Kind braucht kein weiteres Abo"** — Einmalkauf, fertig
2. **„Funktioniert auch im Zug/Auto/Urlaub"** — 100% offline
3. **„Keine Angst vor Daten meines Kindes"** — null Tracking, null Server
4. **„Kein Suchtfaktor durch Endlos-Spiele"** — fokussiertes Lernen statt Gamification-Falle
5. **„Passt zum Lehrplan, nicht zu einem Verlag"** — lehrwerksunabhängig

---

## 2. Differenzierungsstrategie — Was uns einzigartig macht

### 2.1 Kern-Alleinstellungsmerkmale (USPs)

#### USP 1: „Aufgaben-Generator" — Nie dieselbe Aufgabe zweimal
Anders als ANTON oder Schlaukopf (feste Aufgabenpools) generiert unsere App **algorithmisch neue Aufgaben**. Ein Kind kann die App 4 Jahre nutzen, ohne Wiederholungen. Das ist der Hauptgrund, warum ein Einmalkauf den Wert eines Abos übersteigt.

**Technisch:** Parametrische Templates pro Aufgabentyp, Schwierigkeitsgrad-Parameter, Seed-basierte Reproduzierbarkeit für Eltern/Lehrer-Kontrolle.

#### USP 2: „Schreibschrift-Erkennung" (Handschrift-Input)
Kinder schreiben die Antworten mit dem Finger/Stift direkt auf den Screen. Kein Multiple-Choice-Raten, sondern echtes Schreiben und Rechnen. ML-basierte Handschrifterkennung (on-device via TFLite).

#### USP 3: „Arbeitsblatt-Drucker"
Eltern können aus jeder Übungseinheit ein druckbares PDF-Arbeitsblatt generieren — inklusive Lösungsblatt. Perfekt für Hausaufgaben-Ergänzung oder wenn das Kind mal ohne Tablet lernen soll.

#### USP 4: „Lernstandsbericht" — Lokal, ohne Cloud
Ein lokales Eltern-Dashboard (PIN-geschützt) zeigt:
- Welche Themen geübt wurden
- Wo Schwächen liegen (Fehlerquote pro Thema)
- Zeitlicher Verlauf der Lernfortschritte
- Empfehlungen, welche Themen geübt werden sollten

Alles ohne Server, ohne Account, ohne Datenübertragung.

#### USP 5: „Bundesland-Modus"
Lehrpläne variieren zwischen Bundesländern. Eltern wählen beim Start ihr Bundesland, und der Aufgabenpool passt sich an (z.B. Schreibschrift vs. Druckschrift, Zeitpunkt Einmaleins, etc.).

### 2.2 Aufgabentypen — Über Multiple-Choice hinaus

| Kategorie | Aufgabentypen |
|-----------|--------------|
| **Mathe Kl. 1–2** | Zahlenschreiben (Handschrift), Punkte zählen, Addition/Subtraktion freie Eingabe, Zahlenmauern, Rechenketten, Größer/Kleiner/Gleich (Drag&Drop), Einmaleins-Blitz, Uhrzeit-Stellen (interaktive Uhr), Geld zählen (Münzen-Drag&Drop), Muster fortsetzen, Formen erkennen |
| **Mathe Kl. 3–4** | Schriftliche Verfahren (Schritt-für-Schritt mit Übertrag), Division mit Rest, Brüche visualisieren (Tortendiagramm-Touch), Dezimalzahlen am Zahlenstrahl (Slider), Umrechnen (Längen/Gewichte/Zeit), Diagramme lesen, Umfang/Fläche mit Gitterfeld, Sachaufgaben mit Rechenschrittbaukasten |
| **Deutsch Kl. 1–2** | Buchstaben-Nachschreiben (Handschrift), Silben klatschen (Tap-Rhythmus), Anlaute erkennen (Audio+Bild), Wörter lesen + Bild zuordnen, Artikel zuordnen (Drag&Drop), Reimwörter verbinden, Einzahl/Mehrzahl, ABC sortieren, Lückenwörter |
| **Deutsch Kl. 3–4** | Zeitformen-Tabelle ausfüllen, Wortarten sortieren (Drag&Drop in Spalten), Satzglieder umstellen (Drag&Drop), Vier Fälle bestimmen, das/dass-Übung, Wörtliche Rede Satzzeichen setzen, Fehlertext korrigieren, Kommasetzung, Diktat (Audio → Schreiben), Lesetext + Verständnisfragen |

### 2.3 Monetarisierung

| Variante | Preis | Inhalt |
|----------|-------|--------|
| **LernFuchs Mathe** | 7,99 € | Mathe Kl. 1–4, alle Aufgabentypen |
| **LernFuchs Deutsch** | 7,99 € | Deutsch Kl. 1–4, alle Aufgabentypen |
| **LernFuchs Komplett** | 12,99 € | Mathe + Deutsch Kl. 1–4 (Bundle-Rabatt) |

Alternativ: Einzelfach-App für 9,99 € und Bundle für 14,99 €. A/B-Test der Preise nach Launch.

Keine In-App-Käufe, keine Werbung, keine versteckten Kosten.

---

## 3. Technische Architektur

### 3.1 Tech Stack

```
Framework:       Flutter (Dart) — ein Codebase für Android + iOS
State Mgmt:      Riverpod
Lokale DB:       Hive (offline-first, kein SQL nötig)
Handschrift:     TensorFlow Lite (on-device)
PDF-Export:      pdf (Dart-Paket)
Audio:           audioplayers / just_audio
Animationen:     Rive oder Lottie
Testing:         flutter_test + integration_test
CI/CD:           GitHub Actions → Fastlane → Play Store / App Store
```

### 3.2 App-Architektur

```
lib/
├── main.dart
├── app/
│   ├── router.dart              # GoRouter Navigation
│   ├── theme.dart               # Kindgerechtes Design-System
│   └── localization.dart        # DE/AT/CH Varianten
├── core/
│   ├── engine/
│   │   ├── task_generator.dart   # Algorithmischer Aufgaben-Generator
│   │   ├── difficulty.dart       # Schwierigkeitsgrad-Algorithmus
│   │   ├── evaluator.dart        # Antwort-Auswertung
│   │   └── curriculum.dart       # Lehrplan-Mapping pro Bundesland
│   ├── models/
│   │   ├── task.dart             # Aufgaben-Datenmodell
│   │   ├── subject.dart          # Fach (Mathe/Deutsch)
│   │   ├── grade.dart            # Klassenstufe
│   │   ├── progress.dart         # Lernfortschritt
│   │   └── settings.dart         # App-Einstellungen
│   └── services/
│       ├── storage_service.dart  # Hive-basierte Persistenz
│       ├── pdf_service.dart      # Arbeitsblatt-PDF-Generator
│       ├── audio_service.dart    # Vorlesefunktion
│       └── handwriting_service.dart  # On-Device ML
├── features/
│   ├── home/                    # Startscreen mit Klassenauswahl
│   ├── subject_overview/        # Themenübersicht pro Fach
│   ├── exercise/                # Übungs-Session (Kern der App)
│   │   ├── widgets/
│   │   │   ├── number_input.dart
│   │   │   ├── drag_drop_sort.dart
│   │   │   ├── handwriting_pad.dart
│   │   │   ├── clock_widget.dart
│   │   │   ├── fraction_visual.dart
│   │   │   ├── money_counter.dart
│   │   │   └── gap_fill.dart
│   │   └── exercise_screen.dart
│   ├── worksheet/               # PDF-Arbeitsblatt-Export
│   ├── progress/                # Lernstands-Dashboard (Eltern)
│   └── settings/                # Bundesland, Profil, PIN
└── shared/
    ├── widgets/                 # Wiederverwendbare UI-Komponenten
    ├── animations/              # Belohnungs-Animationen
    └── constants/               # Farben, Strings, Assets
```

### 3.3 Aufgaben-Generator — Kernlogik

```dart
// Konzept: Jeder Aufgabentyp ist ein Template mit Parametern
abstract class TaskTemplate {
  final String id;
  final Subject subject;
  final int grade;
  final String topic;
  final DifficultyRange difficultyRange;
  
  Task generate(int difficulty, Random rng);
  bool evaluate(Task task, dynamic answer);
  String get instruction; // Aufgabenstellung
}

// Beispiel: Addition
class AdditionTemplate extends TaskTemplate {
  @override
  Task generate(int difficulty, Random rng) {
    final maxNum = switch(difficulty) {
      1 => 10, 2 => 20, 3 => 50, 4 => 100, _ => 1000,
    };
    final a = rng.nextInt(maxNum);
    final b = rng.nextInt(maxNum - a); // Ergebnis ≤ maxNum
    return Task(
      question: '$a + $b = ___',
      correctAnswer: a + b,
      type: TaskType.freeInput,
    );
  }
}
```

### 3.4 Datenschutz-Architektur

```
╔══════════════════════════════════════╗
║  LernFuchs App                      ║
║                                      ║
║  ┌──────────┐     ┌──────────────┐  ║
║  │ Hive DB  │     │ TFLite Model │  ║
║  │ (lokal)  │     │ (on-device)  │  ║
║  └──────────┘     └──────────────┘  ║
║                                      ║
║  KEINE Netzwerk-Verbindungen         ║
║  KEINE Analytics                     ║
║  KEINE Crash-Reporter                ║
║  KEINE Push-Notifications            ║
║  KEIN Account / Login                ║
║                                      ║
║  Internet-Permission: NICHT angefragt║
╚══════════════════════════════════════╝
```

Die App fordert keine Internet-Permission an. Punkt.

---

## 4. UI/UX Design-Prinzipien

### 4.1 Kindgerechtes Design

- **Große Touch-Targets:** min. 48dp, besser 56dp
- **Klare Typografie:** Runde, gut lesbare Schrift (Nunito/Quicksand)
- **Farbkodierung:** Jede Klassenstufe hat eigene Farbwelt (wie die PDFs)
- **Sofortiges Feedback:** Richtig = grüner Haken + kurze Animation, Falsch = sanfter Hinweis + zweiter Versuch
- **Kein Timer-Druck:** Kinder lernen in ihrem Tempo
- **Vorlesefunktion:** Alle Aufgabenstellungen können vorgelesen werden (TTS on-device)
- **Keine Ablenkung:** Kein Chat, kein Social, keine Minispiele, kein Shop

### 4.2 Screen-Flow

```
[Start] → [Klasse wählen] → [Fach wählen] → [Thema wählen]
    ↓
[Übung] → 10 Aufgaben → [Ergebnis-Screen: Sterne + Zusammenfassung]
    ↓
[Weiter üben] oder [Zurück zur Übersicht]

Eltern-Bereich (PIN):
[Dashboard] → [Fortschritte] → [Arbeitsblatt drucken] → [Einstellungen]
```

---

## 5. Entwicklungs-Roadmap (CLI-Todo-Liste)

### Phase 1: Fundament (Wochen 1–4)

```
[ ] 1.01  Flutter-Projekt initialisieren (flutter create lernfuchs)
[ ] 1.02  Projekt-Struktur nach Architektur-Vorlage anlegen
[ ] 1.03  Riverpod Setup + Provider-Struktur
[ ] 1.04  Hive Setup + lokale DB-Modelle (Task, Progress, Settings)
[ ] 1.05  Design-System erstellen (Farben, Typografie, Spacing, Themes pro Klasse)
[ ] 1.06  Gemeinsame Widgets: RoundedButton, StarRating, ProgressBar, TaskCard
[ ] 1.07  GoRouter Navigation mit verschachtelten Routes
[ ] 1.08  Startscreen: Klassenstufen-Auswahl (1–4) mit Farb-Karten
[ ] 1.09  Fach-Auswahl-Screen (Mathe / Deutsch)
[ ] 1.10  Themen-Übersicht-Screen mit Fortschrittsanzeige pro Thema
[ ] 1.11  Basis-Übungs-Session-Framework (10 Aufgaben, Auswertung, Ergebnis)
[ ] 1.12  Aufgaben-Generator Core-Engine (TaskTemplate, Difficulty, Evaluator)
[ ] 1.13  Lernfortschritt-Persistenz (Hive: pro Thema Fehlerquote + Versuche)
[ ] 1.14  Bundesland-Auswahl beim ersten Start (SharedPreferences)
[ ] 1.15  Unit Tests für Aufgaben-Generator und Evaluator
```

### Phase 2: Mathe-Aufgaben (Wochen 5–8)

```
[ ] 2.01  Mathe Kl.1: Zahlen schreiben (Zahleneingabe-Widget)
[ ] 2.02  Mathe Kl.1: Punkte zählen (visuell + Eingabe)
[ ] 2.03  Mathe Kl.1: Addition bis 10 (Freie Eingabe)
[ ] 2.04  Mathe Kl.1: Subtraktion bis 10
[ ] 2.05  Mathe Kl.1: Größer/Kleiner/Gleich (Tap auf >, <, =)
[ ] 2.06  Mathe Kl.1: Zahlenreihen fortsetzen
[ ] 2.07  Mathe Kl.1: Formen erkennen (Bild → Name zuordnen)
[ ] 2.08  Mathe Kl.1: Muster fortsetzen (Drag&Drop)
[ ] 2.09  Mathe Kl.2: Addition/Subtraktion bis 100
[ ] 2.10  Mathe Kl.2: Einmaleins-Trainer (Blitz-Modus + Tabelle)
[ ] 2.11  Mathe Kl.2: Uhrzeit (Interaktives Uhren-Widget)
[ ] 2.12  Mathe Kl.2: Geld zählen (Münz-Drag&Drop-Widget)
[ ] 2.13  Mathe Kl.2: Zahlenmauern + Rechenketten
[ ] 2.14  Mathe Kl.2: Textaufgaben (Lesen + Rechnung + Antwort)
[ ] 2.15  Mathe Kl.3: Schriftliche Addition (Schritt-für-Schritt-Widget)
[ ] 2.16  Mathe Kl.3: Schriftliche Subtraktion
[ ] 2.17  Mathe Kl.3: Halbschriftliche Multiplikation
[ ] 2.18  Mathe Kl.3: Division mit Rest
[ ] 2.19  Mathe Kl.3: Größen umrechnen (Längen, Gewichte, Zeit)
[ ] 2.20  Mathe Kl.3: Geometrie (Umfang, Fläche mit Gitter-Widget)
[ ] 2.21  Mathe Kl.4: Schriftliche Multiplikation
[ ] 2.22  Mathe Kl.4: Schriftliche Division
[ ] 2.23  Mathe Kl.4: Brüche (Visuelles Tortendiagramm-Widget)
[ ] 2.24  Mathe Kl.4: Dezimalzahlen (Zahlenstrahl-Slider)
[ ] 2.25  Mathe Kl.4: Diagramme lesen (Balkendiagramm + Fragen)
[ ] 2.26  Mathe Kl.4: Große Zahlen / Runden
[ ] 2.27  Mathe Kl.4: Sachaufgaben Klasse 4 Niveau
[ ] 2.28  Alle Mathe-Templates: Unit Tests + Edge-Case-Tests
```

### Phase 3: Deutsch-Aufgaben (Wochen 9–12)

```
[ ] 3.01  Deutsch Kl.1: Buchstaben nachschreiben (Handschrift-Pad)
[ ] 3.02  Deutsch Kl.1: Anlaute erkennen (Audio-Bild-Zuordnung)
[ ] 3.03  Deutsch Kl.1: Silben klatschen (Tap-Rhythmus-Widget)
[ ] 3.04  Deutsch Kl.1: Wort lesen + Bild zuordnen
[ ] 3.05  Deutsch Kl.1: Reimwörter verbinden (Drag&Drop Linien)
[ ] 3.06  Deutsch Kl.1: Wörter vervollständigen (Lückenbuchstabe)
[ ] 3.07  Deutsch Kl.1: Buchstaben-Salat (Buchstaben ordnen)
[ ] 3.08  Deutsch Kl.2: Artikel zuordnen (der/die/das Drag&Drop)
[ ] 3.09  Deutsch Kl.2: Wortarten sortieren (Nomen/Verb/Adjektiv Spalten)
[ ] 3.10  Deutsch Kl.2: Einzahl/Mehrzahl
[ ] 3.11  Deutsch Kl.2: ie/ei, doppelte Mitlaute (Lückenwörter)
[ ] 3.12  Deutsch Kl.2: ABC sortieren (Drag&Drop Reihenfolge)
[ ] 3.13  Deutsch Kl.2: Sätze bilden (Wörter in richtige Reihenfolge)
[ ] 3.14  Deutsch Kl.2: Lesetext + Verständnisfragen
[ ] 3.15  Deutsch Kl.3: Zeitformen (Tabelle ausfüllen)
[ ] 3.16  Deutsch Kl.3: Wortfamilien finden
[ ] 3.17  Deutsch Kl.3: Zusammengesetzte Nomen (Drag&Drop verbinden)
[ ] 3.18  Deutsch Kl.3: Satzarten erkennen + Satzzeichen setzen
[ ] 3.19  Deutsch Kl.3: Diktat (TTS vorlesen → Kind schreibt)
[ ] 3.20  Deutsch Kl.3: Lernwörter (Lesen, abdecken, schreiben, prüfen)
[ ] 3.21  Deutsch Kl.4: Vier Fälle bestimmen
[ ] 3.22  Deutsch Kl.4: Subjekt/Prädikat/Objekt (Drag&Drop Markierung)
[ ] 3.23  Deutsch Kl.4: das/dass-Übung
[ ] 3.24  Deutsch Kl.4: Wörtliche Rede — Satzzeichen setzen
[ ] 3.25  Deutsch Kl.4: Fehlertext korrigieren (Tap auf Fehler)
[ ] 3.26  Deutsch Kl.4: Kommasetzung
[ ] 3.27  Deutsch Kl.4: Bericht vs. Erzählung erkennen
[ ] 3.28  Alle Deutsch-Templates: Unit Tests
```

### Phase 4: Spezial-Features (Wochen 13–16)

```
[ ] 4.01  Handschrift-Erkennung: TFLite-Modell für Ziffern (0–9) integrieren
[ ] 4.02  Handschrift-Erkennung: Buchstaben (A–Z, ä/ö/ü/ß) integrieren
[ ] 4.03  Handwriting-Pad Widget mit Strich-Anzeige + Erkennung
[ ] 4.04  PDF-Service: Arbeitsblatt-Generator (Aufgaben → PDF)
[ ] 4.05  PDF-Service: Lösungsblatt-Generator
[ ] 4.06  PDF-Service: Deckblatt mit Fach/Klasse/Datum
[ ] 4.07  Eltern-Dashboard: PIN-Setup beim ersten Zugriff
[ ] 4.08  Eltern-Dashboard: Übersicht Fehlerquote pro Thema (Balkendiagramm)
[ ] 4.09  Eltern-Dashboard: Zeitlicher Verlauf (Liniengrafik)
[ ] 4.10  Eltern-Dashboard: Empfehlungen ("Übe noch: Division mit Rest")
[ ] 4.11  Eltern-Dashboard: Export Lernbericht als PDF
[ ] 4.12  TTS Vorlesefunktion für alle Aufgabenstellungen (on-device)
[ ] 4.13  Sound-Effekte: Richtig/Falsch/Sterne-Sammeln/Level-Up
[ ] 4.14  Belohnungssystem: Sterne pro Übung, Pokale pro Thema
[ ] 4.15  Belohnungssystem: Sammelbilder/Sticker als Motivation (kein Echtgeld)
[ ] 4.16  Multi-Profil: Bis zu 4 Kinder-Profile auf einem Gerät
[ ] 4.17  Accessibility: Schriftgröße anpassbar, hoher Kontrast, Screenreader
```

### Phase 5: Polishing & Store-Vorbereitung (Wochen 17–20)

```
[ ] 5.01  UI-Review: Alle Screens auf Konsistenz prüfen
[ ] 5.02  Farb-Themes pro Klassenstufe finalisieren
[ ] 5.03  Lottie/Rive Animationen: Belohnungs-Animationen erstellen
[ ] 5.04  App-Icon: Fuchs-Maskottchen in verschiedenen Auflösungen
[ ] 5.05  Splash Screen + Onboarding (3 Screens: Klasse → Bundesland → Los)
[ ] 5.06  Integration Tests: Kompletter User-Flow pro Klassenstufe
[ ] 5.07  Performance: App-Start < 2s, Aufgabenwechsel < 200ms
[ ] 5.08  APK/IPA-Größe optimieren (< 50 MB, Assets lazy laden)
[ ] 5.09  Android: Signing-Konfiguration (Keystore)
[ ] 5.10  iOS: Provisioning Profile + App Store Connect Setup
[ ] 5.11  Store-Listings: Screenshots (Deutsch), Beschreibung, Keywords
[ ] 5.12  Store-Listings: Feature Graphic (Android) / Preview Video (iOS)
[ ] 5.13  Datenschutzerklärung: "Diese App erhebt keine Daten" (DSGVO-konform)
[ ] 5.14  Altersfreigabe: USK/IARC für 4+ (keine Gewalt, keine Käufe)
[ ] 5.15  Beta-Test: TestFlight (iOS) + Internal Testing (Android)
[ ] 5.16  Beta-Feedback einarbeiten
[ ] 5.17  Release Build Android (AAB) + iOS (IPA)
[ ] 5.18  Store-Einreichung Google Play + Apple App Store
[ ] 5.19  Landing Page: lernfuchs.app (One-Pager mit Store-Links)
[ ] 5.20  Pressemitteilung / Eltern-Blogs kontaktieren
```

### Phase 6: Post-Launch (Woche 21+)

```
[ ] 6.01  Store-Reviews monitoren + auf Feedback reagieren
[ ] 6.02  Bugfixes basierend auf Reviews
[ ] 6.03  Content-Update: Sachkunde als drittes Fach (kostenlos oder IAP)
[ ] 6.04  Content-Update: Englisch-Grundwortschatz (optionaler IAP)
[ ] 6.05  Saisonale Aufgaben-Sets (Weihnachten, Ostern, Sommerferien)
[ ] 6.06  ASO-Optimierung (Keywords, Screenshots, A/B-Test Listings)
[ ] 6.07  Marketing: Instagram/TikTok Eltern-Community aufbauen
[ ] 6.08  Marketing: Lehrer-Blogs + Grundschul-Foren bespielen
[ ] 6.09  Evaluierung: Tablet-optimierte Version (iPad/Android-Tablet)
[ ] 6.10  Evaluierung: Lehrerversion mit Klassenlizenzen (B2B)
```

---

## 6. CLI-Tool Spezifikation

Das CLI-Tool `lernfuchs-cli` steuert den Entwicklungsprozess:

```bash
# Setup
lernfuchs-cli init                    # Erstellt Projekt-Struktur
lernfuchs-cli todo                    # Zeigt alle offenen Tasks
lernfuchs-cli todo --phase 2          # Nur Phase 2
lernfuchs-cli todo --next             # Nächster Task

# Task-Management  
lernfuchs-cli done 1.01               # Markiert Task als erledigt
lernfuchs-cli done 1.01 --note "..."  # Mit Notiz
lernfuchs-cli progress                # Zeigt Fortschritt pro Phase
lernfuchs-cli blocked 2.11 "..."      # Markiert Task als blockiert

# Code-Generierung
lernfuchs-cli gen:template addition   # Generiert Aufgaben-Template Boilerplate
lernfuchs-cli gen:widget clock        # Generiert Widget Boilerplate
lernfuchs-cli gen:test 2.03           # Generiert Test-Datei für Task

# Build & Deploy
lernfuchs-cli build android           # Flutter build appbundle
lernfuchs-cli build ios               # Flutter build ipa
lernfuchs-cli test                    # Alle Tests ausführen
lernfuchs-cli lint                    # Dart analyze + custom rules
```

### Datenformat für Tasks (todo.yaml)

```yaml
phases:
  - id: 1
    name: "Fundament"
    weeks: "1-4"
    tasks:
      - id: "1.01"
        title: "Flutter-Projekt initialisieren"
        status: "open"  # open | done | blocked
        done_at: null
        note: null
        depends_on: []
      - id: "1.02"
        title: "Projekt-Struktur anlegen"
        status: "open"
        depends_on: ["1.01"]
```

---

## 7. Risiken & Mitigationsstrategien

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| ANTON bleibt dominanter Platzhirsch | Hoch | Mittel | Differenzierung über Offline-First + Einmalkauf + kein Tracking |
| Handschrifterkennung zu ungenau | Mittel | Hoch | Fallback auf Nummernpad/Tastatur, Handschrift als "Beta"-Feature |
| App Store Rejection (Apple) | Niedrig | Hoch | Frühzeitig App Review Guidelines studieren, keine 4.3-Probleme |
| Zu wenig Downloads bei Launch | Mittel | Mittel | ASO-Fokus, Eltern-Blog-Kooperationen, kostenlose Lite-Version erwägen |
| Lehrplan-Änderungen | Niedrig | Niedrig | Modulares Curriculum-System, einfach anpassbar |

---

## 8. Budget-Schätzung (Solo-Entwickler)

| Posten | Kosten |
|--------|--------|
| Apple Developer Account | 99 €/Jahr |
| Google Play Developer | 25 € (einmalig) |
| Domain lernfuchs.app | ~15 €/Jahr |
| Rive/Lottie Animationen | 0 € (Community) oder ~200 € |
| Sound-Effekte | 0 € (freesound.org) oder ~50 € |
| TFLite Handschrift-Modell | 0 € (Open Source: IAM/MNIST) |
| Marketing (optional) | 200–500 € für erste Ads |
| **Gesamt Year 1** | **~400–900 €** |

Bei 12,99 € Verkaufspreis und 70% Store-Anteil = **~9,09 € Netto pro Verkauf**.  
Break-Even bei ~100 Verkäufen. Realistisch erreichbar.

---

## 9. Zusammenfassung

**LernFuchs** positioniert sich in einer echten Marktlücke: Die einzige Grundschul-App für Mathe und Deutsch, die Einmalkauf + 100% Offline + Null Tracking + algorithmische Aufgabengenerierung + druckbare Arbeitsblätter kombiniert.

Die größten Wettbewerbsvorteile gegenüber ANTON (dem Platzhirsch):
1. Kein Abo nötig — Eltern zahlen einmal
2. Kein Internet nötig — funktioniert überall
3. Kein Account nötig — null Hürde, null Daten
4. Nie dieselbe Aufgabe — algorithmisch generiert
5. PDF-Arbeitsblätter — Bridge zwischen digital und analog

Der DACH-Markt mit ~3,6 Mio. Grundschulkindern bietet genügend Volumen. Das Conni-Beispiel zeigt, dass Einmalkauf-Apps für 4–10 € im Grundschulbereich funktionieren.

**Zeitrahmen:** 20 Wochen bis MVP-Launch bei Vollzeit-Entwicklung.
