import '../engine/elo_difficulty_engine.dart';

/// Lernfortschritt eines Kindes für ein einzelnes Thema.
///
/// Wird dauerhaft in [StorageService] (SharedPreferences) gespeichert.
/// Der eindeutige Speicher-Schlüssel ist [key].
///
/// ### Gleitendes Fenster
/// [recentResults] speichert die letzten 20 Ergebnisse als `1` (richtig)
/// oder `0` (falsch). Dieses Fenster nutzt der [DifficultyEngine] um den
/// nächsten Schwierigkeitsgrad zu berechnen.
class TopicProgress {
  /// ID des Kinderprofils, dem dieser Fortschritt gehört.
  final String profileId;

  /// Fach-ID (`"math"` oder `"german"`).
  final String subject;

  /// Klassenstufe 1–4.
  final int grade;

  /// Themenbezeichner, z.B. `"zeitformen"`.
  final String topic;

  /// Gesamtanzahl aller beantworteten Aufgaben.
  int totalAttempts;

  /// Anzahl der korrekt beantworteten Aufgaben.
  int correctAttempts;

  /// Aktuelles Elo-Rating für dieses Thema.
  double eloRating;

  /// Zeitstempel der letzten Übungssession.
  DateTime lastPracticed;

  /// Letzte 20 Ergebnisse: `1` = richtig, `0` = falsch.
  /// Wird auf max. 20 Einträge begrenzt (älteste fallen heraus).
  List<int> recentResults;

  TopicProgress({
    required this.profileId,
    required this.subject,
    required this.grade,
    required this.topic,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.eloRating = 1000.0,
    required this.lastPracticed,
    List<int>? recentResults,
  }) : recentResults = recentResults ?? [];

  /// Gesamtgenauigkeit als Wert zwischen 0.0 und 1.0.
  /// Gibt 0 zurück, wenn noch keine Aufgaben beantwortet wurden.
  double get accuracy =>
      totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;

  /// Zusammengesetzter Schlüssel für SharedPreferences.
  /// Format: `"<profileId>-<subject>-<grade>-<topic>"`.
  String get key => '$profileId-$subject-$grade-$topic';

  /// Registriert ein neues Ergebnis und aktualisiert alle Felder.
  /// Hält [recentResults] auf maximal 20 Einträge.
  void recordResult(bool correct, {int? difficulty}) {
    totalAttempts++;
    if (correct) correctAttempts++;
    recentResults.add(correct ? 1 : 0);
    if (recentResults.length > 20) recentResults.removeAt(0);

    if (difficulty != null) {
      eloRating = EloDifficultyEngine.calculateNewRating(
        currentRating: eloRating,
        taskDifficulty: difficulty,
        success: correct,
      );
    }

    lastPracticed = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'subject': subject,
        'grade': grade,
        'topic': topic,
        'totalAttempts': totalAttempts,
        'correctAttempts': correctAttempts,
        'eloRating': eloRating,
        'lastPracticed': lastPracticed.toIso8601String(),
        'recentResults': recentResults,
      };

  factory TopicProgress.fromJson(Map<String, dynamic> json) => TopicProgress(
        profileId: json['profileId'] as String,
        subject: json['subject'] as String,
        grade: json['grade'] as int,
        topic: json['topic'] as String,
        totalAttempts: json['totalAttempts'] as int? ?? 0,
        correctAttempts: json['correctAttempts'] as int? ?? 0,
        eloRating: (json['eloRating'] as num? ?? 1000.0).toDouble(),
        lastPracticed: DateTime.parse(json['lastPracticed'] as String),
        recentResults: (json['recentResults'] as List?)?.cast<int>() ?? [],
      );
}

/// Kinderprofil — ein Gerät kann mehrere Profile führen (z.B. Geschwister).
///
/// Das aktive Profil wird in [AppSettings.activeProfileId] gespeichert.
/// Sternpunkte ([totalStars]) werden bei jeder abgeschlossenen Session addiert.
class ChildProfile {
  /// Eindeutige UUID des Profils.
  final String id;

  /// Anzeigename des Kindes.
  String name;

  /// Aktuelle Klassenstufe 1–4.
  int grade;

  /// Emoji-Avatar (Standard: 🦊 = Fuchs, das Maskottchen).
  String avatarEmoji;

  /// Kumulierte Gesamtpunktzahl (Sterne) über alle Themen und Sessions.
  int totalStars;

  /// Erstellungsdatum des Profils.
  DateTime createdAt;

  ChildProfile({
    required this.id,
    required this.name,
    required this.grade,
    this.avatarEmoji = '🦊',
    this.totalStars = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'avatarEmoji': avatarEmoji,
        'totalStars': totalStars,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        grade: json['grade'] as int,
        avatarEmoji: json['avatarEmoji'] as String? ?? '🦊',
        totalStars: json['totalStars'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
