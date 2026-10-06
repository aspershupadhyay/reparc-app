import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../health/health_sync.dart';
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
    // Health write-back runs only while a write feature is on (D-020).
    if (ref.watch(currentSettingsProvider).health.any((h) => h.startsWith('write'))) ref.watch(healthSyncProvider);
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live != null && shell.currentIndex > 1)
            _LiveBar(sessionId: live.id, paused: live.status == SessionStatus.paused),
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

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final duration = motionOf(context, Motion.standard);
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.l)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.s, Space.xs),
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
                        borderRadius: Radii.medium,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 58),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: duration,
                                curve: Motion.change,
                                width: 54,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: i == index ? p.energy : p.energy.withValues(alpha: 0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(tab.icon, size: 22, color: i == index ? p.onEnergy : p.inkSoft),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.labelSmall?.copyWith(color: i == index ? p.ink : p.inkSoft),
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
    );
  }
}
