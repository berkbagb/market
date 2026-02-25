import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/pos_screen.dart';
import 'package:market/features/inventory/inventory_screen.dart';
import 'package:market/features/customers/customer_screen.dart'; 
import 'package:market/features/dashboard/summary_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 1. LİSTE: Buradaki ekran sayısı ile aşağıdaki buton sayısı EŞİT olmalı (Şu an 5 adet)
  final List<Widget> _screens = [
    const PosScreen(),       // 0
    const InventoryScreen(), // 1
    const SummaryScreen(),   // 2
    const CustomerScreen(),  // 3 (Senin istediğin Müşteriler)
    const Scaffold(backgroundColor: Color(0xFF020617), body: Center(child: Text("Ayarlar", style: TextStyle(color: Colors.white)))), // 4 (Ayarlar için geçici ekran)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          // ÇOK KRİTİK: 5 eleman varsa bu 'fixed' olmak zorunda!
          type: BottomNavigationBarType.fixed, 
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: const Color(0xFF818CF8),
          unselectedItemColor: const Color(0xFF475569),
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
          
          // 2. BUTONLAR: Burada da tam 5 tane eleman var.
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_outlined),
              activeIcon: Icon(Icons.point_of_sale_rounded),
              label: 'Satış',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Satok',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Raporlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge_rounded),
              label: 'Müşateriler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}