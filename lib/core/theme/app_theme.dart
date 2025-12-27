import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// VidForge theme configuration
class AppTheme {
  AppTheme._();

  /// Dark theme (default)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.primaryLight,
        secondaryContainer: AppColors.primary,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBgPrimary,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      textTheme: _buildTextTheme(isDark: true),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBgPrimary,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextTertiary,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkBgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.darkBorder,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.2),
        trackHeight: 4,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.darkBorder,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.darkBgSecondary,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.darkTextSecondary),
        selectedLabelTextStyle: TextStyle(color: AppColors.primary),
        unselectedLabelTextStyle: TextStyle(color: AppColors.darkTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBgSecondary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 24,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkBgElevated,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkBgElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),
    );
  }

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.primaryDark,
        secondaryContainer: AppColors.primary,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.lightBgPrimary,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      textTheme: _buildTextTheme(isDark: false),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBgPrimary,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.lightBorder,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.2),
        trackHeight: 4,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lightBorder,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.lightBgSecondary,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.lightTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBgPrimary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme({required bool isDark}) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: textColor),
      displayMedium: AppTypography.displayMedium.copyWith(color: textColor),
      displaySmall: AppTypography.displaySmall.copyWith(color: textColor),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: textColor),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: textColor),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: textColor),
      titleLarge: AppTypography.titleLarge.copyWith(color: textColor),
      titleMedium: AppTypography.titleMedium.copyWith(color: textColor),
      titleSmall: AppTypography.titleSmall.copyWith(color: textColor),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: textColor),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: secondaryColor),
      bodySmall: AppTypography.bodySmall.copyWith(color: secondaryColor),
      labelLarge: AppTypography.labelLarge.copyWith(color: textColor),
      labelMedium: AppTypography.labelMedium.copyWith(color: secondaryColor),
      labelSmall: AppTypography.labelSmall.copyWith(color: secondaryColor),
    );
  }
}
