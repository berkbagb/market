import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/market_provider.dart';

// KDV oranını her yerden erişilebilir kılan provider

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final currentTax = ref.watch(globalTaxProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2D),
        elevation: 0,
        title: Text(
          "Yönetici Paneli & Özet",
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İSTATİSTİK KARTLARI
            Row(
              children: [
                _buildStatCard(
                  "Toplam Ürün",
                  "124",
                  Icons.inventory_2,
                  Colors.blueAccent,
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  "Günlük Ciro",
                  "₺4,250.00",
                  Icons.payments,
                  Colors.greenAccent,
                ),
                _buildStatCard(
                  "Mevcut KDV",
                  "%${currentTax.toInt()}",
                  Icons.percent,
                  Colors.orangeAccent,
                ),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOL: YÖNETİCİ AYARLARI
                Expanded(flex: 1, child: _buildAdminSettings(context, ref)),
                const SizedBox(width: 25),
                // SAĞ: KRİTİK STOK LİSTESİ
                Expanded(
                  flex: 1,
                  child: _buildCriticalStockList(productsAsync),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSettings(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2D),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sistem Ayarları",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _settingTile(
            Icons.store,
            "Mağaza Bilgileri",
            "İsim ve Adres",
            () => _showStoreInfoDialog(context, ref), // Burayı böyle bağla!
          ),

          // VERGİ AYARI BURADA
          _settingTile(
            Icons.percent,
            "Vergi Ayarları",
            "KDV Oranını Düzenle",
            () => _showTaxSettingsDialog(context, ref), // ref eklendi
          ),

          const Divider(color: Colors.white10, height: 40),
          _settingTile(
            Icons.delete_sweep,
            "Verileri Sıfırla",
            "Fabrika Ayarları",
            () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _showStoreInfoDialog(BuildContext context, WidgetRef ref) {
    final currentStore = ref.read(storeInfoProvider);
    final nameC = TextEditingController(text: currentStore.name);
    final phoneC = TextEditingController(text: currentStore.phone);
    final addrC = TextEditingController(text: currentStore.address);
    final footerC = TextEditingController(text: currentStore.footerNote);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2D),
        title: const Text(
          "Mağaza Bilgilerini Düzenle",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogInputCustom(nameC, "Mağaza Adı"),
              _dialogInputCustom(phoneC, "Telefon"),
              _dialogInputCustom(addrC, "Adres"),
              _dialogInputCustom(footerC, "Fiş Alt Notu"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            onPressed: () {
              ref.read(storeInfoProvider.notifier).state = currentStore
                  .copyWith(
                    name: nameC.text,
                    phone: phoneC.text,
                    address: addrC.text,
                    footerNote: footerC.text,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mağaza bilgileri güncellendi.")),
              );
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // Yardımcı input widget'ı
  Widget _dialogInputCustom(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF0F111A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // --- KDV AYAR DİALOGU (HATASIZ VERSİYON) ---
  void _showTaxSettingsDialog(BuildContext context, WidgetRef ref) {
    // taxController burada tanımlandı (Hata 1 çözüldü)
    final taxController = TextEditingController(
      text: ref.read(globalTaxProvider).toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2D),
        title: const Text(
          "KDV Ayarları",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Yeni ürünler için varsayılan KDV oranı:",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: taxController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: "Genel KDV (%)",
                  filled: true,
                  fillColor: const Color(0xFF0F111A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            onPressed: () {
              // ref artık tanımlı (Hata 2 çözüldü)
              final yeniOran = double.tryParse(taxController.text) ?? 20.0;
              ref.read(globalTaxProvider.notifier).state = yeniOran;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Yeni KDV: %$yeniOran")));
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // DİĞER YARDIMCI WIDGETLAR (Aynı kaldı)
  Widget _settingTile(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : const Color(0xFF6366F1),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
        ),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(color: Colors.white24, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white10),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2D),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalStockList(AsyncValue productsAsync) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2D),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kritik Stoklar",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          productsAsync.when(
            data: (list) {
              final critical = (list as List)
                  .where((p) => (p.stock as int) <= 5)
                  .toList();
              if (critical.isEmpty)
                return const Text(
                  "Sorun yok.",
                  style: TextStyle(color: Colors.greenAccent),
                );
              return Column(
                children: critical
                    .take(5)
                    .map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          p.name,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          "${p.stock} Adet",
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text("Hata: $e"),
          ),
        ],
      ),
    );
  }
}
