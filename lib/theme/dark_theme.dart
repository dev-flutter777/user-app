import 'package:flutter/material.dart';

Color _primaryColor = const Color(0xFF1455AC);
Color _secondaryColor = const Color(0xFFF58300);

ThemeData dark = ThemeData(
  fontFamily: 'TitilliumWeb',
  primaryColor: _primaryColor,
  brightness: Brightness.dark,
  highlightColor: const Color(0xFF1C2B43),
  hintColor: const Color(0xFFB4C3DB),
  cardColor: const Color(0xFF182338),
  scaffoldBackgroundColor: const Color(0xFF0F1A2D),
  splashColor: Colors.transparent,


  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFE9EEF4)),  // Text color primary
    bodyMedium: TextStyle(color: Color(0xFFE9EEF4)), // Text color Secondary
    bodySmall: TextStyle(color: Color(0xFFE9EEF4)),  // Text color Light grey
  ),

  colorScheme : ColorScheme.dark(
    primary: _primaryColor,  // Primary Color
    secondary: _secondaryColor,  // Secondary Color
    tertiary: const Color(0xFFFFBB38), // Warning Color
    tertiaryContainer: const Color(0xFF6C7A8E),
    surface: const Color(0xFF182338),
    onPrimary: Colors.white,
    onTertiaryContainer: const Color(0xFF04BB7B), // Success Color
    primaryContainer: const Color(0xFF243B5E),
    onPrimaryContainer: const Color(0xFFD6E6FF),
    onSecondaryContainer: const Color(0xFFE9EEF4),
    outline: const Color(0xff5C8FFC), // Info Color
    onTertiary: const Color(0xFF545252),
    secondaryContainer: const Color(0xFF23324A),
    surfaceContainer: const Color(0xFF1C2B43),
    error: const Color(0xFFFF4040), // Danger Color
    shadow: const Color(0xFFF4F7FC),
  ),

  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
  }),
);
