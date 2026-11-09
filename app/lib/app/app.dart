import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/palette.dart';
import '../core/theme.dart';
import '../data/providers.dart';
import '../features/intro/intro.dart';

final _light = buildTheme(Palette.light);
final _dark = buildTheme(Palette.dark);

class ReparcApp extends ConsumerWidget {
  const ReparcApp({super.key, required this.router, this.intro = false});
  final GoRouter router;

  /// Show the animated logo on start. Off in tests.
  final bool intro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = switch (ref.watch(currentSettingsProvider).themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp.router(
      title: 'RepArc',
      debugShowCheckedModeBanner: false,
      theme: _light,
      darkTheme: _dark,
      themeMode: mode,
      routerConfig: router,
      scrollBehavior: const _IosScroll(),
      builder: (context, child) {
        final page = _DismissKeyboard(child: child ?? const SizedBox.shrink());
        return intro ? IntroGate(child: page) : page;
      },
    );
  }
}

/// iOS scrolling on every platform: bounce at the edges, no glow.
class _IosScroll extends MaterialScrollBehavior {
  const _IosScroll();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

/// A tap on empty space closes the keyboard. iPhone's number pad has no
/// Done key, so without this a keyboard could stay over a Save button
/// (platform design audit, 2026-11-09). Taps on controls still go to them:
/// this detector only wins when nothing below it takes the tap.
class _DismissKeyboard extends StatelessWidget {
  const _DismissKeyboard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    excludeFromSemantics: true,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: child,
  );
}
