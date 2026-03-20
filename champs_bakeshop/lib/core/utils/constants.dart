import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// APP COLORS
// ═══════════════════════════════════════════════════════════
class AppColors {
  static const Color primary = Color(0xFFC4722F);
  static const Color primaryDark = Color(0xFFA35A1F);
  static const Color primaryLight = Color(0xFFE8A960);
  static const Color accent = Color(0xFFD4943A);
  static const Color background = Color(0xFFFDF6EC);
  static const Color surface = Color(0xFFFAF0DE);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF3D2B1F);
  static const Color textSecondary = Color(0xFF7A6555);
  static const Color textHint = Color(0xFFB09A88);
  static const Color border = Color(0xFFE8DDD0);
  static const Color success = Color(0xFF5B8C5A);
  static const Color danger = Color(0xFFC0392B);
  static const Color info = Color(0xFF2E86AB);
  static const Color masterBaker = Color(0xFF5B8C5A);
  static const Color helper = Color(0xFF2E86AB);
  static const Color purple = Color(0xFF8E44AD);
   static const Color warning      = Color(0xFFF39C12); 
   static const Color packer = Color(0xFF7B1FA2); // purple
static const Color seller = Color(0xFF00897B);  // teal// ← ADD THIS
}

// ═══════════════════════════════════════════════════════════
// APP THEME
// ═══════════════════════════════════════════════════════════
class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle( 
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        cardTheme: CardThemeData( // FIXED: CardThemeData
          color: AppColors.card,
          elevation: 2,
          shadowColor: AppColors.text.withValues(alpha: 0.08), // FIXED: withValues
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: AppColors.textHint),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      );
}

// ═══════════════════════════════════════════════════════════
// BUSINESS CONSTANTS
// ═══════════════════════════════════════════════════════════
class AppConstants {
  static const double masterBakerBonusPerSack = 100.0;
  static const double helperOvenDeductionPerDay = 15.0;
}