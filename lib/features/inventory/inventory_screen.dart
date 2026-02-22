import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/market_provider.dart';
import 'package:market/core/models/product_model.dart'; 

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            productsAsync.when(
              data: (products) => _buildStatCards(products),
              loading: () => const SizedBox(
                height: 100, 
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
              ),
              error: (e, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _buildMainTable(productsAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Stok Envanteri",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32, 
                fontWeight: FontWeight.w800, 
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Ürün durumlarını ve stok seviyelerini gerçek zamanlı takip edin.",
              style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            _headerActionBtn(Icons.file_download_outlined, "Dışa Aktar", () {}),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Yeni Ürün Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerActionBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildStatCards(List<Product> products) {
    // Null kontrolleri (?? 0) kaldırıldı çünkü Product modeli artık kesin değerler dönüyor
    final totalValue = products.fold<double>(0, (sum, p) => sum + (p.sellPrice * p.stock));
    final lowStockCount = products.where((p) => p.stock < 10).length;

    return Row(
      children: [
        _statCard("Toplam Çeşit", products.length.toString(), Icons.inventory_2_outlined, Colors.blueAccent),
        const SizedBox(width: 20),
        _statCard("Kritik Stok", lowStockCount.toString(), Icons.auto_graph_rounded, Colors.orangeAccent),
        const SizedBox(width: 20),
        _statCard("Envanter Değeri", "₺${totalValue.toStringAsFixed(0)}", Icons.account_balance_wallet_outlined, Colors.greenAccent),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMainTable(AsyncValue<List<Product>> productsAsync) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: productsAsync.when(
          data: (products) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Theme(
              data: ThemeData.dark().copyWith(dividerColor: Colors.white10),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
                dataRowMaxHeight: 70,
                columnSpacing: 24,
                columns: [
                  DataColumn(label: _tableHeader("ÜRÜN BİLGİSİ")),
                  DataColumn(label: _tableHeader("BARKOD")),
                  DataColumn(label: _tableHeader("SATIŞ FİYATI")),
                  DataColumn(label: _tableHeader("STOK")),
                  DataColumn(label: _tableHeader("DURUM")),
                  const DataColumn(label: Text("")),
                ],
                rows: products.map((p) => DataRow(
                  cells: [
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(p.barcode, style: const TextStyle(color: Colors.white38, fontFamily: 'monospace'))),
                    DataCell(Text("₺${p.sellPrice.toStringAsFixed(2)}")),
                    DataCell(Text("${p.stock} ${p.unit}")),
                    // Hatalı olan p.stock ?? 0 kısımları temizlendi
                    DataCell(_statusBadge(p.stock.toDouble())),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1)),
                        onPressed: () {},
                      ),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
          error: (e, s) => Center(child: Text("Hata oluştu: $e", style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF6366F1), 
        fontWeight: FontWeight.w800, 
        fontSize: 12,
        letterSpacing: 1,
      ),
    );
  }

  Widget _statusBadge(double stock) {
    final bool isLow = stock < 10 && stock > 0;
    final bool isCritical = stock <= 0;
    
    Color color = isCritical ? Colors.red : (isLow ? Colors.orange : Colors.green);
    String label = isCritical ? "Tükendi" : (isLow ? "Kritik" : "Stokta");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label, 
        style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.bold)
      ),
    );
  }
}