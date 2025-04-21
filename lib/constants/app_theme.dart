import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Define el tema visual oscuro para toda la aplicación.
class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color.fromARGB(255, 225, 90, 12),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.indigo[800],
      elevation: 4,
      titleTextStyle: GoogleFonts.pressStart2p( fontSize: 18, color: Colors.white, ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.indigo, brightness: Brightness.dark, backgroundColor: const Color(0xFF121212),
    ).copyWith( secondary: Colors.amberAccent, onSecondary: Colors.black, ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.lato(fontSize: 16, color: Colors.white),
      bodyMedium: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
      headlineSmall: GoogleFonts.pressStart2p(fontSize: 22, color: Colors.white),
      titleLarge: GoogleFonts.pressStart2p(fontSize: 18, color: Colors.white),
      labelLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.grey[850],
      border: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none, ),
      enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!), ),
      focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.indigo[300]!), ),
      labelStyle: GoogleFonts.lato(color: Colors.white70),
      hintStyle: GoogleFonts.lato(color: Colors.white54),
    ),
    listTileTheme: ListTileThemeData( iconColor: Colors.indigo[300], textColor: Colors.white, ),
    dividerColor: Colors.grey[700],
  );
}