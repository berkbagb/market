import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Sayfa importları
import 'package:market/features/pos/pos_screen.dart'; 
import 'package:market/features/inventory/inventory_screen.dart';
import 'package:market/features/reports/reports_page.dart';
import 'package:market/features/settings/settings_screen.dart';
import 'package:market/features/customers/customer_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    await initializeDateFormatting('tr_TR', null);

    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1360, 850),
      minimumSize: Size(1100, 750),
      center: true,
      title: "BERK MARKET - POS PRO",
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    await Hive.initFlutter();
    await Hive.openBox('settings');

    runApp(
      const ProviderScope(
        child: MarketApp(),
      ),
    );
  } catch (e) {
    debugPrint("UYGULAMA BAŞLATMA HATASI: $e");
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Hata: $e")))));
  }
}

class MarketApp extends StatelessWidget {
  const MarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market POS Pro',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr', 'TR'),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617),
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981),
        ),

        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: const Color(0xFFE2E8F0), // Slate yerine elle renk verdik
          displayColor: Colors.white,
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
          height: 75,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF6366F1), size: 28);
            }
            return const IconThemeData(color: Color(0xFF94A3B8));
          }),
        ),

        // Hata düzeldi: CardThemeData kullanıldı
        cardTheme: CardThemeData(
          color: const Color(0xFF0F172A),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const MainNavigationScreen(), 
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PosScreen(),
    const InventoryScreen(),
    const ReportsPage(),
    const CustomerScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Satış (POS)',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Stok Yönetimi',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Raporlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Müşteriler',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_suggest_outlined),
              selectedIcon: Icon(Icons.settings_suggest_rounded),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}