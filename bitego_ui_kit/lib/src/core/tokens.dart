import 'package:flutter/material.dart';

/// BiteGo Design Tokens - Unified design system
/// Used across all 4 apps for consistency
///
/// ## Border Radius Tokens
/// - small: 8
/// - medium: 12
/// - large: 16
/// - xl: 24
/// - round: full circle
///
/// ## Spacing Tokens
/// - xs: 4
/// - sm: 8
/// - md: 12
/// - lg: 16
/// - xl: 24
/// - xxl: 32
///
/// ## Elevation/Shadow Tokens
/// - card: subtle shadow for cards
/// - elevated: higher elevation for floating elements
/// - dialog: maximum elevation for modals

class BorderRadiusTokens {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xl = 24;
  static const double round = 999;
}

class SpacingTokens {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class ElevationTokens {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> dialog = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> none = [];
}

class TypographyTokens {
  static const String fontFamily = 'Inter';

  // Display
  static const double displayLarge = 48;
  static const double displayMedium = 36;
  static const double displaySmall = 24;

  // Headline
  static const double headlineLarge = 32;
  static const double headlineMedium = 28;
  static const double headlineSmall = 24;

  // Title
  static const double titleLarge = 20;
  static const double titleMedium = 18;
  static const double titleSmall = 16;

  // Body
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;

  // Label
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 11;
}

class DurationTokens {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration emphasis = Duration(milliseconds: 800);
}

class AnimationCurveTokens {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve entrance = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve emphasize = Curves.easeInOutCubicEmphasized;
  static const Curve bounce = Curves.elasticOut;
}
