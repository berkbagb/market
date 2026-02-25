import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/core/models/product_model.dart';
import 'package:market/features/pos/market_provider.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();

  // Kontrolcüler
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController(text: "5.0");

  // State Değişkenleri
  String _selectedUnit = "adet";
  int _selectedTax = 20;
  String _selectedCategory = "Genel"; 
  double _calculatedMargin = 0.0;

  @override
  void initState() {
    super.initState();
    _buyPriceController.addListener(_calculateProfit);
    _sellPriceController.addListener(_calculateProfit);
  }

  void _calculateProfit() {
    final buy = double.tryParse(_buyPriceController.text) ?? 0;
    final sell = double.tryParse(_sellPriceController.text) ?? 0;
    if (buy > 0) {
      setState(() {
        _calculatedMargin = ((sell - buy) / buy) * 100;
      });
    } else {
      setState(() => _calculatedMargin = 0.0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final double buyPrice = double.tryParse(_buyPriceController.text) ?? 0.0;
      final double sellPrice = double.tryParse(_sellPriceController.text) ?? 0.0;
      final double stock = double.tryParse(_stockController.text) ?? 0.0;
      final double minStock = double.tryParse(_minStockController.text) ?? 5.0;

      final newProduct = Product(
        id: null,
        barcode: _barcodeController.text.trim(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock.toDouble(), 
        minStockLevel: minStock.toDouble(),
        unit: _selectedUnit,
        taxRate: _selectedTax.toDouble(),
      );

      try {
        await ref.read(productsProvider.notifier).addProduct(newProduct);

        if (mounted) {
          Navigator.pop(context);
          _showSuccessSheet(newProduct.name);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar("Kayıt sırasında hata oluştu: $e");
        }
      }
    }
  }

  void _showSuccessSheet(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text("$name başarıyla envantere eklendi."),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    const Color primaryBlue = Color(0xFF6366F1);
    const Color cardBg = Color(0xFF0F172A);

    return Dialog(
      backgroundColor: cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(primaryBlue),
                const SizedBox(height: 32),
                _buildSectionTitle("TEMEL BİLGİLER"),
                _buildField(_barcodeController, "Barkod Numarası", Icons.qr_code_scanner_rounded, isRequired: true),
                _buildField(_nameController, "Ürün Tanımı (Ad/Marka)", Icons.shopping_bag_outlined, isRequired: true),
                
                categoriesAsync.when(
                  data: (categoriesList) => _buildCategoryDropdown(categoriesList),
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (err, stack) => _buildField(TextEditingController(text: "Genel"), "Kategori Hatası", Icons.error_outline),
                ),

                const SizedBox(height: 24),
                _buildSectionTitle("MALİYET & SATIŞ"),
                Row(
                  children: [
                    Expanded(child: _buildField(_buyPriceController, "Alış (₺)", Icons.south_east_rounded, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField(_sellPriceController, "Satış (₺)", Icons.north_east_rounded, isNumber: true)),
                  ],
                ),
                _buildProfitIndicator(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<String>(
                        label: "Birim",
                        value: _selectedUnit,
                        items: ["adet", "kg", "lt", "paket", "koli"],
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown<int>(
                        label: "KDV Oranı",
                        value: _selectedTax,
                        items: [1, 10, 20],
                        onChanged: (v) => setState(() => _selectedTax = v!),
                        suffix: "%",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("STOK KONTROLÜ"),
                Row(
                  children: [
                    Expanded(child: _buildField(_stockController, "Mevcut Miktar", Icons.inventory_2_outlined, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField(_minStockController, "Kritik Uyarı Sınırı", Icons.notification_important_outlined, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 40),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  Widget _buildHeader(Color primaryBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.add_business_rounded, color: primaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              "Ürün Envanter Kaydı",
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Yeni ürünü tanımlayarak satışa hazır hale getirin.",
          style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: _inputDecoration(label, icon),
        validator: isRequired ? (v) => (v == null || v.isEmpty) ? "Zorunlu" : null : null,
      ),
    );
  }

  Widget _buildCategoryDropdown(List<Map<String, dynamic>> categories) {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration("Kategori Seçimi", Icons.grid_view_rounded),
      value: categories.any((c) => c['name'] == _selectedCategory) ? _selectedCategory : null,
      items: categories.map((cat) => DropdownMenuItem<String>(
        value: cat['name'].toString(), 
        child: Text(cat['name'].toString())
      )).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value ?? "Genel"),
    );
  }

  Widget _buildDropdown<T>({required String label, required T value, required List<T> items, required ValueChanged<T?> onChanged, String suffix = ""}) {
    return DropdownButtonFormField<T>(
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, Icons.unfold_more_rounded),
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text("$e $suffix"))).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.white24),
      labelStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
    );
  }

  Widget _buildProfitIndicator() {
    final bool isLoss = _calculatedMargin < 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isLoss ? Colors.red : Colors.green).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isLoss ? Colors.red : Colors.green).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLoss ? Icons.warning_amber_rounded : Icons.auto_graph_rounded, 
               size: 16, color: isLoss ? Colors.redAccent : Colors.greenAccent),
          const SizedBox(width: 10),
          Text(
            isLoss ? "Zararına Satış: %${_calculatedMargin.toStringAsFixed(1)}" : "Tahmini Kâr: %${_calculatedMargin.toStringAsFixed(1)}",
            style: GoogleFonts.plusJakartaSans(
              color: isLoss ? Colors.redAccent : Colors.greenAccent, 
              fontSize: 13, 
              fontWeight: FontWeight.w800
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
            child: Text("İPTAL", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            onPressed: _saveProduct,
            child: Text("ENVANTERİ GÜNCELLE", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}