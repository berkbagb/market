import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/features/pos/market_provider.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text("İşletme Analizi", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.invalidate(salesHistoryProvider),
          )
        ],
      ),
      body: salesAsync.when(
        data: (sales) {
          // 1. DEĞİŞKENLERİ SIFIRLA
          double n = 0.0;
          double k = 0.0;
          double v = 0.0;

          // 2. VERİLERİ GRUPLA
          for (var s in sales) {
            String m = (s['paymentMethod'] ?? "NAKİT").toString().toUpperCase();
            double amt = (s['totalAmount'] as num).toDouble();
            
            if (m.contains("KART") || m == "K.KARTI") {
              k += amt;
            } else if (m.contains("VERESİYE")) {
              v += amt;
            } else {
              n += amt;
            }
          }

          // 3. EKRANA BAS
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ÖDEME DAĞILIMI", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)
                ),
                const SizedBox(height: 20),
                
                // BURADA SADECE 3 TANE SABİT SATIR VAR
                _buildStaticRow("Nakit Tahsilat", n, Colors.greenAccent, Icons.payments),
                const SizedBox(height: 15),
                _buildStaticRow("Kredi Kartı", k, Colors.blueAccent, Icons.credit_card),
                const SizedBox(height: 15),
                _buildStaticRow("Veresiye / Borç", v, Colors.orangeAccent, Icons.handshake),
                
                const SizedBox(height: 30),
                const Text(
                  "HIZLI AKSİYONLAR", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                // Buraya diğer butonlarını (Z Raporu vs.) ekleyebilirsin
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (e, s) => Center(child: Text("Hata oluştu: $e", style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildStaticRow(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: amount > 0 ? 0.8 : 0.0, 
                  color: color,
                  backgroundColor: Colors.white10,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text("${amount.toStringAsFixed(2)} ₺", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}