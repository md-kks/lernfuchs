import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';
import '../../shared/widgets/star_rating.dart';
import '../../shared/widgets/rounded_button.dart';
import 'exercise_screen.dart';

/// Ergebnis-Screen nach einer abgeschlossenen Übungssession.
///
/// Zeigt Trefferquote, Sterne und motivierende Nachricht an.
/// Verdiente Sterne ([stars]) werden einmalig zum [ChildProfile.totalStars]
/// des aktiven Profils addiert — dies geschieht in [initState] via
/// [StorageService.saveProfile].
///
/// ### Buttons
/// - **Nochmal üben**: Startet eine neue [ExerciseScreen]-Session mit denselben
///   Parametern (gleiche Klasse, Fach, Thema) via `Navigator.pushReplacement`.
/// - **Zurück zur Übersicht**: Navigiert zu [SubjectOverviewScreen] via go_router.
class ResultScreen extends ConsumerStatefulWidget {
  final int grade;
  final String subjectId;
  final String topic;
  final int correctCount;
  final int totalCount;

  const ResultScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.topic,
    required this.correctCount,
    required this.totalCount,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _awardStars();
  }

  /// Addiert die verdienten Sterne zum aktiven Kinderprofil.
  Future<void> _awardStars() async {
    final stars = StarRating.fromAccuracy(
        widget.correctCount / widget.totalCount);
    if (stars == 0) return;

    final storage = ref.read(storageServiceProvider);
    final profileId = ref.read(appSettingsProvider).activeProfileId;
    final profile = storage.getProfile(profileId);
    if (profile == null) return;

    profile.totalStars += stars;
    await storage.saveProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.correctCount / widget.totalCount;
    final stars = StarRating.fromAccuracy(accuracy);
    final colors = AppColors.forGrade(widget.grade);
    final percent = (accuracy * 100).round();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _emoji(stars),
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              Text(
                _headline(stars),
                style: AppTextStyles.displayMedium.copyWith(
                  color: colors.accent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              StarRating(stars: stars, size: 48),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.secondary, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.correctCount} von ${widget.totalCount} richtig',
                      style: AppTextStyles.headlineMedium,
                    ),
                    Text(
                      '$percent %',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    if (stars > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+$stars ⭐ verdient!',
                          style: TextStyle(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              RoundedButton(
                label: 'Nochmal üben',
                color: colors.primary,
                icon: Icons.refresh_rounded,
                width: double.infinity,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ExerciseScreen(
                      grade: widget.grade,
                      subjectId: widget.subjectId,
                      topic: widget.topic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RoundedButton(
                label: 'Zurück zur Übersicht',
                color: colors.secondary,
                textColor: colors.accent,
                icon: Icons.arrow_back_rounded,
                width: double.infinity,
                onPressed: () => context
                    .go('/home/subject/${widget.grade}/${widget.subjectId}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emoji(int stars) => switch (stars) {
        3 => '🏆',
        2 => '⭐',
        1 => '👍',
        _ => '💪',
      };

  String _headline(int stars) => switch (stars) {
        3 => 'Ausgezeichnet!',
        2 => 'Gut gemacht!',
        1 => 'Weiter üben!',
        _ => 'Nicht aufgeben!',
      };
}
