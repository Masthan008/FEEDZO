import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Color System ──────────────────────────────────────────────────────────────
class AppColors {
  // Primary brand - BiteGo Orange
  static const primary = Color(0xFFFF6B35);
  static const primaryLight = Color(0xFFFFB340);
  static const primaryDark = Color(0xFFE55A2B);
  static const primarySurface = Color(0xFFFFF8F0);

  // Accent - BiteGo Yellow
  static const accent = Color(0xFFFFB340);
  static const accentLight = Color(0xFFFFCC80);

  // Surfaces
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF3F4F6);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFBDBDBD);

  // Borders
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFEEEEEE);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const star = Color(0xFFFBBF24);

  // Status
  static const statusDelivered = Color(0xFF16A34A);
  static const statusDeliveredBg = Color(0xFFF0FDF4);
  static const statusPreparing = Color(0xFF2563EB);
  static const statusPreparingBg = Color(0xFFDBEAFE);
  static const statusPicked = Color(0xFF0EA5E9);
  static const statusPickedBg = Color(0xFFE0F2FE);

  // Shadows
  static const cardShadow = Color(0x14000000);
  static const deepShadow = Color(0x1F000000);

  // Gradients
  static const gradientStart = Color(0xFFFF6B35);
  static const gradientEnd = Color(0xFFE55A2B);

  // Dark mode
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceVariant = Color(0xFF334155);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
}

// ── Shape System ──────────────────────────────────────────────────────────────
class AppShape {
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXL = 20;
  static const double radiusRound = 100;

  static final small = BorderRadius.circular(radiusSmall);
  static final medium = BorderRadius.circular(radiusMedium);
  static final large = BorderRadius.circular(radiusLarge);
  static final xl = BorderRadius.circular(radiusXL);
  static final round = BorderRadius.circular(radiusRound);
}

// ── Shadows ───────────────────────────────────────────────────────────────────
class AppShadows {
  static List<BoxShadow> get card => [
        const BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevated => [
        const BoxShadow(
          color: AppColors.deepShadow,
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get subtle => [
        const BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> primaryGlow(double opacity) => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  // Legacy static colours (for backward compat)
  static const primaryColor = AppColors.primary;
  static const secondaryColor = AppColors.primaryLight;
  static const backgroundColor = AppColors.background;
  static const cardColor = AppColors.surface;
  static const errorColor = AppColors.error;
  static const warningColor = AppColors.warning;
  static const infoColor = AppColors.info;

  static ThemeData lightTheme = _buildLight();

  static ThemeData _buildLight() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          scrolledUnderElevation: 1,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShape.radiusMedium)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShape.radiusMedium)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppShape.radiusMedium)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppShape.radiusMedium),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.radiusLarge),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
          selectedLabelStyle:
              GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
        ),
        tabBarTheme: TabBarThemeData(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShape.radiusMedium)),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShape.radiusXL)),
        ),
      );
}
