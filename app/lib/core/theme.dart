import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'tokens.dart';

const _family = 'Manrope';

/// Manrope ships as one variable font. Set the `wght` axis together with
/// [FontWeight] so every platform renders the requested weight.
TextStyle manrope(double size, FontWeight weight, {double? height, Color? color, double? spacing}) {
  return TextStyle(
    fontFamily: _family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    height: height,
    color: color,
    letterSpacing: spacing,
  );
}

extension WeightStyle on TextStyle {
  /// Changes weight and the matching variable-font axis.
  TextStyle weight(FontWeight w) => copyWith(fontWeight: w, fontVariations: [FontVariation.weight(w.value.toDouble())]);

  /// Uses tabular figures for data values.
  TextStyle get tabular => copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

ThemeData buildTheme(Palette p) {
  final dark = p.brightness == Brightness.dark;
  final t = TextTheme(
    displayLarge: manrope(48, FontWeight.w800, height: 1.05, color: p.ink, spacing: -1),
    displaySmall: manrope(34, FontWeight.w800, height: 1.1, color: p.ink, spacing: -0.5),
    headlineSmall: manrope(26, FontWeight.w800, height: 1.2, color: p.ink, spacing: -0.3),
    titleLarge: manrope(20, FontWeight.w700, height: 1.3, color: p.ink),
    titleMedium: manrope(16, FontWeight.w700, height: 1.4, color: p.ink),
    titleSmall: manrope(14, FontWeight.w700, height: 1.4, color: p.ink),
    bodyLarge: manrope(16, FontWeight.w500, height: 1.5, color: p.ink),
    bodyMedium: manrope(14, FontWeight.w500, height: 1.45, color: p.ink),
    bodySmall: manrope(12, FontWeight.w600, height: 1.4, color: p.inkSoft),
    labelLarge: manrope(16, FontWeight.w700, height: 1.25, color: p.ink),
    labelMedium: manrope(14, FontWeight.w700, height: 1.3, color: p.ink),
    labelSmall: manrope(12, FontWeight.w700, height: 1.3, color: p.inkSoft),
  );

  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.action,
    onPrimary: p.onAction,
    primaryContainer: p.brandSoft,
    onPrimaryContainer: p.ink,
    secondary: p.energy,
    onSecondary: p.onEnergy,
    secondaryContainer: p.brandSoft,
    onSecondaryContainer: p.ink,
    tertiary: p.ink,
    onTertiary: p.surface,
    error: p.error,
    onError: p.surface,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.inkSoft,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surfaceAlt,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.surfaceAlt,
    outline: p.line,
    outlineVariant: p.line,
    inverseSurface: p.ink,
    onInverseSurface: p.surface,
    inversePrimary: p.energy,
  );

  final shape = WidgetStateProperty.all(const StadiumBorder());
  final size = WidgetStateProperty.all(const Size(minTarget, 52));
  final pad = WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.m));

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    extensions: [p],
    fontFamily: _family,
    textTheme: t,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: t.titleMedium,
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: Radii.large),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: shape,
        minimumSize: size,
        padding: pad,
        elevation: WidgetStateProperty.all(0),
        textStyle: WidgetStateProperty.all(t.labelLarge),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? p.line : p.action),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? p.inkSoft : p.onAction,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: shape,
        minimumSize: size,
        padding: pad,
        textStyle: WidgetStateProperty.all(t.labelLarge),
        foregroundColor: WidgetStateProperty.all(p.ink),
        side: WidgetStateProperty.all(BorderSide(color: p.line, width: 1.5)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        shape: shape,
        minimumSize: WidgetStateProperty.all(const Size(minTarget, minTarget)),
        textStyle: WidgetStateProperty.all(t.labelMedium),
        foregroundColor: WidgetStateProperty.all(p.brand),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(minTarget, minTarget)),
        iconSize: WidgetStateProperty.all(IconSizes.m),
        foregroundColor: WidgetStateProperty.all(p.ink),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 14),
      labelStyle: t.bodyMedium?.copyWith(color: p.inkSoft),
      floatingLabelStyle: t.bodySmall?.copyWith(color: p.brand),
      hintStyle: t.bodyLarge?.copyWith(color: p.inkSoft.withValues(alpha: 0.7)),
      suffixStyle: t.bodyMedium?.copyWith(color: p.inkSoft),
      border: OutlineInputBorder(
        borderRadius: Radii.medium,
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Radii.medium,
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.medium,
        borderSide: BorderSide(color: p.brand, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Radii.medium,
        borderSide: BorderSide(color: p.error),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.ink,
      secondarySelectedColor: p.ink,
      side: BorderSide(color: p.line),
      labelStyle: t.labelMedium,
      secondaryLabelStyle: t.labelMedium?.copyWith(color: p.surface),
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.surface),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.surface : p.ink),
        side: WidgetStateProperty.all(BorderSide(color: p.line)),
        textStyle: WidgetStateProperty.all(t.labelMedium),
        minimumSize: WidgetStateProperty.all(const Size(minTarget, minTarget)),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.line,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.l))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Radii.large),
      titleTextStyle: t.titleLarge,
      contentTextStyle: t.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.ink,
      contentTextStyle: t.bodyMedium?.copyWith(color: p.surface),
      actionTextColor: dark ? p.brand : p.energy,
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: Space.m,
      titleTextStyle: t.bodyLarge?.weight(FontWeight.w600),
      subtitleTextStyle: t.bodySmall,
      iconColor: p.ink,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.brand : p.line),
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.onBrand : p.surface),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brand),
    datePickerTheme: DatePickerThemeData(backgroundColor: p.surface, surfaceTintColor: Colors.transparent),
    timePickerTheme: TimePickerThemeData(backgroundColor: p.surface),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Radii.medium),
      textStyle: t.bodyMedium,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _ReducedMotionAware(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.iOS: _ReducedMotionAware(CupertinoPageTransitionsBuilder()),
      },
    ),
  );
}

/// Uses the platform page transition, or a dissolve when the user asked
/// the system to reduce motion (handbook 3.12).
class _ReducedMotionAware extends PageTransitionsBuilder {
  const _ReducedMotionAware(this.inner);
  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return FadeTransition(opacity: animation, child: child);
    }
    return inner.buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}
