// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:market/features/customers/customer_provider.dart';
// import 'package:market/core/models/customer_model.dart';

// class CustomerScreen extends ConsumerWidget {
//   const CustomerScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final customers = ref.watch(customersProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xFF020617),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text("MÜŞTERİ & VERESİYE", 
//           style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
//         actions: [
//           IconButton(
//             onPressed: () => _showAddCustomerDialog(context, ref),
//             icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF818CF8)),
//           ),
//           const SizedBox(width: 10),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildSearchBox(ref),
//           Expanded(
//             child: customers.isEmpty
//                 ? _buildEmptyState()
//                 : _buildCustomerList(customers, ref, context),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBox(WidgetRef ref) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
//       child: TextField(
//         onChanged: (val) => ref.read(customersProvider.notifier).refresh(query: val),
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           hintText: "Müşteri ara...",
//           hintStyle: const TextStyle(color: Colors.white24),
//           prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
//           filled: true,
//           fillColor: const Color(0xFF0F172A),
//           contentPadding: const EdgeInsets.symmetric(vertical: 16),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomerList(List<Customer> customers, WidgetRef ref, BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       itemCount: customers.length,
//       itemBuilder: (context, index) {
//         final customer = customers[index];
//         return Container(
//           margin: const EdgeInsets.only(bottom: 12),
//           decoration: BoxDecoration(
//             color: const Color(0xFF0F172A),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.all(16),
//             leading: CircleAvatar(
//               radius: 25,
//               backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
//               child: Text(customer.name[0].toUpperCase(), 
//                 style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
//             ),
//             title: Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             subtitle: Text(customer.phone, style: const TextStyle(color: Colors.white38)),
//             trailing: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text("${customer.balance.toStringAsFixed(2)} ₺", 
//                   style: TextStyle(
//                     color: customer.balance > 0 ? Colors.redAccent : Colors.greenAccent, 
//                     fontWeight: FontWeight.w900, 
//                     fontSize: 16
//                   )),
//                 const Text("Bakiye", style: TextStyle(color: Colors.white24, fontSize: 10)),
//               ],
//             ),
//             onTap: () => _showPaymentDialog(context, ref, customer),
//           ),
//         );
//       },
//     );
//   }

//   void _showPaymentDialog(BuildContext context, WidgetRef ref, Customer customer) {
//     final amountController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF1E293B),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         title: Text(customer.name, style: const TextStyle(color: Colors.white)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text("Güncel Borç: ${customer.balance.toStringAsFixed(2)} ₺", style: const TextStyle(color: Colors.redAccent)),
//             const SizedBox(height: 16),
//             TextField(
//               controller: amountController,
//               keyboardType: TextInputType.number,
//               style: const TextStyle(color: Colors.white),
//               decoration: const InputDecoration(
//                 labelText: "Tahsil Edilen Tutar",
//                 labelStyle: TextStyle(color: Colors.white60),
//                 suffixText: "₺",
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
//           ElevatedButton(
//             onPressed: () {
//               final miktar = double.tryParse(amountController.text) ?? 0;
//               if (miktar > 0) {
//                 ref.read(customersProvider.notifier).addDebt(customer.id!, -miktar);
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text("Ödemeyi Al"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
//     final nameCtrl = TextEditingController();
//     final phoneCtrl = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF1E293B),
//         title: const Text("Yeni Müşteri Kaydı", style: TextStyle(color: Colors.white)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Ad Soyad"), style: const TextStyle(color: Colors.white)),
//             TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Telefon"), style: const TextStyle(color: Colors.white)),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
//           ElevatedButton(
//             onPressed: () {
//               if (nameCtrl.text.isNotEmpty) {
//                 ref.read(customersProvider.notifier).addCustomer(nameCtrl.text, phoneCtrl.text);
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text("Kaydet"),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return const Center(child: Text("Müşteri bulunamadı.", style: TextStyle(color: Colors.white24)));
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/customers/customer_provider.dart';

class CustomerScreen extends ConsumerWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    final totalDebt = customers.fold<double>(0, (sum, item) => sum + item.balance);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Column(
        children: [
          // Üst Bilgi Paneli (Toplam Alacak)
          _buildHeader(totalDebt),
          
          // Arama ve Filtreleme Alanı
          _buildSearchSection(ref),

          // Müşteri Listesi
          Expanded(
            child: customers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerCard(context, ref, customer);
                    },
                  ),
          ),
        ],
      ),
      // Yeni Müşteri Ekleme Butonu
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context, ref),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text("Yeni Müşteri", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("MÜŞTERİ YÖNETİMİ", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6366F1), fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
              const SizedBox(height: 8),
              Text("Veresiye Defteri", style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("TOPLAM ALACAK", style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 11)),
                Text("${total.toStringAsFixed(2)} ₺", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchSection(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: TextField(
        onChanged: (val) => ref.read(customersProvider.notifier).refresh(query: val),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Müşteri ismi veya telefon numarası ile ara...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, WidgetRef ref, dynamic customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: Text(customer.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(customer.phone, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${customer.balance.toStringAsFixed(2)} ₺", style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.w900)),
              const Text("GÜNCEL BORÇ", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 24),
          _buildActionButton(Icons.payments_rounded, Colors.green, () => _showPaymentDialog(context, ref, customer)),
          const SizedBox(width: 8),
          _buildActionButton(Icons.edit_note_rounded, Colors.blue, () => _showEditCustomerDialog(context, ref, customer)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // Ödeme Alma Penceresi (Borç Düşme)
  void _showPaymentDialog(BuildContext context, WidgetRef ref, dynamic customer) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text("${customer.name} - Ödeme Al", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Alınan Tutar (₺)", labelStyle: TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount > 0) {
                ref.read(customersProvider.notifier).addDebt(customer.id!, -amount); // Borcu azaltmak için eksi değer
                Navigator.pop(context);
              }
            },
            child: const Text("Ödemeyi Kaydet"),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Yeni Müşteri Ekle", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Ad Soyad", labelStyle: TextStyle(color: Colors.white60)), style: const TextStyle(color: Colors.white)),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Telefon", labelStyle: TextStyle(color: Colors.white60)), style: const TextStyle(color: Colors.white)),
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
            child: const Text("Müşteriyi Kaydet"),
          ),
        ],
      ),
    );
  }

  // Mavi butona tıklandığında bu fonksiyon çalışacak
void _showEditCustomerDialog(BuildContext context, WidgetRef ref, dynamic customer) {
  final nameCtrl = TextEditingController(text: customer.name);
  final phoneCtrl = TextEditingController(text: customer.phone);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.white10),
      ),
      title: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: Colors.blue),
          const SizedBox(width: 12),
          const Text("Müşteriyi Düzenle", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Ad Soyad",
              labelStyle: TextStyle(color: Colors.white60),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Telefon",
              labelStyle: TextStyle(color: Colors.white60),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            ),
          ),
          const SizedBox(height: 32),
          
          // --- KRİTİK SİLME BUTONU ---
          TextButton.icon(
            onPressed: () => _showDeleteConfirm(context, ref, customer),
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
            label: const Text(
              "MÜŞTERİYİ SİSTEMDEN TAMAMEN SİL", 
              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal", style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () {
            if (nameCtrl.text.isNotEmpty) {
              ref.read(customersProvider.notifier).updateCustomer(
                customer.id!,
                nameCtrl.text,
                phoneCtrl.text,
              );
              Navigator.pop(context);
            }
          },
          child: const Text("Güncelle"),
        ),
      ],
    ),
  );
}

// Yanlışlıkla silmeyi önlemek için onay penceresi
void _showDeleteConfirm(BuildContext context, WidgetRef ref, dynamic customer) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF020617),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Dikkat!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      content: Text(
        "${customer.name} isimli müşteriyi ve tüm borç geçmişini silmek istediğinize emin misiniz?",
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Vazgeç", style: TextStyle(color: Colors.white54))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            ref.read(customersProvider.notifier).deleteCustomer(customer.id!);
            Navigator.pop(context); // Onay penceresini kapat
            Navigator.pop(context); // Düzenleme penceresini kapat
          },
          child: const Text("Evet, Her Şeyi Sil"),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text("Henüz müşteri kaydı yok.", style: TextStyle(color: Colors.white.withOpacity(0.2))),
        ],
      ),
    );
  }
}