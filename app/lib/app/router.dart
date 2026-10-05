import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/analytics/source_records_screen.dart';
import '../features/exercises/guide_screen.dart';
import '../features/exercises/library_screen.dart';
import '../features/home/home_screen.dart';
import '../features/me/ai_connections_screen.dart';
import '../features/me/app_updates_screen.dart';
import '../features/me/data_screen.dart';
import '../features/me/me_screen.dart';
import '../features/me/privacy_screen.dart';
import '../features/meal/meal_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/workout/exercise_detail_screen.dart';
import '../features/workout/live_session_screen.dart';
import '../features/workout/plan_screen.dart';
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
                  path: 'plan/:id',
                  builder: (_, s) => PlanScreen(id: s.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'session/:id',
                  builder: (_, s) => SessionDetailScreen(id: s.pathParameters['id']!),
                ),
                GoRoute(path: 'library', builder: (_, _) => const LibraryScreen()),
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
                GoRoute(path: 'ai', builder: (_, _) => const AiConnectionsScreen()),
                GoRoute(path: 'updates', builder: (_, _) => const AppUpdatesScreen()),
                GoRoute(path: 'data', builder: (_, _) => const DataScreen()),
                GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen()),
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
  ],
);
