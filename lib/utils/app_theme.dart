import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Following the Tailwind Slate palette
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);

  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue300 = Color(0xFF93C5FD);

  static const Color red400 = Color(0xFFF87171);
  static const Color red900 = Color(0xFF7F1D1D);
  static const Color green400 = Color(0xFF4ADE80);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slate900,

      colorScheme: ColorScheme.dark(
        primary: blue600,
        secondary: blue500,
        surface: slate800,
        surfaceContainerHighest: slate700,
        error: red400,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: slate800.withAlpha((0.95 * 255).toInt()),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: slate800.withAlpha((0.5 * 255).toInt()),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: slate700, width: 1)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: slate600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate700.withAlpha((0.5 * 255).toInt()),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: slate600)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: slate600)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: blue500, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: red400)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: slate400),
        labelStyle: TextStyle(color: slate200),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: slate300),
        bodySmall: TextStyle(fontSize: 12, color: slate400),
      ),

      iconTheme: IconThemeData(color: slate400),

      dividerTheme: DividerThemeData(color: slate700, thickness: 1),

      dialogTheme: DialogThemeData(backgroundColor: slate800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: slate800,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Gradient backgrounds
  static BoxDecoration get gradientBackground {
    return BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [slate900, slate800, slate900]),
    );
  }

  static BoxDecoration get cardGradient {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [slate800.withAlpha((0.6 * 255).toInt()), slate800.withAlpha((0.4 * 255).toInt())],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: slate700),
    );
  }
}
