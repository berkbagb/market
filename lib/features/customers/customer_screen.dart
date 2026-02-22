import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/models/customer_model.dart';
import 'package:market/features/customers/customer_provider.dart';
import 'package:market/features/customers/widgets/customer_card.dart'; 

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
    // customersProvider'ı dinliyoruz
    final customers = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          customers.isEmpty
              ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final customer = customers[index];
                        return CustomerCard(
                          customer: customer,
                          onTap: () => _showCustomerDialog(customer: customer),
                          onAction: (val) {
                            if (val == 'edit') _showCustomerDialog(customer: customer);
                            if (val == 'delete') _confirmDelete(customer);
                          },
                        );
                      },
                      childCount: customers.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF020617),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        centerTitle: false,
        title: Text(
          "Müşteri Portföyü",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800, 
            color: Colors.white, 
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        background: Stack(
          children: [
            Positioned(
              right: -30,
              top: -10,
              child: Icon(
                Icons.people_alt_rounded, 
                size: 220, 
                color: Colors.white.withValues(alpha: 0.02)
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
              child: Opacity(
                opacity: 0.4,
                child: Text(
                  "Sadakat sistemini ve müşteri ilişkilerini\nburadan yönetin.",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, 
                    fontSize: 13, 
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
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
            onPressed: () => _showCustomerDialog(),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
        onChanged: (val) {
          ref.read(customersProvider.notifier).refresh(query: val);
          setState(() {}); // Suffix icon görünürlüğü için
        },
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: "Müşteri ismi veya telefon yazın...",
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 22),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), 
            borderSide: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3))
          ),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.cancel_rounded, color: Colors.white24, size: 20),
                onPressed: () {
                  _searchController.clear();
                  ref.read(customersProvider.notifier).refresh();
                  setState(() {}); 
                },
              ) 
            : null,
        ),
      ),
    );
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "Müşteriyi Sil", 
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        content: Text(
          "${customer.name} silinecek. Bu işlem geri alınamaz.", 
          style: const TextStyle(color: Colors.white60)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("İptal", style: TextStyle(color: Colors.white24))
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(customersProvider.notifier).deleteCustomer(customer.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("SİL", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCustomerDialog({Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final phoneController = TextEditingController(text: customer?.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, 
          left: 24, 
          right: 24, 
          top: 32
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(
              customer == null ? "Yeni Müşteri" : "Müşteri Düzenle", 
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 24),
            _dialogField(nameController, "Ad Soyad", Icons.person_rounded),
            const SizedBox(height: 16),
            _dialogField(phoneController, "Telefon (Opsiyonel)", Icons.phone_android_rounded, isPhone: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    if (customer == null) {
                      ref.read(customersProvider.notifier).addCustomer(nameController.text.trim(), phoneController.text.trim());
                    } else {
                      ref.read(customersProvider.notifier).updateCustomer(
                        customer.copyWith(name: nameController.text.trim(), phone: phoneController.text.trim())
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  customer == null ? "KAYDET" : "GÜNCELLE", 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      textCapitalization: isPhone ? TextCapitalization.none : TextCapitalization.words,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        filled: true,
        fillColor: Colors.black26, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1)
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 100, color: Colors.white.withValues(alpha: 0.03)),
          const SizedBox(height: 16),
          Text(
            "Henüz müşteri kaydı yok.", 
            style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.1), fontSize: 16, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}