import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../workout/guide_controller.dart';
import '../../activity/recorder.dart';
import '../../health/health_sync.dart';
import '../../core/distribution.dart';
import '../../updates/update_controller.dart';
import '../workout/session_clock.dart';
import '../exercises/body3d/body_model.dart';
import '../exercises/library/library.dart';

class _Tab {
  const _Tab(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _tabs = [
  _Tab('Home', LucideIcons.house),
  _Tab('Workout', LucideIcons.dumbbell),
  _Tab('Meal', LucideIcons.utensils),
  _Tab('Analytics', LucideIcons.chartNoAxesColumn),
  _Tab('Me', LucideIcons.userRound),
];

/// Loads the exercise list, the food list, and the body map's mesh once
/// the first frame is on screen, so Exercises, Add food, and the body map
/// open at once instead of with a spinner. A failure here is ignored: each
/// screen shows its own error if it still cannot load.
final warmUpProvider = FutureProvider<void>((ref) async {
  await SchedulerBinding.instance.endOfFrame;
  try {
    await Future.wait([ref.watch(libraryProvider.future), ref.watch(foodLibraryProvider.future), BodyMesh.load()]);
  } catch (_) {}
});

/// Five persistent tabs. Each tab keeps its own navigation and scroll state.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveSessionProvider).value;
    ref.watch(warmUpProvider);
    // Health write-back runs only while a write feature is on (D-020).
    if (ref.watch(currentSettingsProvider).health.any((h) => h.startsWith('write'))) ref.watch(healthSyncProvider);
    // The once-a-day update check (D-029). It only reads release data.
    // Google Play delivers its own updates (handbook 17.10).
    if (!playBuild) ref.watch(autoUpdateCheckProvider);
    // The guided workout ticks while a workout is live (handbook 4.13).
    if (live != null) ref.read(guideProvider.notifier).attach();
    // A run, walk, or ride that was recording when the app closed goes on
    // (handbook 4.14).
    final activity = ref.watch(liveActivityProvider).value;
    if (activity != null) {
      // After the frame: starting GPS changes the recorder's state, which
      // must not happen while the tree builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(ref.read(recorderProvider.notifier).attach(activity));
      });
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live != null && shell.currentIndex > 1)
            _LiveBar(sessionId: live.id, paused: live.status == SessionStatus.paused),
          _TabBar(
            index: shell.currentIndex,
            onSelect: (i) {
              // A message belongs to the screen it came from.
              if (i != shell.currentIndex) ScaffoldMessenger.of(context).hideCurrentSnackBar();
              shell.goBranch(i, initialLocation: i == shell.currentIndex);
            },
          ),
        ],
      ),
    );
  }
}

/// Persistent control that returns the user to the active workout.
class _LiveBar extends StatelessWidget {
  const _LiveBar({required this.sessionId, required this.paused});
  final String sessionId;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
      child: Material(
        color: p.panel,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => context.push('/live/$sessionId'),
          child: Semantics(
            button: true,
            label: paused ? 'Workout paused. Continue workout' : 'Workout in progress. Continue workout',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.l, Space.s),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: p.energy, shape: BoxShape.circle),
                    child: Icon(paused ? LucideIcons.pause : LucideIcons.dumbbell, color: p.onEnergy, size: 18),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Text(
                      paused ? 'Paused' : 'Training',
                      style: t.labelLarge?.copyWith(color: p.onPanel),
                    ),
                  ),
                  SessionClock(
                    sessionId: sessionId,
                    style: t.titleMedium!.tabular.copyWith(color: p.energy),
                  ),
                  const SizedBox(width: Space.s),
                  Icon(LucideIcons.chevronRight, color: p.onPanelSoft, size: IconSizes.s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS-style tab bar: a thin top line, tinted icon and label for the
/// selected tab, no pill and no ripple. Labels always show.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final duration = motionOf(context, Motion.quick);
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: p.brightness == Brightness.dark ? 0.85 : 0.92),
            border: Border(top: BorderSide(color: p.line, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    for (final (i, tab) in _tabs.indexed)
                      Expanded(
                        child: Semantics(
                          selected: i == index,
                          button: true,
                          label: '${tab.label}, tab ${i + 1} of ${_tabs.length}',
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (i != index) HapticFeedback.selectionClick();
                              onSelect(i);
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 50),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<Color?>(
                                    duration: duration,
                                    tween: ColorTween(end: i == index ? p.brand : p.inkSoft),
                                    builder: (_, c, _) => Icon(tab.icon, size: 25, color: c),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tab.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.labelSmall?.copyWith(
                                      fontSize: 11,
                                      color: i == index ? p.brand : p.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
