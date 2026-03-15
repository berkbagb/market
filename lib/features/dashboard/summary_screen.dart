import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/features/pos/market_provider.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verileri iki farklı provider'dan çekiyoruz
    final salesAsync = ref.watch(salesHistoryProvider);
    final topProductsAsync = ref.watch(topProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "İşletme Özeti",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: salesAsync.when(
        data: (sales) {
          // --- 1. ÖDEME HESAPLAMA MANTIĞI ---
          double n = 0.0, k = 0.0, v = 0.0;
          for (var s in sales) {
            String m = (s['paymentMethod'] ?? "NAKİT")
                .toString()
                .toUpperCase()
                .trim();
            double amt = (s['totalAmount'] as num).toDouble();

            if (m == "NAKİT" || m == "NAKIT")
              n += amt;
            else if (m.contains("KART"))
              k += amt;
            else if (m == "VERESİYE" || m == "VERESIYE")
              v += amt;
            else
              n += amt;
          }
          double total = n + k + v;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Ciro Kartı
                _buildTotalBalanceCard(total),

                const SizedBox(height: 30),
                const Text(
                  "ÖDEME ANALİZİ",
                  style: TextStyle(
                    color: Colors.white60,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 15),

                // Analiz Kartları
                _buildModernCard(
                  "Nakit Tahsilat",
                  n,
                  total,
                  Colors.greenAccent,
                  Icons.payments_rounded,
                ),
                const SizedBox(height: 12),
                _buildModernCard(
                  "Kredi Kartı",
                  k,
                  total,
                  Colors.blueAccent,
                  Icons.credit_card_rounded,
                ),
                const SizedBox(height: 12),
                _buildModernCard(
                  "Veresiye / Borç",
                  v,
                  total,
                  Colors.orangeAccent,
                  Icons.handshake_rounded,
                ),

                const SizedBox(height: 35),
                const Text(
                  "EN ÇOK SATAN ÜRÜNLER",
                  style: TextStyle(
                    color: Colors.white60,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 15),

                // --- 2. EN ÇOK SATANLAR LİSTESİ ---
                topProductsAsync.when(
                  data: (products) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: products.isEmpty
                          ? [
                              const Text(
                                "Henüz satış verisi yok",
                                style: TextStyle(color: Colors.white38),
                              ),
                            ]
                          : products
                                .map(
                                  (p) => Column(
                                    children: [
                                      _buildTopProductRow(
                                        p['productName'].toString(),
                                        "${p['totalQty']} Adet",
                                        Colors.blueAccent,
                                      ),
                                      if (products.last != p)
                                        const Divider(
                                          color: Colors.white10,
                                          height: 24,
                                        ),
                                    ],
                                  ),
                                )
                                .toList(),
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text(
                    "Hata: $e",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
        error: (e, s) => Center(
          child: Text("Hata: $e", style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  // --- YARDIMCI TASARIM BİLEŞENLERİ ---

  Widget _buildTopProductRow(String name, String qty, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          qty,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text(
            "GÜNLÜK TOPLAM CİRO",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${total.toStringAsFixed(2)} ₺",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(
    String title,
    double amount,
    double total,
    Color color,
    IconData icon,
  ) {
    double ratio = total > 0 ? (amount / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${(ratio * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: ratio,
                    color: color,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${amount.toStringAsFixed(2)} ₺",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
