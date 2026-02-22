import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/market_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  final ScrollController _cartScrollController = ScrollController();

  void _handleBarcodeSubmit(String value) async {
    if (value.isEmpty) return;
    
    final success = await ref.read(cartProvider.notifier).addToCart(value);
    
    if (!success) {
      _showFeedback("Ürün bulunamadı veya stok yetersiz!", isError: true);
    } else {
      _scrollToBottom();
    }
    
    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_cartScrollController.hasClients) {
        _cartScrollController.animateTo(
          _cartScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack, // Küçük 'b' hatası düzeltildi
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

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Row(
        children: [
          // Sol Taraf: Ürün Giriş ve Liste
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildTopBar(),
                _buildBarcodeSection(),
                Expanded(
                  child: cartItems.isEmpty 
                    ? _buildEmptyState() 
                    : _buildCartTable(cartItems, cartNotifier),
                ),
              ],
            ),
          ),
          // Sağ Taraf: Özet ve Ödeme
          _buildCheckoutSidebar(cartItems, cartNotifier),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TERMINAL #01",
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6366F1), 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Hızlı Satış Paneli",
                style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
              ),
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
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Text("SİSTEM AKTİF", 
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800)),
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
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
          prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6366F1), size: 26),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          contentPadding: const EdgeInsets.all(28),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Row(
            children: [
              _buildProductLeading(item['category'] ?? 'Genel'),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("${item['price'].toStringAsFixed(2)} ₺ / ${item['unit'] ?? 'Adet'}", 
                      style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              _buildQuantityControls(item, notifier),
              const SizedBox(width: 32),
              SizedBox(
                width: 100,
                child: Text(
                  "${(item['price'] * item['qty']).toStringAsFixed(2)} ₺",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => notifier.removeFromCart(item['barcode']),
                icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.2), size: 22),
                hoverColor: Colors.redAccent.withValues(alpha: 0.1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductLeading(String category) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6366F1), size: 24),
    );
  }

  Widget _buildQuantityControls(Map item, CartNotifier notifier) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _qtyBtn(Icons.remove, () => notifier.updateQuantity(item['barcode'], (item['qty'] - 1).clamp(1, 999))),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text("${item['qty']}", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          _qtyBtn(Icons.add, () => notifier.updateQuantity(item['barcode'], item['qty'] + 1)),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
      ),
    );
  }

  Widget _buildCheckoutSidebar(List<Map<String, dynamic>> cartItems, CartNotifier notifier) {
    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1)),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ÖDEME DETAYI", 
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6366F1), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 32),
          _summaryRow("Ara Toplam", "${(notifier.totalAmount / 1.2).toStringAsFixed(2)} ₺"),
          _summaryRow("KDV Dahil", "${(notifier.totalAmount - (notifier.totalAmount / 1.2)).toStringAsFixed(2)} ₺", isSub: true),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          Text("GENEL TOPLAM", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              "${notifier.totalAmount.toStringAsFixed(2)} ₺",
              style: GoogleFonts.plusJakartaSans(fontSize: 68, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: -2),
            ),
          ),
          const Spacer(),
          _paymentActionBtn("NAKİT (F10)", Icons.payments_rounded, const Color(0xFF10B981), () => _handleComplete(cartItems, notifier, "NAKİT")),
          const SizedBox(height: 16),
          _paymentActionBtn("KREDİ KARTI (F11)", Icons.credit_card_rounded, const Color(0xFF6366F1), () => _handleComplete(cartItems, notifier, "KART")),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => notifier.clear(),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withValues(alpha: 0.5)),
              child: Text("İŞLEMİ İPTAL ET", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          )
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
          Text(label, style: GoogleFonts.plusJakartaSans(color: isSub ? Colors.white38 : Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _paymentActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 84,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 26),
        label: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
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
    _showFeedback("Satış Tamamlandı. Fiş Yazdırılıyor...");
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
            ),
            child: Icon(Icons.barcode_reader, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          ),
          const SizedBox(height: 24),
          Text("Satış Bekleniyor", 
            style: GoogleFonts.plusJakartaSans(fontSize: 20, color: Colors.white.withValues(alpha: 0.2), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}