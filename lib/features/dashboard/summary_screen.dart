import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/market_provider.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verileri Provider'lardan çekiyoruz
    final productsAsync = ref.watch(productsProvider);
    final currentTax = ref.watch(globalTaxProvider);
    final customers = ref.watch(customerProvider);
    final todayStats = ref.watch(todayStatsProvider);

    // Borç hesaplaması
    double totalDebt = customers.fold(0, (sum, item) => sum + (item.balance > 0 ? item.balance : 0));

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          "Yönetici Paneli & Özet",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ÜST İSTATİSTİK KARTLARI
            todayStats.when(
              data: (stats) => Row(
                children: [
                  _buildStatCard("Günlük Ciro", "₺${stats['revenue']?.toStringAsFixed(2)}", Icons.payments, Colors.greenAccent),
                  const SizedBox(width: 15),
                  _buildStatCard("Toplam Veresiye", "₺${totalDebt.toStringAsFixed(2)}", Icons.trending_up, Colors.orangeAccent),
                  const SizedBox(width: 15),
                  _buildStatCard("Mevcut KDV", "%${currentTax.toInt()}", Icons.percent, Colors.blueAccent),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text("Hata: $e", style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 30),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOL TARAF: AYARLAR VE SİSTEM
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildAdminSettings(context, ref),
                      const SizedBox(height: 20),
                      _buildCriticalStockList(productsAsync),
                    ],
                  ),
                ),
                const SizedBox(width: 25),

                // SAĞ TARAF: VERESİYE LİSTESİ
                Expanded(
                  flex: 1,
                  child: _buildDebtList(customers),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- AYARLAR PANELİ ---
  Widget _buildAdminSettings(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sistem Ayarları", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _settingTile(Icons.store, "Mağaza Bilgileri", "İsim, Telefon ve Fiş Notu", () => _showStoreInfoDialog(context, ref)),
          _settingTile(Icons.percent, "Vergi Ayarları", "KDV Oranını Güncelle", () => _showTaxSettingsDialog(context, ref)),
          const Divider(color: Colors.white10, height: 40),
          _settingTile(Icons.delete_sweep, "Verileri Sıfırla", "Tüm kayıtları kalıcı olarak siler", () {}, isDestructive: true),
        ],
      ),
    );
  }

  // --- KRİTİK STOK LİSTESİ ---
  Widget _buildCriticalStockList(AsyncValue productsAsync) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kritik Stoklar (5 ve altı)", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          productsAsync.when(
            data: (list) {
              final critical = (list as List).where((p) => (p.stock as num) <= 5).toList();
              if (critical.isEmpty) return const Text("Stok durumu gayet iyi.", style: TextStyle(color: Colors.greenAccent));
              return Column(
                children: critical.take(5).map((p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  trailing: Text("${p.stock} Adet", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                )).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text("Hata: $e"),
          ),
        ],
      ),
    );
  }

  // --- VERESİYE LİSTESİ ---
  Widget _buildDebtList(List<Customer> customers) {
    final debtList = customers.where((c) => c.balance > 0).toList();
    debtList.sort((a, b) => b.balance.compareTo(a.balance));

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Borçlu Listesi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (debtList.isEmpty)
            const Text("Borcu olan müşteri bulunmuyor.", style: TextStyle(color: Colors.white38))
          else
            ...debtList.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(radius: 15, backgroundColor: Colors.orange.withOpacity(0.1), child: Text(c.name[0], style: const TextStyle(color: Colors.orange, fontSize: 12))),
                  const SizedBox(width: 12),
                  Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text("₺${c.balance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  // --- YARDIMCI METOTLAR (DİALOGLAR) ---
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
        title: const Text("Mağaza Bilgileri", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInput(nameC, "Mağaza Adı"),
            _dialogInput(phoneC, "Telefon"),
            _dialogInput(addrC, "Adres"),
            _dialogInput(footerC, "Fiş Alt Notu"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () {
              ref.read(storeInfoProvider.notifier).state = currentStore.copyWith(
                name: nameC.text, phone: phoneC.text, address: addrC.text, footerNote: footerC.text,
              );
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _showTaxSettingsDialog(BuildContext context, WidgetRef ref) {
    final taxController = TextEditingController(text: ref.read(globalTaxProvider).toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2D),
        title: const Text("KDV Ayarı", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: taxController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Yeni KDV Oranı (%)", labelStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              ref.read(globalTaxProvider.notifier).state = double.tryParse(taxController.text) ?? 20.0;
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Widget _dialogInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38)),
    );
  }

  Widget _settingTile(IconData icon, String title, String sub, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : const Color(0xFF6366F1)),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.white24, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white10, size: 16),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.1))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 15),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}