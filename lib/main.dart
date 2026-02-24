// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:window_manager/window_manager.dart';
// import 'package:intl/date_symbol_data_local.dart';

// // Özelliklerin importları
// import 'package:market/features/pos/pos_screen.dart'; 
// import 'package:market/features/inventory/inventory_screen.dart';
// import 'package:market/features/reports/reports_page.dart';
// import 'package:market/features/settings/settings_screen.dart';

// void main() async {
//   // 1. Flutter motorunu başlat
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // 2. Dil ayarları
//   await initializeDateFormatting('tr_TR', null);

//   // 3. Pencere Ayarları
//   await windowManager.ensureInitialized();
//   WindowOptions windowOptions = const WindowOptions(
//     size: Size(1360, 850),
//     center: true,
//     title: "BERK MARKET - POS PRO",
//   );
  
//   windowManager.waitUntilReadyToShow(windowOptions, () async {
//     await windowManager.show();
//     await windowManager.focus();
//   });

//   // 4. Hive Veritabanı
//   await Hive.initFlutter();
//   await Hive.openBox('customers'); 

//   runApp(
//     const ProviderScope(
//       child: MarketApp(),
//     ),
//   );
// }

// class MarketApp extends StatelessWidget {
//   const MarketApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Market POS Pro',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         brightness: Brightness.dark,
//         scaffoldBackgroundColor: const Color(0xFF020617),
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6366F1),
//           brightness: Brightness.dark,
//         ),
//         // Yazı tipi ayarları
//         textTheme: GoogleFonts.plusJakartaSansTextTheme(
//           ThemeData.dark().textTheme,
//         ).apply(bodyColor: Colors.white, displayColor: Colors.white),
//       ),
//       locale: const Locale('tr', 'TR'),
//       home: const MainNavigationScreen(), 
//     );
//   }
// }

// // ANA NAVİGASYON EKRANI (TAB BAR)
// class MainNavigationScreen extends StatefulWidget {
//   const MainNavigationScreen({super.key});

//   @override
//   State<MainNavigationScreen> createState() => _MainNavigationScreenState();
// }

// class _MainNavigationScreenState extends State<MainNavigationScreen> {
//   int _currentIndex = 0;

//   // Sayfalar Listesi
//   final List<Widget> _pages = [
//     const PosScreen(),       // 0: Satış
//     const InventoryScreen(), // 1: Stok
//     const ReportsPage(),     // 2: Raporlar
//     const SettingsScreen(),  // 3: Ayarlar
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // IndexedStack kullanarak sayfalar arası geçişte verilerin kaybolmamasını sağlıyoruz
//       body: IndexedStack(
//         index: _currentIndex,
//         children: _pages,
//       ),
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _currentIndex,
//         onDestinationSelected: (int index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.shopping_cart_outlined),
//             selectedIcon: Icon(Icons.shopping_cart),
//             label: 'Satış (POS)',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.inventory_2_outlined),
//             selectedIcon: Icon(Icons.inventory_2),
//             label: 'Stok',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.analytics_outlined),
//             selectedIcon: Icon(Icons.analytics),
//             label: 'Raporlar',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.settings_outlined),
//             selectedIcon: Icon(Icons.settings),
//             label: 'Ayarlar',
//           ),
//         ],
//       ),
//     );
//   }
// }

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop: initialize sqflite FFI so global openDatabase works
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } catch (e) {
      debugPrint('sqflite FFI init failed: $e');
    }
  }

  await initializeDateFormatting('tr_TR', null);

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

  await Hive.initFlutter();
  await Hive.openBox('customers'); 

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

  final List<Widget> _pages = [
    const PosScreen(),
    const InventoryScreen(),
    const ReportsPage(),
    const SettingsScreen(),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Satış (POS)',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stok',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Raporlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}