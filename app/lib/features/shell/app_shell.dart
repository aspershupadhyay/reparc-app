import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../workout/session_clock.dart';

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

/// Five persistent tabs. Each tab keeps its own navigation and scroll state.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveSessionProvider).value;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live != null) _LiveBar(sessionId: live.id, paused: live.status == SessionStatus.paused),
          _TabBar(
            index: shell.currentIndex,
            onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
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
    return Material(
      color: AppColors.ink,
      child: InkWell(
        onTap: () => context.push('/live/$sessionId'),
        child: Semantics(
          button: true,
          label: paused ? 'Workout paused. Continue workout' : 'Workout in progress. Continue workout',
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
              child: Row(
                children: [
                  Icon(paused ? LucideIcons.pause : LucideIcons.timer, color: AppColors.lime, size: IconSizes.s),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Text(
                      paused ? 'Workout paused' : 'Workout in progress',
                      style: t.labelMedium?.copyWith(color: AppColors.surface),
                    ),
                  ),
                  SessionClock(
                    sessionId: sessionId,
                    style: t.labelMedium!.tabular.copyWith(color: AppColors.lime),
                  ),
                  const SizedBox(width: Space.s),
                  const Icon(LucideIcons.chevronRight, color: AppColors.surface, size: IconSizes.s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final duration = motionOf(context, Motion.standard);
    final t = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s),
              child: Row(
                children: [
                  for (final (i, tab) in _tabs.indexed)
                    Expanded(
                      child: Semantics(
                        selected: i == index,
                        button: true,
                        label: '${tab.label}, tab ${i + 1} of ${_tabs.length}',
                        excludeSemantics: true,
                        child: InkResponse(
                          onTap: () => onSelect(i),
                          containedInkWell: true,
                          highlightShape: BoxShape.rectangle,
                          borderRadius: Radii.small,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 56),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: duration,
                                  curve: Motion.change,
                                  width: 56,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: i == index ? AppColors.lime : AppColors.lime.withValues(alpha: 0),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(tab.icon, size: IconSizes.m, color: AppColors.ink),
                                ),
                                const SizedBox(height: Space.xs),
                                Text(
                                  tab.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: (i == index ? t.labelSmall?.weight(FontWeight.w800) : t.labelSmall)?.copyWith(
                                    color: i == index ? AppColors.ink : AppColors.secondaryText,
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
    );
  }
}
