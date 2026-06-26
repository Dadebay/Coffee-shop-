import 'package:flutter/material.dart';
import '../constants/color_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg      = isDark ? AppColors.bgDark    : const Color(0xffF5F5F7);
    final bgCard  = isDark ? AppColors.bgCard    : Colors.white;
    final bgSurf  = isDark ? AppColors.bgSurface : const Color(0xffEEEEF2);
    final bgBord  = isDark ? AppColors.bgBorder  : const Color(0xffE0E0E6);
    final txtWh   = isDark ? AppColors.textWhite : const Color(0xff111111);
    final txtGrey = isDark ? AppColors.textGrey  : const Color(0xff666666);
    final txtDim  = isDark ? AppColors.textDim   : const Color(0xffAAAAAA);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Gilroy',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primary2,
        onSecondary: Colors.white,
        surface: bgSurf,
        onSurface: txtWh,
        error: AppColors.red,
        onError: Colors.white,
        outline: bgBord,
        surfaceContainerHighest: bgCard,
      ),
      scaffoldBackgroundColor: bg,
      cardTheme: CardTheme(
        color: bgCard,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withAlpha(20),
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgSurf,
        foregroundColor: txtWh,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: txtWh,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: bgSurf,
        selectedIconTheme: const IconThemeData(color: AppColors.primary2),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: 'Gilroy',
          color: AppColors.primary2,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(color: txtGrey),
        unselectedLabelTextStyle: TextStyle(fontFamily: 'Gilroy', color: txtGrey),
        indicatorColor: AppColors.primary.withAlpha(30),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bgBord),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bgBord),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary2, width: 1.5),
        ),
        labelStyle: TextStyle(fontFamily: 'Gilroy', color: txtGrey, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(fontFamily: 'Gilroy', color: txtDim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary2,
          textStyle: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: bgBord, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: bgCard,
        selectedColor: AppColors.primary.withAlpha(isDark ? 34 : 25),
        labelStyle: TextStyle(fontFamily: 'Gilroy', color: txtWh, fontWeight: FontWeight.w500),
        side: BorderSide(color: bgBord),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, color: txtWh),
        displayMedium:  TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, color: txtWh),
        headlineLarge:  TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, color: txtWh),
        headlineMedium: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, color: txtWh),
        headlineSmall:  TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, color: txtWh),
        titleLarge:     TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: txtWh),
        titleMedium:    TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: txtWh),
        titleSmall:     TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: txtWh),
        bodyLarge:      TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w400, color: txtWh),
        bodyMedium:     TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w400, color: txtWh),
        bodySmall:      TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w400, color: txtGrey),
        labelLarge:     TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: txtWh),
        labelMedium:    TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: txtWh),
        labelSmall:     TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: txtGrey),
      ),
    );
  }
}
