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

  // Surfaces
  static const background = Color(0xFFF8FAFB);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF3F4F6);

  // Sidebar
  static const sidebar = Color(0xFF1A1A1A);
  static const sidebarHover = Color(0xFF2D2D2D);
  static const sidebarActive = Color(0xFFFF6B35);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFD1D5DB);

  // Borders
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFEEEEEE);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF2563EB);
  static const star = Color(0xFFFBBF24);

  // Status
  static const statusPending = Color(0xFFF59E0B);
  static const statusPendingBg = Color(0xFFFEF3C7);
  static const statusPreparing = Color(0xFF2563EB);
  static const statusPreparingBg = Color(0xFFDBEAFE);
  static const statusDelivered = Color(0xFF16A34A);
  static const statusDeliveredBg = Color(0xFFF0FDF4);
  static const statusCancelled = Color(0xFFDC2626);
  static const statusCancelledBg = Color(0xFFFEE2E2);

  // Shadows
  static const cardShadow = Color(0x14000000);
  static const deepShadow = Color(0x1F000000);
  static const shadow = Color(0x0A000000);

  // Gradients
  static const gradientStart = Color(0xFFFF6B35);
  static const gradientEnd = Color(0xFFE55A2B);
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
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.radiusMedium),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShape.radiusSmall)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppShape.radiusSmall),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppShape.radiusSmall),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppShape.radiusSmall),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
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
