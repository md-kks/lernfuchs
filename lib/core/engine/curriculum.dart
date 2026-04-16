/// Lehrplan-Mapping pro Bundesland.
/// Steuert welche Themen in welcher Reihenfolge erscheinen
/// und welche Varianten gelehrt werden (z.B. Schreibschrift vs. Druckschrift).
class Curriculum {
  final String federalState;

  const Curriculum(this.federalState);

  /// Schreibschrift-Variante: Einige Länder lehren SAS früher als andere
  bool get teachesCursiveEarly => const ['BY', 'BW', 'RP'].contains(federalState);

  /// Zeitpunkt Einmaleins: Die meisten ab Kl.2, einige ab Kl.3
  int get timestablesGrade => const ['SH', 'MV'].contains(federalState) ? 3 : 2;

  /// Themenreihenfolge Mathe pro Klasse
  List<String> mathTopics(int grade) => switch (grade) {
        1 => [
            'zahlen_bis_10',
            'zahlen_bis_20',
            'addition_bis_10',
            'subtraktion_bis_10',
            'groesser_kleiner',
            'zahlenmauern',
            'formen',
            'zahlenreihen',
            'muster',
          ],
        2 => [
            'addition_bis_100',
            'subtraktion_bis_100',
            'einmaleins',
            'uhrzeit',
            'geld',
            'zahlenmauern',
            'rechenketten',
            'textaufgaben',
          ],
        3 => [
            'schriftliche_addition',
            'schriftliche_subtraktion',
            'multiplikation',
            'division_mit_rest',
            'groessen_umrechnen',
            'geometrie',
            'textaufgaben_3',
          ],
        4 => [
            'schriftliche_multiplikation',
            'schriftliche_division',
            'brueche',
            'dezimalzahlen',
            'diagramme',
            'grosse_zahlen',
            'sachaufgaben_4',
          ],
        _ => [],
      };

  /// Themenreihenfolge Deutsch pro Klasse
  List<String> germanTopics(int grade) => switch (grade) {
        1 => [
            'buchstaben',
            'anlaute',
            'silben',
            'woerter_lesen',
            'reimwoerter',
            'lueckenwoerter',
            'buchstaben_salat',
            'handschrift',
          ],
        2 => [
            'artikel',
            'wortarten',
            'einzahl_mehrzahl',
            'rechtschreibung_ie_ei',
            'abc_sortieren',
            'saetze_bilden',
            'lesetext',
          ],
        3 => [
            'zeitformen',
            'wortfamilien',
            'zusammengesetzte_nomen',
            'satzarten',
            'diktat',
            'lernwoerter',
          ],
        4 => [
            'vier_faelle',
            'satzglieder',
            'das_dass',
            'woertliche_rede',
            'fehlertext',
            'kommasetzung',
            'textarten',
          ],
        _ => [],
      };
}

/// Alle verfügbaren Bundesländer
const kFederalStates = [
  ('BY', 'Bayern'),
  ('BW', 'Baden-Württemberg'),
  ('NW', 'Nordrhein-Westfalen'),
  ('NI', 'Niedersachsen'),
  ('HE', 'Hessen'),
  ('SN', 'Sachsen'),
  ('ST', 'Sachsen-Anhalt'),
  ('TH', 'Thüringen'),
  ('BB', 'Brandenburg'),
  ('MV', 'Mecklenburg-Vorpommern'),
  ('SH', 'Schleswig-Holstein'),
  ('HH', 'Hamburg'),
  ('BE', 'Berlin'),
  ('HB', 'Bremen'),
  ('SL', 'Saarland'),
  ('RP', 'Rheinland-Pfalz'),
  ('AT', 'Österreich'),
  ('CH', 'Schweiz'),
];
