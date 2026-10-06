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
      title: 'Reparc',
      debugShowCheckedModeBanner: false,
      theme: _light,
      darkTheme: _dark,
      themeMode: mode,
      routerConfig: router,
      builder: intro ? (context, child) => IntroGate(child: child ?? const SizedBox.shrink()) : null,
    );
  }
}
