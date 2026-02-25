import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/customers/customer_provider.dart';
import 'package:market/core/models/customer_model.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("MÜŞTERİ YÖNETİMİ & VERESİYE", 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildSearchBox(ref),
          Expanded(
            child: customers.isEmpty
                ? _buildEmptyState()
                : _buildCustomerList(customers, ref, context),
          ),
        ],
      ),
    );
  }

  // Arama Kutusu
  Widget _buildSearchBox(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: TextField(
        onChanged: (val) => ref.read(customersProvider.notifier).refresh(query: val),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Müşteri adı veya telefon ile ara...",
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // Müşteri Listesi
  Widget _buildCustomerList(List<Customer> customers, WidgetRef ref, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: Text(customer.name[0].toUpperCase(), 
                style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            title: Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text(customer.phone, style: const TextStyle(color: Colors.white38)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${customer.balance.toStringAsFixed(2)} ₺", 
                  style: TextStyle(color: customer.balance > 0 ? Colors.redAccent : Colors.greenAccent, 
                  fontWeight: FontWeight.w900, fontSize: 18)),
                const Text("Güncel Borç", style: TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
            onTap: () => _showPaymentDialog(context, ref, customer),
          ),
        );
      },
    );
  }

  // TAHSİLAT YAPMA POPUP'I
  void _showPaymentDialog(BuildContext context, WidgetRef ref, Customer customer) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("${customer.name} - Tahsilat Al", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Mevcut Borç: ${customer.balance.toStringAsFixed(2)} ₺", 
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              decoration: InputDecoration(
                labelText: "Alınan Miktar",
                labelStyle: const TextStyle(color: Colors.white60),
                suffixText: "₺",
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final miktar = double.tryParse(amountController.text) ?? 0;
              if (miktar > 0) {
                // Borçtan düşme işlemi (Negatif miktar gönderiyoruz)
                ref.read(customersProvider.notifier).addDebt(customer.id!, -miktar);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tahsilat başarıyla kaydedildi.")));
              }
            },
            child: const Text("ÖDEMEYİ AL", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Müşteri bulunamadı.", style: TextStyle(color: Colors.white24)));
  }
}