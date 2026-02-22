import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/core/database_helper.dart';
import 'package:intl/intl.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  double _dailyTotal = 0;
  double _dailyProfit = 0;
  int _saleCount = 0;
  Map<String, double> _paymentStats = {"NAKİT": 0, "KART": 0, "VERESİYE": 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyReport();
  }

  Future<void> _loadDailyReport() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      final List<Map<String, dynamic>> sales = await db.query(
        'sales',
        where: "createdAt LIKE ? AND isReturned = 0",
        whereArgs: ["$todayStr%"],
      );

      double total = 0;
      double profit = 0;
      Map<String, double> stats = {"NAKİT": 0, "KART": 0, "VERESİYE": 0};

      for (var sale in sales) {
        total += (sale['totalAmount'] as num).toDouble();
        profit += (sale['totalProfit'] as num).toDouble();
        String method = sale['paymentMethod'].toString().toUpperCase();
        
        if (stats.containsKey(method)) {
          stats[method] = (stats[method] ?? 0) + (sale['totalAmount'] as num).toDouble();
        } else {
          stats[method] = (sale['totalAmount'] as num).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _dailyTotal = total;
          _dailyProfit = profit;
          _saleCount = sales.length;
          _paymentStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Rapor yükleme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF6366F1);
    const Color bgDark = Color(0xFF020617);
    const Color cardBg = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "İşletme Analizi",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 22),
            ),
            Text(
              "Günlük operasyonel verileriniz",
              style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _loadDailyReport,
              style: IconButton.styleFrom(backgroundColor: primaryBlue.withValues(alpha: 0.1)),
              icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _loadDailyReport,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("GÜNLÜK PERFORMANS", "Canlı özet"),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        _buildSummaryCard("Toplam Ciro", "${_dailyTotal.toStringAsFixed(2)} ₺", Icons.payments_rounded, const Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        _buildSummaryCard("Net Kâr", "${_dailyProfit.toStringAsFixed(2)} ₺", Icons.auto_graph_rounded, primaryBlue),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSummaryCard("Fiş Sayısı", "$_saleCount İşlem", Icons.receipt_long_rounded, Colors.orangeAccent),
                        const SizedBox(width: 12),
                        _buildSummaryCard("KDV (Tahmini)", "${(_dailyTotal * 0.20).toStringAsFixed(2)} ₺", Icons.account_balance_rounded, Colors.purpleAccent),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("ÖDEME DAĞILIMI", "Kanal bazlı ciro analizi"),
                    const SizedBox(height: 16),

                    ..._paymentStats.entries.map((e) => _buildPaymentTile(
                      e.key == "NAKİT" ? "Nakit Tahsilat" : (e.key == "KART" ? "Kredi Kartı" : "Veresiye / Borç"),
                      e.value,
                      e.key == "NAKİT" ? Icons.money_rounded : (e.key == "KART" ? Icons.credit_card_rounded : Icons.handshake_rounded),
                      e.key == "NAKİT" ? Colors.green : (e.key == "KART" ? Colors.blue : Colors.amber),
                    )),

                    const SizedBox(height: 32),
                    _buildSectionHeader("HIZLI AKSİYONLAR", "Rapor yönetimi"),
                    const SizedBox(height: 16),

                    _buildActionTile("Z Raporu Al", Icons.print_rounded, "Yazıcıdan çıktı al", () {}),
                    _buildActionTile("PDF Raporu Oluştur", Icons.picture_as_pdf_rounded, "Dışa aktar ve paylaş", () {}),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 2),
        Container(width: 40, height: 3, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(10))),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(String title, double amount, IconData icon, Color color) {
    double percentage = _dailyTotal > 0 ? (amount / _dailyTotal) : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("${amount.toStringAsFixed(2)} ₺", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(sub, style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
      ),
    );
  }
}