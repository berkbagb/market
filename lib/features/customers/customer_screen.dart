import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/market_provider.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Market provider içindeki müşteri listesini dinle
    final customers = ref.watch(customerProvider);
    
    // Arama filtresi
    final filteredList = customers.where((c) {
      return c.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
             c.phone.contains(_searchController.text);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Üst Başlık Alanı
          _buildSliverHeader(context),
          
          // Arama Çubuğu
          SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),

          // Müşteri Kartları
          filteredList.isEmpty
              ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Ekranı 3'e böler (Windows için ideal)
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 2.5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _customerCard(filteredList[index]),
                      childCount: filteredList.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF020617),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        centerTitle: false,
        title: Text(
          "Müşteri Portföyü",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 20),
        ),
        background: Stack(
          children: [
            Positioned(
              right: -30,
              top: -10,
              child: Icon(Icons.people_alt_rounded, size: 220, color: Colors.white.withOpacity(0.02)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
              child: Opacity(
                opacity: 0.4,
                child: Text(
                  "Sadakat sistemini ve müşteri borçlarını\nburadan yönetin.",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20, top: 8),
          child: IconButton(
            onPressed: () => _showAddCustomerDialog(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() {}),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Müşteri ismi veya telefon...",
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
    );
  }

// Müşteri kartını bu şekilde güncelle (InkWell ekledik)
Widget _customerCard(Customer customer) {
  return InkWell(
    onTap: () => _showTransactionDialog(customer), // Tıklayınca işlem açılır
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: Text(customer.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(customer.phone, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${customer.balance.toStringAsFixed(2)} ₺", 
                style: TextStyle(
                  color: customer.balance >= 0 ? Colors.redAccent : Colors.greenAccent, 
                  fontWeight: FontWeight.w900,
                  fontSize: 16
                )),
              Text(customer.balance >= 0 ? "BORÇ" : "ALACAK", 
                style: const TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  );
}

// Borç Ekle / Ödeme Al Penceresi
void _showTransactionDialog(Customer customer) {
  final amountC = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text("${customer.name} - İşlem Yap", style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Mevcut Bakiye: ${customer.balance.toStringAsFixed(2)} ₺", 
               style: TextStyle(color: customer.balance >= 0 ? Colors.redAccent : Colors.greenAccent)),
          const SizedBox(height: 20),
          _dialogInput(amountC, "Miktar (₺)"),
        ],
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        // Tahsilat (Ödeme Aldık, Borç Azalır)
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.2), foregroundColor: Colors.green),
          onPressed: () {
            final val = double.tryParse(amountC.text) ?? 0;
            ref.read(customerProvider.notifier).updateBalance(customer.id, -val);
            Navigator.pop(context);
          },
          child: const Text("ÖDEME AL"),
        ),
        // Borç Yaz (Veresiye Verdik, Borç Artar)
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), foregroundColor: Colors.red),
          onPressed: () {
            final val = double.tryParse(amountC.text) ?? 0;
            ref.read(customerProvider.notifier).updateBalance(customer.id, val);
            Navigator.pop(context);
          },
          child: const Text("BORÇ EKLE"),
        ),
      ],
    ),
  );
}
  void _showAddCustomerDialog(BuildContext context) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2D),
        title: const Text("Yeni Müşteri Kaydı", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInput(nameC, "Ad Soyad"),
            const SizedBox(height: 10),
            _dialogInput(phoneC, "Telefon"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              ref.read(customerProvider.notifier).addCustomer(nameC.text, phoneC.text);
              Navigator.pop(context);
            }, 
            child: const Text("Kaydet")
          ),
        ],
      ),
    );
  }

  Widget _dialogInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF020617),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Müşteri bulunamadı.", style: TextStyle(color: Colors.white24)));
  }
}