# World 1 Vertical Slice

World 1 is the first complete playable slice of the hybrid Flutter + Flame app.
It stays intentionally small: one map, chapter-1 and chapter-2 quest links,
one mentor, and local profile rewards only.

## Playable Flow

Der vollständige Happy Path ist implementiert und durch Integrationstests abgesichert:
**Weltkarte -> Quest starten -> Lernchallenge -> RewardOverlay -> Rückkehr -> sichtbarer Fortschritt im Baumhaus.**

- Baumhaus hub: `/home/baumhaus`, liest Upgrades/Items direkt aus dem `InventoryStore`.
- Flüsterwald map: geöffnet aus dem Dashboard über die klickbare Abenteuer-Kachel.
- Kapitel-1-Arcs:
  - `chapter1_ovas_ruf`: Deutsch `buchstaben`, schaltet `baumhaus_laterne` frei.
  - `chapter1_zahlenpfad`: Mathe `zahlen_bis_10`, vergibt kleine Sternensamen.
  - `chapter1_singende_blaetter`: Deutsch `silben`, schaltet `baumhaus_kristall_blau` frei.
  - `chapter1_erste_lichtung`: Mathe `zahlen_bis_20`, schaltet `baumhaus_bank` frei.
- Kapitel-2-Arcs:
  - `chapter2_alter_baum`: Mathe `addition_bis_10`, vergibt kleine Sternensamen.
  - `chapter2_nebelbruecke`: Mathe `subtraktion_bis_10`, vergibt kleine Sternensamen.
  - `chapter2_mauer_der_funken`: Mathe `zahlenmauern`, vergibt kleine Sternensamen.
  - `chapter2_wegweiser_aus_klang`: Deutsch `reimwoerter` und `lueckenwoerter`, vergibt kleine Sternensamen.

Curriculum-Hinweis: Kapitel 1 nutzt nur aktuell registrierte Klasse-1-Templates
aus der bestehenden Curriculum-Reihenfolge. `woerter_lesen` wird uebersprungen,
weil dafuer im aktuellen Generator kein belastbares Template registriert ist;
spaetere Fallback-Themen wie `reimwoerter`, `lueckenwoerter`, `formen`,
`zahlenreihen` oder `muster` bleiben fuer Folgekapitel frei.

## Klasse-1-Fachplanung

World 1 bleibt als Klasse-1-Welt curricular aufgebaut. Die Reihenfolge ist kein
bundesweit verbindlicher Lehrplan, sondern eine vorsichtige LernFuchs-Sequenz,
die an typische Anfangsunterrichts-Progressionen anschliesst und ueber
Bundesland-Varianten nur dann enger wird, wenn das System sie wirklich abbildet.

### Mathe Klasse 1

- Mengen und Zahlen: Zahlen bis 10, Zahlen bis 20, Zehnerfeld,
  Zwanzigerfeld, strukturierte Mengenerfassung statt nur Einzelzaehlen.
- Zahlbeziehungen: Zahlzerlegung, Nachbarzahlen, groesser/kleiner/gleich,
  Zahlenstrahl und flexibles Vorwaerts-/Rueckwaertszaehlen.
- Operationen: Addition und Subtraktion im kleinen Zahlenraum, Tauschaufgaben,
  Umkehraufgaben, Nachbaraufgaben und Rechnen in Schritten.
- Vertiefungsformate: `zahlenmauern` als klasse-1-faehiges Format nach den
  ersten Zahl- und Rechenbasics; in Kapitel 1 noch nicht als Pflichtkern.
- Anwendung und Struktur: einfache Rechengeschichten/Sachsituationen, einfache
  kombinatorische Aufgaben, Muster, Formen, Raumorientierung und
  Lagebeziehungen.

### Deutsch Klasse 1

- Schriftspracherwerb: Buchstaben, Anlaute, Lautsynthese, Silben und Reime.
- Lautliche Einheiten: Buchstabenverbindungen und haeufige Lautgruppen wie
  `sch`, `ch`, `ie`, `ei`, `au` und `eu`, jeweils nur mit passenden Wortlisten.
- Lesen: Sichtwortschatz/Blitzlesen, kurze lauttreue Woerter und
  Bild-Wort-Zuordnung, sobald das Generator-/Template-Angebot belastbar ist.
- Schreiben: lauttreue Woerter mit silbischem Mitsprechen, Abschreiben mit
  Fehlervergleich, kurze freie Schreibimpulse.
- Satzvorbereitung: Satzgrenzen, Satzschlusszeichen und das Alphabet als
  Ordnungs- und Nachschlagehilfe.

## Kapitelplanung

Die produktiven Quest-/Dialogdaten bilden derzeit Kapitel 1 und Kapitel 2 des
Fluesterwalds ab. Die folgende 3-Kapitel-Verteilung ist der kanonische
World-1-Rahmen und trennt bewusst zwischen aktuell spielbarer Slice,
angelegten Topics/Templates und Konzeptbausteinen.

### Kapitel 1: Fruehe Grundlagen

- Fachliche Zielthemen: `buchstaben`, `anlaute`, `zahlen_bis_10`, `silben`,
  `zahlen_bis_20`.
- Aktuell als Topics/Templates angelegt: `buchstaben`, `anlaute`,
  `zahlen_bis_10`, `silben`, `zahlen_bis_20`.
- Aktuell in der Kapitel-1-Quest-Slice genutzt: `buchstaben`, `zahlen_bis_10`,
  `silben`, `zahlen_bis_20`; `anlaute` ist im Themenkatalog angelegt, aber
  noch nicht als eigener Kapitel-1-Questschritt ausgespielt.

### Kapitel 2: Erste Vertiefung

- Fachliche Zielthemen: `addition_bis_10`, `subtraktion_bis_10`,
  `zahlenmauern`, `reimwoerter`, `lueckenwoerter`, Lautsynthese,
  Sichtwortschatz und erste lauttreue Woerter.
- Aktuell als Topics/Templates angelegt: `addition_bis_10`,
  `subtraktion_bis_10`, `zahlenmauern`, `reimwoerter`, `lueckenwoerter`.
- Aktuell in der Kapitel-2-Quest-Slice genutzt: `addition_bis_10`,
  `subtraktion_bis_10`, `zahlenmauern`, `reimwoerter`, `lueckenwoerter`.
- Konzept-/Planungsstand: Lautsynthese, Sichtwortschatz/Blitzlesen und erste
  lauttreue Woerter brauchen noch belastbare Templates, Wortlisten und UI.
- `zahlenmauern` sind hier bewusst als klasse-1-faehiges Vertiefungsthema
  verankert, nicht als Grundlagenstoff in Kapitel 1.

#### Kapitel 2 Quest-Arc-Planung

Diese vier Arcs sind als Questdaten in `assets/quests/sample_quests.json`
angelegt und ueber die bestehende lineare Weltkarten-Freischaltung erreichbar.
Die Reihenfolge bleibt bewusst leicht: erst Rechnen bis 10, dann
`zahlenmauern` als Strukturformat, danach Deutsch-Vertiefung.

| Quest | Storyfunktion | Lernfokus | Bereits anschliessbar | Konzept-/Planungsstand | Reward und sichtbarer Fortschritt |
|-------|---------------|-----------|-----------------------|-------------------------|-----------------------------------|
| Quest 6: Der alte Baum | Fino und Ova kehren zum alten Baum zurueck. Die Jahresringe leuchten in Paaren und zeigen, dass zwei kleine Mengen zusammen ein neues Licht ergeben. | `addition_bis_10`, erste Tausch- und Nachbaraufgaben als sanfte Strategie-Sprache. | `addition_bis_10` ist als Klasse-1-Topic/Template angelegt. | Explizite Strategie-UI fuer Tausch-/Nachbaraufgaben bleibt Planung; vorerst nur dialogisch/konzeptionell. | Kleine Sternensamen; am Baum leuchten neue Jahresringe, im Baumhaus kann ein kleiner Notizzettel/Blattfund geplant werden. |
| Quest 7: Die Nebelbruecke | Auf einer freundlichen Bruecke fehlen einzelne Lichtplanken. Fino nimmt Nebelplanken weg und sieht, was uebrig bleibt. | `subtraktion_bis_10`, Umkehraufgaben als Verbindung zu Addition. | `subtraktion_bis_10` ist als Klasse-1-Topic/Template angelegt. | Explizite Umkehraufgaben-Logik und Bruecken-Visualisierung bleiben Planung. | Sternensamen oder kleiner Kartenfortschritt; die Bruecke wird klarer und verbindet Kapitel 2 sichtbar mit tieferen Waldwegen. |
| Quest 8: Die Mauer der Funken | Kleine Funkensteine stapeln sich zu einer freundlichen Zahlenmauer. Jede obere Flamme entsteht aus zwei unteren Steinen. | `zahlenmauern` als Vertiefung fuer Zahlzerlegung, Zahlbeziehungen und Rechnen im kleinen Zahlenraum. | `zahlenmauern` ist als Klasse-1-faehiges Topic/Template angelegt. | Feineres Klasse-1-Scaffolding fuer Zahlzerlegung, Zehnerfeld-Bezug und Fehlerhilfen bleibt Planung. | Kleines Baumhaus-/Welt-Upgrade, z.B. ein Funkenglas als geplantes Deko-Element; die Mauer oeffnet einen helleren Seitenpfad. |
| Quest 9: Die Wegweiser aus Klang | Klangwegweiser summen kurze Woerter. Ova gibt weniger vor und laesst Fino Laute verbinden, Reime finden und fehlende Buchstaben ergaenzen. | `reimwoerter`, `lueckenwoerter`, Lautsynthese, Sichtwortschatz/Blitzlesen, erste lauttreue Woerter. | `reimwoerter` und `lueckenwoerter` sind als Klasse-1-Topics/Templates angelegt. | Lautsynthese, Sichtwortschatz/Blitzlesen und erste lauttreue Woerter brauchen noch belastbare Templates, Wortlisten und UI. | Sternensamen oder ein kleiner Klang-Anhaenger als geplantes Baumhaus-/Story-Detail; Wegweiser klingen klarer und bereiten Kapitel 3 vor. |

Tonalitaet: Kapitel 2 fuehlt sich tiefer und strukturierter an als Kapitel 1,
bleibt aber warm. Nebel bedeutet weiterhin nur verschwommene Zeichen,
vergessene Wege oder wiederkehrendes Wissen. Ova begleitet etwas zurueckhaltender:
Sie erinnert an Strategien, statt jeden Schritt direkt vorzusagen.

### Kapitel 3: Transfer und Struktur

- Fachliche Zielthemen: `formen`, `zahlenreihen`, `muster`, `handschrift`,
  `buchstaben_salat`, Raumorientierung/Lagebeziehungen,
  Zahlenstrahl/Nachbarzahlen, Buchstabenverbindungen, Satzgrenzen und kleine
  Schreibimpulse.
- Aktuell als Topics/Templates angelegt: `formen`, `zahlenreihen`, `muster`,
  `handschrift`, `buchstaben_salat`.
- Konzept-/Planungsstand: Raumorientierung/Lagebeziehungen,
  Zahlenstrahl/Nachbarzahlen als eigenes Format, Buchstabenverbindungen,
  Satzgrenzen/Satzschlusszeichen und kleine Schreibimpulse.

### Status Matrix

| Bereich | Bereits angelegt | Konzept/Planung | Technisch fehlt |
|---------|------------------|-----------------|-----------------|
| Mathe K1 | `zahlen_bis_10`, `zahlen_bis_20`, `addition_bis_10`, `subtraktion_bis_10`, `groesser_kleiner`, `zahlenmauern`, `formen`, `zahlenreihen`, `muster` | Zehner-/Zwanzigerfeld als didaktische Darstellung, Zahlzerlegung, Rechenstrategien, Rechengeschichten, Kombinatorik, Raumorientierung | eigene Templates/UI fuer Rechengeschichten, Kombinatorik, Raumorientierung und expliziten Zahlenstrahl |
| Deutsch K1 | `buchstaben`, `anlaute`, `silben`, `reimwoerter`, `lueckenwoerter`, `buchstaben_salat`, `handschrift` | Lautsynthese, Sichtwortschatz/Blitzlesen, lauttreue Woerter, Buchstabenverbindungen, Abschreiben/Fehlervergleich, Satzgrenzen, Schreibimpulse, Alphabet-Arbeit | belastbares `woerter_lesen`/Blitzlesen, Lautsynthese-Template, Schreib- und Satzgrenzen-Templates, gepruefte Wortlisten |

Jede Quest nutzt den validierten Flow:
- Lokale Dialogszene via `QuestIntroScreen`
- `ForestQuestOverlay` (Challenge-Länge dynamisch aus Quest-Daten)
- Belohnungsanzeige via `QuestRewardOverlay`
- Idempotente Belohnungsvergabe via `QuestRuntime` an den `InventoryStore`.

## Placeholder Assets

- Flame map background: Handgezeichnete Canvas-Shapes.
- Quest nodes: Interaktive Komponenten mit Status-Visualisierung (locked/current/completed).
- Player character: `WorldMapFinoComponent` mit Laufanimationen und Trail-Effekten.
- Baumhaus: Detaillierte Visualisierung via `BaumhausPainter` mit Unterstützung für diverse Upgrades und Wachstumsstufen.

## Systems Proven

- Flutter remains responsible for hub UI, overlays, rewards, and normal routes.
- Flame remains limited to the interactive world-map layer.
- Quest definitions are local JSON assets.
- Dialogue and hints are local JSON assets.
- Learning challenges reuse existing generator/evaluator/progress recording.
- Quest rewards update profile-local inventory without backend, telemetry, or
  store logic.
