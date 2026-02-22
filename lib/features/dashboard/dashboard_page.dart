import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/market_provider.dart';
import 'package:intl/intl.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reaktif veri kaynakları
    final statsAsync = ref.watch(todayStatsProvider);
    final weeklySalesAsync = ref.watch(weeklySalesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Performans Analizi",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            Text(
              DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
              style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          _buildRefreshButton(ref),
          const SizedBox(width: 12),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayStatsProvider);
            ref.invalidate(weeklySalesProvider);
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ÜST İSTATİSTİK KARTLARI ---
                _buildStatCards(stats, currencyFormat),
                
                const SizedBox(height: 32),
                
                // --- GRAFİK BÖLÜMÜ ---
                _buildSectionHeader("Haftalık Satış Trendi", "Son 7 günün mağaza cirosu"),
                const SizedBox(height: 16),
                _buildChartContainer(weeklySalesAsync),
                
                const SizedBox(height: 32),
                
                // --- HIZLI AKSİYONLAR ---
                _buildSectionHeader("Yönetici Araçları", "Hızlı raporlama ve sistem ayarları"),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (e, _) => _buildErrorState(e.toString()),
      ),
    );
  }

  Widget _buildRefreshButton(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () {
          ref.invalidate(todayStatsProvider);
          ref.invalidate(weeklySalesProvider);
        },
        icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle,
          style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatCards(Map<String, double> stats, NumberFormat format) {
    return Row(
      children: [
        _statCard(
          "Bugünkü Ciro", 
          format.format(stats['revenue'] ?? 0), 
          Icons.account_balance_wallet_rounded, 
          const Color(0xFF10B981)
        ),
        const SizedBox(width: 16),
        _statCard(
          "Net Kâr", 
          format.format(stats['profit'] ?? 0), 
          Icons.auto_graph_rounded, 
          const Color(0xFF6366F1)
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(value, 
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.w800
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(AsyncValue<List<double>> data) {
    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 40, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: data.when(
        data: (sales) => LineChart(_mainChartData(sales)),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (e, _) => const Center(child: Text("Grafik verisi yüklenemedi", style: TextStyle(color: Colors.white24))),
      ),
    );
  }

  LineChartData _mainChartData(List<double> sales) {
    if (sales.isEmpty) return LineChartData();
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withOpacity(0.03),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
              int index = value.toInt();
              if (index >= 0 && index < days.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(days[index], style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const Text('');
              return Text(
                value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0), 
                style: const TextStyle(color: Colors.white10, fontSize: 10)
              );
            }
          )
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(sales.length, (i) => FlSpot(i.toDouble(), sales[i])),
          isCurved: true,
          curveSmoothness: 0.35,
          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
          barWidth: 6,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: const Color(0xFF0F172A),
              strokeWidth: 3,
              strokeColor: const Color(0xFF6366F1),
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF6366F1).withOpacity(0.15), const Color(0xFF6366F1).withOpacity(0.0)],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot touchedSpot) => const Color(0xFF1E293B),
          tooltipRoundedRadius: 16,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                '₺${NumberFormat('#,###', 'tr_TR').format(barSpot.y)}',
                GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: [
        _actionButton("Günlük Rapor", Icons.analytics_rounded, const Color(0xFFF59E0B)),
        _actionButton("Kasa Kapat", Icons.lock_clock_rounded, const Color(0xFFEF4444)),
        _actionButton("Yedekle", Icons.cloud_upload_rounded, const Color(0xFF10B981)),
        _actionButton("Ayarlar", Icons.tune_rounded, const Color(0xFF64748B)),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color) {
    return SizedBox(
      width: 75,
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {}, // Aksiyon ekleyebilirsin
                child: Icon(icon, color: color.withOpacity(0.8), size: 26),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, 
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text("Veriler Yüklenemedi", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}