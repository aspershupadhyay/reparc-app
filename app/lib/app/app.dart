import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

class ReparcApp extends StatelessWidget {
  const ReparcApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Reparc',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
