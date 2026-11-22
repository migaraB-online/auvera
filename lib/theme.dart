import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

class AuveraColors {
  static const navy = Color(0xFF0B1F3A);
  static const gold = Color(0xFFC9A24B);
  static const ivory = Color(0xFFFAF6EC);
}

ThemeData auveraLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AuveraColors.navy,
      primary: AuveraColors.navy,
      secondary: AuveraColors.gold,
      surface: AuveraColors.ivory,
    ),
    scaffoldBackgroundColor: AuveraColors.ivory,
  );

  final body = GoogleFonts.interTextTheme(base.textTheme)
      .apply(bodyColor: AuveraColors.navy, displayColor: AuveraColors.navy);

  return base.copyWith(
    textTheme: body.copyWith(
      headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 40, fontWeight: FontWeight.w700, color: AuveraColors.navy),
      headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 30, fontWeight: FontWeight.w700, color: AuveraColors.navy),
      titleLarge: GoogleFonts.cormorantGaramond(
          fontSize: 24, fontWeight: FontWeight.w600, color: AuveraColors.navy),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AuveraColors.ivory,
      foregroundColor: AuveraColors.navy,
      elevation: 0,
      titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 26, fontWeight: FontWeight.w700, color: AuveraColors.navy),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AuveraColors.gold,
        foregroundColor: AuveraColors.navy,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AuveraColors.gold, width: 2),
      ),
    ),
  );
}