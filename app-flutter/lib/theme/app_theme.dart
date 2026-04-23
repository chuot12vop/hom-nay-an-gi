import 'package:flutter/material.dart';

import 'app_gradients.dart';

/// Theme toàn app (Material 3, slider, chip, nút, v.v.).
ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppGradients.primaryMid,
    primary: AppGradients.primaryEnd,
    secondary: AppGradients.primaryOrange,
    surface: Colors.white,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFFFF8F4),
    useMaterial3: true,
    sliderTheme: SliderThemeData(
      activeTrackColor: AppGradients.primaryEnd,
      inactiveTrackColor: AppGradients.primaryStart.withValues(alpha: 0.3),
      thumbColor: AppGradients.primaryMid,
      overlayColor: AppGradients.primaryMid.withValues(alpha: 0.2),
      valueIndicatorColor: AppGradients.primaryEnd,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppGradients.primaryMid,
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF5A5A5E)),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: AppGradients.primaryStart.withValues(alpha: 0.4),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppGradients.primaryStart.withValues(alpha: 0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppGradients.primaryStart.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppGradients.primaryMid,
          width: 1.6,
        ),
      ),
      labelStyle: const TextStyle(color: Color(0xFF5A5A5E)),
      floatingLabelStyle: const TextStyle(color: AppGradients.primaryEnd),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppGradients.primaryEnd,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppGradients.primaryEnd,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppGradients.primaryMid,
    ),
  );
}
