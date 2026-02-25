import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/market_provider.dart';
import 'package:market/features/customers/customer_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  final ScrollController _cartScrollController = ScrollController();
  final TextEditingController _customerSearchController = TextEditingController();

  void _handleBarcodeSubmit(String value) async {
    if (value.isEmpty) return;
    final success = await ref.read(cartProvider.notifier).addToCart(value);
    if (!success) {
      _showFeedback("Ürün bulunamadı!", isError: true);
    } else {
      _scrollToBottom();
    }
    _barcodeController.clear();
    Future.microtask(() {
      if (mounted) _barcodeFocusNode.requestFocus();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cartScrollController.hasClients) {
        _cartScrollController.animateTo(
          _cartScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
        );
      }
    });
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.watch(cartProvider.notifier);
    final activeTax = ref.watch(globalTaxProvider);
    final store = ref.watch(storeInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildTopBar(store),
                _buildBarcodeSection(),
                Expanded(
                  child: cartItems.isEmpty
                      ? _buildEmptyState()
                      : _buildCartTable(cartItems, cartNotifier),
                ),
              ],
            ),
          ),
          _buildCheckoutSidebar(cartItems, cartNotifier, activeTax),
        ],
      ),
    );
  }

  Widget _buildTopBar(StoreInfo store) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TERMINAL #01", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6366F1), fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
              const SizedBox(height: 4),
              Text(store.name, style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          const Spacer(),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Text("SİSTEM AKTİF", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildBarcodeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: TextField(
        controller: _barcodeController,
        focusNode: _barcodeFocusNode,
        autofocus: true,
        onSubmitted: _handleBarcodeSubmit,
        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Ürün barkodunu tarayın...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
          prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6366F1), size: 26),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          contentPadding: const EdgeInsets.all(28),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCartTable(List<Map<String, dynamic>> items, CartNotifier notifier) {
    return ListView.builder(
      controller: _cartScrollController,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6366F1)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("${item['price']} ₺", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              _buildQuantityControls(item, notifier),
              const SizedBox(width: 20),
              Text("${(item['price'] * item['qty']).toStringAsFixed(2)} ₺", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white24), onPressed: () => notifier.removeFromCart(item['barcode'])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuantityControls(Map item, CartNotifier notifier) {
    return Row(
      children: [
        IconButton(onPressed: () => notifier.updateQuantity(item['barcode'], (item['qty'] - 1).clamp(1, 99)), icon: const Icon(Icons.remove, color: Color(0xFF6366F1))),
        Text("${item['qty']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        IconButton(onPressed: () => notifier.updateQuantity(item['barcode'], item['qty'] + 1), icon: const Icon(Icons.add, color: Color(0xFF6366F1))),
      ],
    );
  }

  // HATANIN ÇÖZÜLDÜĞÜ YER BURASI:
  Widget _buildCheckoutSidebar(List<Map<String, dynamic>> cartItems, CartNotifier notifier, double taxRate) {
    final double total = notifier.totalAmount;
    final double netFiyat = total / (1 + (taxRate / 100));
    final double kdvTutari = total - netFiyat;

    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SingleChildScrollView( // Kaydırma eklendi
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Sıkışmayı önler
          children: [
            Text("ÖDEME DETAYI", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6366F1), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)),
            const SizedBox(height: 32),
            _summaryRow("Ara Toplam (KDV Hariç)", "${netFiyat.toStringAsFixed(2)} ₺"),
            _summaryRow("KDV (%${taxRate.toInt()})", "${kdvTutari.toStringAsFixed(2)} ₺", isSub: true),
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 24),
            Text("GENEL TOPLAM", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            FittedBox(
              child: Text("${total.toStringAsFixed(2)} ₺", style: GoogleFonts.plusJakartaSans(fontSize: 68, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: -2)),
            ),
            
            // Spacer() yerine sabit boşluk kullanıldı:
            const SizedBox(height: 48), 
            
            _paymentActionBtn("NAKİT (F10)", Icons.payments_rounded, const Color(0xFF10B981), () => _handleComplete(cartItems, notifier, "NAKİT")),
            const SizedBox(height: 12),
            _paymentActionBtn("KREDİ KARTI (F11)", Icons.credit_card_rounded, const Color(0xFF6366F1), () => _handleComplete(cartItems, notifier, "KART")),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: cartItems.isEmpty ? null : () => _showCustomerSelectionDialog(context, ref, total),
                icon: const Icon(Icons.person_search_rounded),
                label: const Text("VERESİYE / MÜŞTERİ"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  foregroundColor: Colors.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Colors.orange, width: 1),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => notifier.clear(),
                child: Text("İŞLEMİ İPTAL ET", style: GoogleFonts.plusJakartaSans(color: Colors.redAccent.withOpacity(0.5), fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerSelectionDialog(BuildContext context, WidgetRef ref, double total) {
    _customerSearchController.clear();
    ref.read(customersProvider.notifier).refresh();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final customers = ref.watch(customersProvider);
            
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Colors.white10)),
              title: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text("Veresiye İçin Müşteri Seç", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 600,
                child: Column(
                  children: [
                    TextField(
                      controller: _customerSearchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => ref.read(customersProvider.notifier).refresh(query: val),
                      decoration: InputDecoration(
                        hintText: "Müşteri ara (İsim veya Tel)...",
                        hintStyle: const TextStyle(color: Colors.white24),
                        prefixIcon: const Icon(Icons.search, color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: customers.isEmpty 
                      ? const Center(child: Text("Müşteri bulunamadı.", style: TextStyle(color: Colors.white24)))
                      : ListView.separated(
                          itemCount: customers.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                child: Text(customer.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1))),
                              ),
                              title: Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(customer.phone, style: const TextStyle(color: Colors.white38)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("${customer.balance.toStringAsFixed(2)} ₺", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  const Text("Mevcut Borç", style: TextStyle(color: Colors.white24, fontSize: 10)),
                                ],
                              ),
                              onTap: () {
                                ref.read(customersProvider.notifier).addDebt(customer.id!, total);
                                ref.read(cartProvider.notifier).clear();
                                Navigator.pop(context);
                                _showFeedback("${customer.name} hesabına borç işlendi.");
                              },
                            );
                          },
                        ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddCustomerDialog(context, ref),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text("Yeni Müşteri Oluştur"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Yeni Müşteri", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Ad Soyad", labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Telefon", labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(customersProvider.notifier).addCustomer(nameCtrl.text, phoneCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isSub = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(color: isSub ? Colors.white38 : Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _paymentActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  void _handleComplete(List<Map<String, dynamic>> items, CartNotifier n, String method) async {
    if (items.isEmpty) {
      _showFeedback("Lütfen ürün ekleyin!", isError: true);
      return;
    }
    await n.completeSale(method);
    _showFeedback("Satış Tamamlandı.");
  }

  Widget _buildEmptyState() {
    return Center(child: Icon(Icons.barcode_reader, size: 80, color: Colors.white.withOpacity(0.05)));
  }
}