import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/core/database_helper.dart';
import 'package:market/main_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Flutter binding'i garantiye al
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop (Windows/Linux) veritabanı desteğini başlat
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Veritabanını uygulama açılmadan önce uyandır
  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    debugPrint("CRITICAL DATABASE ERROR: $e");
  }

  // Sistem durum çubuğunu temaya uygun hale getir
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF020617),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: MarketApp(),
    ),
  );
}

class MarketApp extends StatelessWidget {
  const MarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    // V3 PREMIUM KURUMSAL TEMA
    final premiumDarkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF020617),
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
        surface: const Color(0xFF0F172A),
        primary: const Color(0xFF818CF8),
        secondary: const Color(0xFF10B981),
        error: const Color(0xFFF87171),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // withOpacity yerine withValues kullanıldı
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
        ),
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800, 
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF818CF8),
        unselectedItemColor: Colors.white.withValues(alpha: 0.3),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        elevation: 20,
        type: BottomNavigationBarType.fixed,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B).withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.2), 
          fontSize: 14,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return MaterialApp(
      title: 'Market POS Pro',
      debugShowCheckedModeBanner: false,
      theme: premiumDarkTheme,
      home: const MainScreen(), 
    );
  }
}