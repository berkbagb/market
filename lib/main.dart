import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

// Sayfa importları
import 'package:market/features/pos/pos_screen.dart'; 
import 'package:market/features/inventory/inventory_screen.dart';

import 'package:market/features/reports/reports_page.dart';
import 'package:market/features/settings/settings_screen.dart';
import 'package:market/features/customers/customer_screen.dart'; // Müşteriler sayfasını ekledik

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop: SQLite FFI motorunu başlat
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } catch (e) {
      debugPrint('sqflite FFI init failed: $e');
    }
  }

  // Dil ayarları
  await initializeDateFormatting('tr_TR', null);

  // Pencere ayarları
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1360, 850),
      center: true,
      title: "BERK MARKET - POS PRO",
    ), 
    () async {
      await windowManager.show();
      await windowManager.focus();
    }
  );

  // Veritabanı başlatma
  await Hive.initFlutter();
  // Hive.registerAdapter(CustomerAdapter());
  // await Hive.openBox('customers'); 

  runApp(const ProviderScope(child: MarketApp()));
}

class MarketApp extends StatelessWidget {
  const MarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market POS Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      locale: const Locale('tr', 'TR'),
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

  // Sayfalar Listesi - Tam 5 adet yapıldı
  final List<Widget> _pages = [
    const PosScreen(),       // index 0: Satış (POS)
    const InventoryScreen(), // index 1: Stok
    const ReportsPage(),     // index 2: Raporlar
    const CustomerScreen(),  // index 3: Müşteriler (HATA BURADAYDI, EKSİKTİ)
    const SettingsScreen(),  // index 4: Ayarlar
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // Alt taraftaki sıralama yukarıdaki _pages ile aynı olmalı
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Satış (POS)', // 0
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stok', // 1
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Raporlar', // 2
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline), // Müşteriler butonu
            selectedIcon: Icon(Icons.people),
            label: 'Müşteriler', // 3
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar', // 4
          ),
        ],
      ),
    );
  }
}