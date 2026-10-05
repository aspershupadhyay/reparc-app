import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

const _family = 'Manrope';

/// Manrope ships as one variable font. Set the `wght` axis together with
/// [FontWeight] so every platform renders the requested weight.
TextStyle manrope(double size, FontWeight weight, {double? height, Color? color}) {
  return TextStyle(
    fontFamily: _family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    height: height,
    color: color ?? AppColors.ink,
  );
}

extension WeightStyle on TextStyle {
  /// Changes weight and the matching variable-font axis.
  TextStyle weight(FontWeight w) => copyWith(
    fontWeight: w,
    fontVariations: [FontVariation.weight(w.value.toDouble())],
  );

  /// Uses tabular figures for data values.
  TextStyle get tabular => copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

ThemeData buildTheme() {
  final textTheme = TextTheme(
    displaySmall: manrope(32, FontWeight.w800, height: 1.2),
    headlineSmall: manrope(24, FontWeight.w700, height: 1.25),
    titleLarge: manrope(20, FontWeight.w700, height: 1.3),
    titleMedium: manrope(16, FontWeight.w700, height: 1.5),
    titleSmall: manrope(14, FontWeight.w700, height: 1.4),
    bodyLarge: manrope(16, FontWeight.w500, height: 1.5),
    bodyMedium: manrope(14, FontWeight.w500, height: 1.45),
    bodySmall: manrope(12, FontWeight.w500, height: 1.4, color: AppColors.secondaryText),
    labelLarge: manrope(16, FontWeight.w700, height: 1.25),
    labelMedium: manrope(14, FontWeight.w600, height: 1.3),
    labelSmall: manrope(12, FontWeight.w600, height: 1.3),
  );

  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.lime,
    onPrimary: AppColors.ink,
    primaryContainer: AppColors.lime,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.lavender,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.lavender,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.ink,
    onTertiary: AppColors.surface,
    error: AppColors.error,
    onError: AppColors.surface,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.secondaryText,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.canvas,
    surfaceContainer: AppColors.softSurface,
    surfaceContainerHigh: AppColors.softSurface,
    surfaceContainerHighest: AppColors.softSurface,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.lime,
  );

  final buttonShape = WidgetStateProperty.all(
    const RoundedRectangleBorder(borderRadius: Radii.medium),
  );
  final buttonSize = WidgetStateProperty.all(const Size(minTarget, minTarget));
  final buttonPadding = WidgetStateProperty.all(
    const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.m),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _family,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.canvas,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.medium,
        side: BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: buttonShape,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? AppColors.border : AppColors.lime,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? AppColors.secondaryText : AppColors.ink,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: buttonShape,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        foregroundColor: WidgetStateProperty.all(AppColors.ink),
        side: WidgetStateProperty.all(const BorderSide(color: AppColors.border)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        shape: buttonShape,
        minimumSize: buttonSize,
        textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        foregroundColor: WidgetStateProperty.all(AppColors.ink),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: buttonSize,
        iconSize: WidgetStateProperty.all(IconSizes.m),
        foregroundColor: WidgetStateProperty.all(AppColors.ink),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
      labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
      hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
      border: const OutlineInputBorder(
        borderRadius: Radii.small,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: Radii.small,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: Radii.small,
        borderSide: BorderSide(color: AppColors.ink, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: Radii.small,
        borderSide: BorderSide(color: AppColors.error),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.lime,
      side: const BorderSide(color: AppColors.border),
      labelStyle: textTheme.labelMedium,
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.l)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.large),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.surface),
      actionTextColor: AppColors.lime,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: Radii.small),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: Space.m,
      titleTextStyle: textTheme.bodyLarge?.weight(FontWeight.w600),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
      iconColor: AppColors.ink,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.ink : AppColors.border,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.lime : AppColors.surface,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _ReducedMotionAware(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.iOS: _ReducedMotionAware(CupertinoPageTransitionsBuilder()),
      },
    ),
  );
}

/// Uses the platform page transition, or no movement when the user asked
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
