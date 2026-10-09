import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/analytics/source_records_screen.dart';
import '../features/exercises/catalog/model.dart';
import '../features/exercises/guide_screen.dart';
import '../features/exercises/library/move_browser.dart';
import '../features/exercises/library/move_screen.dart';
import '../features/exercises/library_screen.dart';
import '../features/exercises/rig/anatomy.dart';
import '../features/home/home_screen.dart';
import '../features/me/ai_connections_screen.dart';
import '../features/me/ai_file_screen.dart';
import '../features/me/app_updates_screen.dart';
import '../features/me/body_screen.dart';
import '../features/me/backup_screen.dart';
import '../features/me/gateway_setup_screen.dart';
import '../features/me/health_screen.dart';
import '../features/me/proposal_screen.dart';
import '../features/me/data_screen.dart';
import '../features/me/me_screen.dart';
import '../features/me/privacy_screen.dart';
import '../features/me/training_screen.dart';
import '../features/meal/meal_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/workout/calculator_screen.dart';
import '../features/workout/exercise_detail_screen.dart';
import '../features/workout/live_session_screen.dart';
import '../features/workout/plan_screen.dart';
import '../features/workout/roadmap_screens.dart';
import '../domain/roadmap.dart';
import '../features/workout/session_detail_screen.dart';
import '../features/workout/workout_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes. The five tabs are fixed by decision D-008.
GoRouter buildRouter({String initialLocation = '/home'}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workout',
              builder: (_, _) => const WorkoutScreen(),
              routes: [
                GoRoute(
                  path: 'session/:id',
                  builder: (_, s) => SessionDetailScreen(id: s.pathParameters['id']!),
                ),
                GoRoute(path: 'library', builder: (_, _) => const LibraryScreen()),
                GoRoute(path: 'calculator', builder: (_, _) => const CalculatorScreen()),
                GoRoute(
                  path: 'plan/new',
                  builder: (_, s) =>
                      RoadmapBuilderScreen(goal: RoadmapGoal.values.asNameMap()[s.uri.queryParameters['goal']]),
                ),
                GoRoute(
                  path: 'plan/:id',
                  builder: (_, s) => PlanScreen(id: s.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'plan/:id/day/:day',
                  builder: (_, s) => RoadmapDayScreen(
                    programId: s.pathParameters['id']!,
                    day: int.tryParse(s.pathParameters['day']!) ?? 0,
                  ),
                ),
                GoRoute(
                  path: 'area/:area',
                  builder: (_, s) => AreaScreen(
                    area: BodyArea.values.byName(s.pathParameters['area']!),
                    muscle: Muscle.values.asNameMap()[s.uri.queryParameters['muscle']],
                  ),
                ),
                GoRoute(
                  path: 'browse',
                  builder: (_, s) => BrowseScreen(area: BodyArea.values.asNameMap()[s.uri.queryParameters['area']]),
                ),
                GoRoute(
                  path: 'move/:id',
                  builder: (_, s) => MoveScreen(id: s.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'guide/:id',
                  builder: (_, s) => GuideScreen(id: s.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'exercise/:id',
                  builder: (_, s) => ExerciseDetailScreen(id: s.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/meal',
              builder: (_, s) => MealScreen(initialDay: s.uri.queryParameters['day']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (_, _) => const AnalyticsScreen(),
              routes: [
                GoRoute(
                  path: 'sources/:kind',
                  builder: (_, s) => SourceRecordsScreen(
                    kind: s.pathParameters['kind']!,
                    from: s.uri.queryParameters['from']!,
                    to: s.uri.queryParameters['to']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/me',
              builder: (_, _) => const MeScreen(),
              routes: [
                GoRoute(
                  path: 'ai',
                  builder: (_, _) => const AiConnectionsScreen(),
                  routes: [
                    GoRoute(path: 'setup', builder: (_, _) => const GatewaySetupScreen()),
                    GoRoute(path: 'file', builder: (_, _) => const AiFileScreen()),
                    GoRoute(
                      path: 'proposal/:id',
                      builder: (_, s) => ProposalScreen(id: s.pathParameters['id']!),
                    ),
                  ],
                ),
                GoRoute(path: 'health', builder: (_, _) => const HealthScreen()),
                GoRoute(path: 'backup', builder: (_, _) => const BackupScreen()),
                GoRoute(path: 'body', builder: (_, _) => const BodyScreen()),
                GoRoute(path: 'updates', builder: (_, _) => const AppUpdatesScreen()),
                GoRoute(path: 'data', builder: (_, _) => const DataScreen()),
                GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen()),
                GoRoute(path: 'training', builder: (_, _) => const TrainingScreen()),
              ],
            ),
          ],
        ),
      ],
    ),
    // The live workout is a focused full-screen flow without the tab bar.
    GoRoute(
      path: '/live/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, s) => MaterialPage(
        fullscreenDialog: true,
        child: LiveSessionScreen(id: s.pathParameters['id']!),
      ),
    ),
    // Guides opened from a workout. They sit above the live screen; pushing
    // a tab route from there would switch tabs and hide the guide.
    GoRoute(
      path: '/learn/guide/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, s) => GuideScreen(id: s.pathParameters['id']!, fromWorkout: true),
    ),
    GoRoute(
      path: '/learn/move/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, s) => MoveScreen(id: s.pathParameters['id']!, fromWorkout: true),
    ),
  ],
);
