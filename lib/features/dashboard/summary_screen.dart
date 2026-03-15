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
        title: const Text(
          "İşletme Analizi",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: salesAsync.when(
        data: (sales) {
          // --- 1. ADIM: VERİLERİ HAVUZDA TOPLA ---
          double nakitHavuzu = 0.0;
          double kartHavuzu = 0.0;
          double veresiyeHavuzu = 0.0;

          for (var s in sales) {
            String m = (s['paymentMethod'] ?? "NAKİT")
                .toString()
                .toUpperCase()
                .trim();
            double amt = (s['totalAmount'] as num).toDouble();

            if (m == "NAKİT" || m == "NAKIT") {
              nakitHavuzu += amt;
            } else if (m.contains("KART")) {
              kartHavuzu += amt;
            } else if (m == "VERESİYE" || m == "VERESIYE") {
              veresiyeHavuzu += amt;
            } else {
              // EĞER "a" GİBİ TANINMAYAN BİR ŞEY GELİRSE:
              // Yeni satır açma, git Nakit havuzuna ekle!
              nakitHavuzu += amt;
            }
          }

          // --- 2. ADIM: EKRANA SADECE 3 WIDGET BAS ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ÖDEME DAĞILIMI",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),

                // BURADA DÖNGÜ YOK! SADECE 3 TANE SABİT FONKSİYON ÇAĞRISI VAR.
                _buildStaticRow(
                  "Nakit Tahsilat",
                  nakitHavuzu,
                  Colors.greenAccent,
                  Icons.payments,
                ),
                const SizedBox(height: 15),
                _buildStaticRow(
                  "Kredi Kartı",
                  kartHavuzu,
                  Colors.blueAccent,
                  Icons.credit_card,
                ),
                const SizedBox(height: 15),
                _buildStaticRow(
                  "Veresiye / Borç",
                  veresiyeHavuzu,
                  Colors.orangeAccent,
                  Icons.handshake,
                ),

                // NOT: Eğer bu satırın altında hala bir şeyler çıkıyorsa,
                // dosyanın devamında kalmış eski bir .map veya ListView var demektir.
                // Lütfen dosyanın sonuna kadar başka Column elemanı kalmadığına emin ol.
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Hata: $e")),
      ),
    );
  }

  Widget _buildStaticRow(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: amount > 0 ? 0.7 : 0.0,
                  color: color,
                  backgroundColor: Colors.white10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text(
            "${amount.toStringAsFixed(2)} ₺",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
