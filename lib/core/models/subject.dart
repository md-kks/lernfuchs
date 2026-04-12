/// Verfügbare Schulfächer in der App.
///
/// Jedes Fach hat ein menschenlesbares [label] für die UI und
/// eine maschinenlesbare [id] für den Template-Registry-Schlüssel
/// (z.B. `"math_2_addition_bis_100"`).
enum Subject {
  math('Mathe', 'math'),
  german('Deutsch', 'german');

  /// Anzeigename in der UI (deutsch).
  final String label;

  /// Schlüssel-Bezeichner für den TaskGenerator und Persistenz.
  final String id;

  const Subject(this.label, this.id);
}
