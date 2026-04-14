class SchoolTopic {
  final String label;
  final List<String> competencyIds;

  const SchoolTopic(this.label, this.competencyIds);
}

const Map<int, List<SchoolTopic>> schoolTopicsByClass = {
  1: [
    SchoolTopic('Zahlen bis 20', ['zahlen_bis_10', 'zahlen_bis_20']),
    SchoolTopic('Einfache Addition', ['addition_bis_10', 'addition_bis_20']),
    SchoolTopic('Einfache Subtraktion', ['subtraktion_bis_10']),
    SchoolTopic('Buchstaben lernen', ['buchstaben']),
    SchoolTopic('Silben klatschen', ['silben']),
    SchoolTopic('Anlaute erkennen', ['anlaute']),
  ],
  2: [
    SchoolTopic('Zahlen bis 100', ['zahlen_bis_100']),
    SchoolTopic('Kleines Einmaleins', ['multiplikation_1x1']),
    SchoolTopic('Zehnerübergang', ['addition_zehnerubergang']),
    SchoolTopic('Wortarten', ['nomen', 'verben', 'adjektive']),
    SchoolTopic('Dehnungs-h', ['dehnung_h']),
  ],
  3: [
    SchoolTopic('Zahlen bis 1000', ['zahlen_bis_1000']),
    SchoolTopic('Halbschriftliches Rechnen', ['rechnen_halbschriftlich']),
    SchoolTopic('Längen und Gewichte', ['groessen_laenge', 'groessen_gewicht']),
    SchoolTopic('Satzzeichen', ['satzzeichen']),
    SchoolTopic('Zeitformen', ['zeitformen']),
  ],
  4: [
    SchoolTopic('Große Zahlen', ['zahlen_bis_million']),
    SchoolTopic('Schriftliche Division', ['division_schriftlich']),
    SchoolTopic('Die vier Fälle', ['kasus']),
    SchoolTopic('Rechtschreibung', ['rechtschreibung']),
    SchoolTopic('Sachaufgaben', ['sachaufgaben']),
  ],
};
