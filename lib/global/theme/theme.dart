import 'package:flutter/material.dart';

class AppThemes {
  // 1. Default Style (Light / Clean Theme - မူလ ပုံစံအဖြူရောင်)
  static final ThemeData defaultTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
      primary: Colors.blueAccent,
      secondary: Colors.blue,
      surface: Colors.white,
      onSurface: const Color(0xFF1E293B),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(color: Color(0xFF475569)),
    ),
  );

  // 2. Dark Style (ရိုးရိုး အမှောင်ပုံစံ - Classic Dark)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1E1E1E),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF2C2C2C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Brightness.dark,
      primary: Colors.grey,
      secondary: Colors.blueGrey,
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFE0E0E0),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(color: Color(0xFFA0A0A0)),
    ),
  );

  // 3. Modern / High-light Style (Neon / Deep Cyber Neon ပုံစံ)
  // Dark Theme နှင့် သိသိသာသာ ကွဲထွက်စေရန် Neon Color များကို အသားပေးထားပါသည်
  static final ThemeData modernHighlightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF38BDF8),
    scaffoldBackgroundColor: const Color(0xFF020617), // အမည်းစက်စက် အနက်ရင့်
    cardColor: const Color(0xFF0F172A), // Slate 900
    dividerColor: const Color(0xFF38BDF8).withAlpha(76), // Neon Cyan Line
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Color(0xFF38BDF8), // လင်းလက်နေသော Cyan
      elevation: 2,
      shadowColor: Color(0xFF38BDF8),
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF38BDF8),    // Neon Cyan
      secondary: Color(0xFFF43F5E),  // Neon Pink
      surface: Color(0xFF0F172A),    // Card / Sheet Color
      onSurface: Color(0xFFF8FAFC),  // Text Color
      tertiary: Color(0xFFA855F7),   // Neon Purple Accent
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF38BDF8),
      foregroundColor: Color(0xFF020617),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0F172A),
      selectedItemColor: Color(0xFF38BDF8),
      unselectedItemColor: Color(0xFF64748B),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Color(0xFFF8FAFC)),
    ),
  );
}
