import 'package:go_router/go_router.dart';
import '../core/services/storage_service.dart';
import '../features/home/baumhaus_screen.dart';
import '../features/home/daily_path_screen.dart';
import '../features/home/free_practice_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/shell_placeholder_screen.dart';
import '../features/home/world_map_screen.dart';
import '../features/subject_overview/subject_overview_screen.dart';
import '../features/exercise/exercise_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/worksheet/worksheet_screen.dart';
import '../features/parent/parent_dashboard_screen.dart';

/// Zentraler App-Router (go_router).
///
/// ### Onboarding-Redirect
/// Solange [AppSettings.onboardingDone] `false` ist, leitet der `redirect`-
/// Callback jeden Navigationsversuch automatisch nach `/onboarding` um.
/// Ist Onboarding abgeschlossen, wird `null` zurückgegeben (kein Redirect).
///
/// ### Routen-Übersicht
/// | Pfad                                           | Screen                     |
/// |------------------------------------------------|----------------------------|
/// | `/onboarding`                                  | [OnboardingScreen]         |
/// | `/home`                                        | [HomeScreen]               |
/// | `/home/freies-ueben`                           | [FreePracticeScreen]       |
/// | `/home/baumhaus`                               | [BaumhausScreen]           |
/// | `/home/weltkarte`                              | [WorldMapScreen]           |
/// | `/home/tagespfad`                              | [DailyPathScreen]          |
/// | `/home/elternbereich`                          | [ShellPlaceholderScreen]   |
/// | `/home/subject/:grade/:subject`                | [SubjectOverviewScreen]    |
/// | `/home/subject/:grade/:subject/exercise/:topic`| [ExerciseScreen]           |
/// | `/progress`                                    | [ProgressScreen]           |
/// | `/settings`                                    | [SettingsScreen]           |
/// | `/profiles`                                    | [ProfileScreen]            |
/// | `/parent`                                      | [ParentDashboardScreen]    |
/// | `/worksheet/:grade/:subject/:topic`            | [WorksheetScreen]          |
final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final onboardingDone = StorageService.instance.settings.onboardingDone;
    final going = state.matchedLocation;
    if (!onboardingDone && going != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(
      path: '/home',
      builder: (_, _) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'freies-ueben',
          builder: (_, _) => const FreePracticeScreen(),
        ),
        GoRoute(path: 'baumhaus', builder: (_, _) => const BaumhausScreen()),
        GoRoute(path: 'weltkarte', builder: (_, _) => const WorldMapScreen()),
        GoRoute(path: 'tagespfad', builder: (_, _) => const DailyPathScreen()),
        GoRoute(
          path: 'elternbereich',
          builder: (_, _) =>
              const ShellPlaceholderScreen(title: 'Elternbereich'),
        ),
        GoRoute(
          path: 'subject/:grade/:subject',
          builder: (_, state) => SubjectOverviewScreen(
            grade: int.parse(state.pathParameters['grade']!),
            subjectId: state.pathParameters['subject']!,
          ),
          routes: [
            GoRoute(
              path: 'exercise/:topic',
              builder: (_, state) => ExerciseScreen(
                grade: int.parse(state.pathParameters['grade']!),
                subjectId: state.pathParameters['subject']!,
                topic: state.pathParameters['topic']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/profiles', builder: (_, _) => const ProfileScreen()),
    GoRoute(path: '/parent', builder: (_, _) => const ParentDashboardScreen()),
    GoRoute(
      path: '/worksheet/:grade/:subject/:topic',
      builder: (_, state) => WorksheetScreen(
        grade: int.parse(state.pathParameters['grade']!),
        subjectId: state.pathParameters['subject']!,
        topic: state.pathParameters['topic']!,
      ),
    ),
  ],
);
