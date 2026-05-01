import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark.background,
      primaryColor: AppColors.dark.primary,
      colorScheme: ColorScheme.dark(
        primary: AppColors.dark.primary,
        secondary: AppColors.dark.accent,
        surface: AppColors.dark.cardDark,
        error: AppColors.dark.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark.secondary,
        foregroundColor: AppColors.dark.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.dark.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: AppColors.dark.textPrimary, letterSpacing: -1.0),
          displayMedium: TextStyle(color: AppColors.dark.textPrimary, letterSpacing: -0.8),
          displaySmall: TextStyle(color: AppColors.dark.textPrimary, letterSpacing: -0.6),
          headlineLarge: TextStyle(color: AppColors.dark.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(color: AppColors.dark.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          headlineSmall: TextStyle(color: AppColors.dark.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AppColors.dark.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: TextStyle(color: AppColors.dark.textPrimary, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.dark.textSecondary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.dark.textPrimary),
          bodyMedium: TextStyle(color: AppColors.dark.textSecondary),
          bodySmall: TextStyle(color: AppColors.dark.textSecondary),
          labelLarge: TextStyle(color: AppColors.dark.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.dark.cardDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.dark.divider, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.dark.cardMedium,
        selectedColor: AppColors.dark.primary,
        labelStyle: GoogleFonts.inter(color: AppColors.dark.textPrimary, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.inter(color: AppColors.dark.secondary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.dark.textSecondary, fontSize: 14),
        prefixIconColor: AppColors.dark.textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.dark.navBar,
        indicatorColor: AppColors.dark.primary.withAlpha(36),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.dark.primary, size: 22);
          }
          return IconThemeData(color: AppColors.dark.textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                color: AppColors.dark.primary, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.inter(color: AppColors.dark.textSecondary, fontSize: 11);
        }),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: DividerThemeData(color: AppColors.dark.divider, thickness: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.dark.primary,
        unselectedLabelColor: AppColors.dark.textSecondary,
        indicatorColor: AppColors.dark.primary,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.dark.primary,
        foregroundColor: AppColors.dark.secondary,
        elevation: 4,
        shape: const StadiumBorder(),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.light.background,
      primaryColor: AppColors.light.primary,
      colorScheme: ColorScheme.light(
        primary: AppColors.light.primary,
        secondary: AppColors.light.accent,
        surface: AppColors.light.cardDark,
        error: AppColors.light.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light.secondary,
        foregroundColor: AppColors.light.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.light.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: AppColors.light.textPrimary, letterSpacing: -1.0),
          displayMedium: TextStyle(color: AppColors.light.textPrimary, letterSpacing: -0.8),
          displaySmall: TextStyle(color: AppColors.light.textPrimary, letterSpacing: -0.6),
          headlineLarge: TextStyle(color: AppColors.light.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(color: AppColors.light.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          headlineSmall: TextStyle(color: AppColors.light.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AppColors.light.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: TextStyle(color: AppColors.light.textPrimary, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.light.textSecondary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.light.textPrimary),
          bodyMedium: TextStyle(color: AppColors.light.textSecondary),
          bodySmall: TextStyle(color: AppColors.light.textSecondary),
          labelLarge: TextStyle(color: AppColors.light.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.light.cardDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.light.divider, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.light.cardMedium,
        selectedColor: AppColors.light.primary,
        labelStyle: GoogleFonts.inter(color: AppColors.light.textPrimary, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.inter(color: AppColors.light.secondary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.light.textSecondary, fontSize: 14),
        prefixIconColor: AppColors.light.textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.light.navBar,
        indicatorColor: AppColors.light.primary.withAlpha(36),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.light.primary, size: 22);
          }
          return IconThemeData(color: AppColors.light.textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                color: AppColors.light.primary, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.inter(color: AppColors.light.textSecondary, fontSize: 11);
        }),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: DividerThemeData(color: AppColors.light.divider, thickness: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.light.primary,
        unselectedLabelColor: AppColors.light.textSecondary,
        indicatorColor: AppColors.light.primary,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.light.primary,
        foregroundColor: AppColors.light.secondary,
        elevation: 4,
        shape: const StadiumBorder(),
      ),
    );
  }

  // ── Decoration helpers ───────────────────────────────────────────────────────

  static BoxDecoration surfaceCard({
    BuildContext? context,
    BorderRadius? borderRadius,
    Color? borderColor,
    Color? color,
  }) {
    final colors = context != null ? AppColors.of(context) : AppColors.dark;
    return BoxDecoration(
      color: color ?? colors.cardDark,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? colors.divider, width: 1),
    );
  }

  static BoxDecoration gradientCard({
    BuildContext? context,
    List<Color>? colors,
    BorderRadius? borderRadius,
  }) {
    final appColors = context != null ? AppColors.of(context) : AppColors.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors ?? [appColors.cardDark, appColors.cardMedium],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: appColors.divider, width: 1),
    );
  }

  static BoxDecoration primaryGradient({BorderRadius? borderRadius}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00E5A0), Color(0xFF00A87A)],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.dark.primary.withAlpha(50),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration purpleGradient({BorderRadius? borderRadius}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF160D36), Color(0xFF0D0820)],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
    );
  }

  static BoxDecoration glassCard({
    BuildContext? context,
    BorderRadius? borderRadius,
    Color? borderColor,
  }) {
    final colors = context != null ? AppColors.of(context) : AppColors.dark;
    return BoxDecoration(
      color: colors.cardDark.withAlpha(200),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? colors.divider,
        width: 1,
      ),
    );
  }

  static Widget sectionTitle(
    BuildContext context,
    String title, {
    String? action,
    VoidCallback? onAction,
  }) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              'See All →',
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
