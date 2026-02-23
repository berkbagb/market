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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2D),
        elevation: 0,
        title: Text("Stok Yönetimi", 
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF6366F1), size: 32),
            onPressed: () => _openAddProductDialog(context, ref),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu (Sabit Genişlik ve Ortalanmış)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            color: const Color(0xFF1A1D2D),
            child: Center(
              child: SizedBox(
                width: 600,
                child: TextField(
                  onChanged: (v) => ref.read(productsProvider.notifier).filterProducts(v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ürün veya Barkod Ara...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                    filled: true,
                    fillColor: const Color(0xFF0F111A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (list) => ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                itemBuilder: (ctx, i) => _buildProductCard(ref, list[i], context),
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              error: (e, s) => Center(child: Text("Hata: $e", style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(WidgetRef ref, Product p, BuildContext context) {
    return Card(
      color: const Color(0xFF1A1D2D),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("Barkod: ${p.barcode}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₺${p.sellPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                Text("Stok: ${p.stock}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 15),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, ref, p),
            ),
          ],
        ),
      ),
    );
  }

  // --- ÜRÜN EKLEME / GÜNCELLEME DİALOĞU ---
  void _openAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameC = TextEditingController();
    final barC = TextEditingController();
    final priceC = TextEditingController();
    final stockC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ürün İşlemi", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogInput(nameC, "Ürün Adı (Yeni Ürünse)"),
              _dialogInput(barC, "Barkod"),
              Row(
                children: [
                  Expanded(child: _dialogInput(priceC, "Yeni Fiyat", isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _dialogInput(stockC, "Eklenecek Stok", isNum: true)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              final barcode = barC.text.trim();
              if (barcode.isEmpty) return;

              final products = ref.read(productsProvider).value ?? [];
              final existing = products.where((p) => p.barcode == barcode).firstOrNull;

              if (existing != null) {
                // EĞER ÜRÜN VARSA ONAY PENCERESİNE GİT
                final addedStock = int.tryParse(stockC.text) ?? 0;
                final newPrice = double.tryParse(priceC.text) ?? 0.0;
                
                Navigator.pop(context); // Önceki dialoğu kapat
                _showUpdateConfirmation(context, ref, existing, addedStock, newPrice);
              } else {
                // ÜRÜN YOKSA DİREKT EKLE
                final p = Product(
                  name: nameC.text.isEmpty ? "İsimsiz Ürün" : nameC.text,
                  barcode: barcode,
                  buyPrice: 0,
                  sellPrice: double.tryParse(priceC.text) ?? 0,
                  stock: int.tryParse(stockC.text) ?? 0,
                  minStockLevel: 5, taxRate: 20, unit: "Adet", category: "Genel",
                );
                await ref.read(productsProvider.notifier).addProduct(p);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- GÜNCELLEME ONAYI (EMİN MİSİN ŞEYİ) ---
  void _showUpdateConfirmation(BuildContext context, WidgetRef ref, Product existing, int added, double newPrice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2D),
        title: const Text("Ürün Güncellensin mi?", style: TextStyle(color: Colors.orangeAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ürün: ${existing.name}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Yeni Stok: ${existing.stock + added} (Mevcut: ${existing.stock})", style: const TextStyle(color: Colors.white70)),
            if (newPrice > 0)
              Text("Yeni Fiyat: ₺$newPrice (Eski: ₺${existing.sellPrice})", style: const TextStyle(color: Colors.greenAccent)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hayır", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              final updated = existing.copyWith(
                stock: existing.stock + added,
                sellPrice: newPrice > 0 ? newPrice : existing.sellPrice,
              );
              await ref.read(productsProvider.notifier).updateProduct(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Evet, Güncelle", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // --- SİLME ONAYI ---
  void _confirmDelete(BuildContext context, WidgetRef ref, Product p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2D),
        title: const Text("Ürünü Sil?", style: TextStyle(color: Colors.redAccent)),
        content: Text("${p.name} ürünü kalıcı olarak silinecek. Emin misiniz?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProduct(p.id!);
              Navigator.pop(context);
            },
            child: const Text("Evet, Sil"),
          ),
        ],
      ),
    );
  }

  Widget _dialogInput(TextEditingController c, String l, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF0F111A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}