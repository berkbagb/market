import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/pos_screen.dart';
import 'package:market/features/products/products_page.dart';
import 'package:market/features/reports/reports_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 1; // Başlangıç sayfası: Hızlı Satış

  // Sayfaları liste olarak tutuyoruz
  // Not: AddProductDialog yerine ProductsPage kullanıldı.
  final List<Widget> _pages = [
    const Center(child: _PlaceholderWidget(title: "Özet Panel", icon: Icons.grid_view_rounded)),
    const PosScreen(),
    const ProductsPage(), // Burası artık tam sayfa stok yönetimi
    const ReportsPage(),
    const Center(child: _PlaceholderWidget(title: "Cari & Veresiye", icon: Icons.people_rounded)),
  ];

  @override
  Widget build(BuildContext context) {
    // Tasarım Renkleri (Hata veren kısımlar burada tanımlandı)
    const Color primaryIndigo = Color(0xFF6366F1);
    const Color railBg = Color(0xFF020617);
    const Color scaffoldBg = Color(0xFF0F172A);

    // 1300 piksel altındaki ekranlarda menüyü daraltarak alandan tasarruf ediyoruz
    final bool isExtended = MediaQuery.of(context).size.width > 1300;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Row(
        children: [
          // --- MODERN NAVIGASYON MENÜSÜ (NavigationRail) ---
          NavigationRail(
            backgroundColor: railBg,
            selectedIndex: _selectedIndex,
            extended: isExtended,
            minExtendedWidth: 240,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            // Üst Logo Bölümü
            leading: _buildRailLeading(isExtended, primaryIndigo),
            
            // Stil Düzenlemeleri
            unselectedIconTheme: const IconThemeData(color: Colors.white24, size: 24),
            selectedIconTheme: const IconThemeData(color: primaryIndigo, size: 28),
            unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
              color: Colors.white24, 
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: Text('Özet Panel'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bolt_outlined),
                selectedIcon: Icon(Icons.bolt_rounded),
                label: Text('Hızlı Satış'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: Text('Stok Yönetimi'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: Text('Raporlar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: Text('Cari/Veresiye'),
              ),
            ],
            
            // Alt Ayarlar & Profil
            trailing: _buildRailTrailing(isExtended),
          ),

          // İnce Ayırıcı
          const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),

          // --- ANA İÇERİK (Animasyonlu Sayfa Geçişi) ---
          Expanded(
            child: Container(
              color: scaffoldBg,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.01, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: _pages[_selectedIndex],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailLeading(bool isExtended, Color primaryIndigo) {
    return Column(
      children: [
        const SizedBox(height: 32),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryIndigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryIndigo.withOpacity(0.2)),
          ),
          child: Icon(Icons.storefront_rounded, color: primaryIndigo, size: 30),
        ),
        if (isExtended) ...[
          const SizedBox(height: 16),
          Text(
            "BERK MARKET",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "SİSTEM YÖNETİCİSİ",
              style: GoogleFonts.plusJakartaSans(
                color: primaryIndigo.withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRailTrailing(bool isExtended) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.settings_suggest_outlined, color: Colors.white24),
                onPressed: () {
                  // Ayarlar sayfasını açabilirsin
                },
                tooltip: "Ayarlar",
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                child: Text(
                  "B", 
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderWidget({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withOpacity(0.03)),
          const SizedBox(height: 16),
          Text(
            "$title Çok Yakında",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.1),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}