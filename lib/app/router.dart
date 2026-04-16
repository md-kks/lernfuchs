import 'package:go_router/go_router.dart';
import '../features/baumhaus/baumhaus_screen.dart';
import '../features/home/daily_path_screen.dart';
import '../features/home/free_practice_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/shell_placeholder_screen.dart';
import '../features/onboarding/child_onboarding_screen.dart';
import '../features/onboarding/parent_onboarding_screen.dart';
import '../features/onboarding/placement_screen.dart';
import '../features/subject_overview/subject_overview_screen.dart';
import '../features/exercise/exercise_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/worksheet/worksheet_screen.dart';
import '../features/parent/parent_dashboard_screen.dart';

/// Zentraler App-Router (go_router).
///
/// ### Startfluss
/// Die App startet dashboard-first immer direkt auf `/home`. Onboarding,
/// Abenteuer-Intro, Eltern-PIN-Vergabe und Placement bleiben als manuell
/// erreichbare Routen erhalten, blockieren den App-Start aber nicht.
///
/// ### Routen-Übersicht
/// | Pfad                                           | Screen                     |
/// |------------------------------------------------|----------------------------|
/// | `/onboarding/parent`                           | [ParentOnboardingScreen]   |
/// | `/onboarding/child`                            | [ChildOnboardingScreen]    |
/// | `/onboarding/placement`                        | [PlacementScreen]          |
/// | `/home`                                        | [HomeScreen]               |
/// | `/home/freies-ueben`                           | [FreePracticeScreen]       |
/// | `/home/baumhaus`                               | [BaumhausScreen]           |
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
  routes: [
    GoRoute(path: '/onboarding', redirect: (_, _) => '/onboarding/child'),
    GoRoute(
      path: '/onboarding/parent',
      builder: (_, _) => const ParentOnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/child',
      builder: (_, _) => const ChildOnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/placement',
      builder: (_, _) => const PlacementScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, _) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'freies-ueben',
          builder: (_, _) => const FreePracticeScreen(),
        ),
        GoRoute(path: 'baumhaus', builder: (_, _) => const BaumhausScreen()),
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
