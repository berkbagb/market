import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/pos_screen.dart';
import 'package:market/features/dashboard/dashboard_page.dart';
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

  // Sayfalar arası geçişte state korunması için IndexedStack kullanılır
  // final List<Widget> _screens = [
  //   const PosScreen(),
  //   const DashboardPage(), 
  //   const InventoryScreen(), 
  //   const CustomerScreen(), 
  // ];
  final List<Widget> _screens = [
    const PosScreen(),
    const SummaryScreen(), // DashboardPage yerine SummaryScreen yazdık
    const InventoryScreen(), 
    const CustomerScreen(), 
  ];
  @override
  Widget build(BuildContext context) {
    // V3 Kurumsal Renk Paleti (ThemeData ile uyumlu)
    const Color scaffoldBg = Color(0xFF020617);
    const Color navBarBg = Color(0xFF0F172A);
    const Color activeColor = Color(0xFF818CF8); // Soft Indigo
    const Color inactiveColor = Color(0xFF475569); // Slate Gray

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarBg,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.transparent, // Container rengini kullanır
              selectedItemColor: activeColor,
              unselectedItemColor: inactiveColor,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              items: [
                _buildNavItem(
                  icon: Icons.point_of_sale_outlined,
                  activeIcon: Icons.point_of_sale_rounded,
                  label: 'Satış (POS)',
                ),
                _buildNavItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics_rounded,
                  label: 'Özet',
                ),
                _buildNavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Stok',
                ),
                _buildNavItem(
                  icon: Icons.badge_outlined,
                  activeIcon: Icons.badge_rounded,
                  label: 'Müşteriler',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(icon, size: 22),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(activeIcon, size: 24),
      ),
      label: label,
    );
  }
}