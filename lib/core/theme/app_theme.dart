import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF081A46);
  static const Color navy2 = Color(0xFF102B6B);
  static const Color blue = Color(0xFF245BFF);
  static const Color ink = Color(0xFF071735);
  static const Color muted = Color(0xFF63708A);
  static const Color line = Color(0xFFE3E9F6);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF5F7FC);
  static const Color softBlue = Color(0xFFEAF0FF);
  static const Color success = Color(0xFF21A67A);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: background,
      primaryColor: navy,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: navy,
        secondary: blue,
        surface: surface,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: blue,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: blue, width: 1.4),
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: line),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          color: ink,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        titleLarge: const TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: const TextStyle(
          color: ink,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        bodyLarge: const TextStyle(
          color: ink,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        bodyMedium: const TextStyle(
          color: ink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }

  static BoxDecoration panel({Color color = surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: line),
      boxShadow: [
        BoxShadow(
          color: navy.withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration heroPanel() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [navy, navy2],
      ),
    );
  }
}
