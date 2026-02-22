import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/features/pos/market_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reaktif veriler
    final statsAsync = ref.watch(todayStatsProvider);
    final weeklySalesAsync = ref.watch(weeklySalesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildStatsRow(stats, currencyFormat),
              const SizedBox(height: 32),
              _buildChartSection(weeklySalesAsync, currencyFormat),
              const SizedBox(height: 32),
              _buildQuickActions(),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 3),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text("Veri bağlantısı hatası: $e", style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Performans Paneli",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white38),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
                  style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        _headerAvatar(),
      ],
    );
  }

  Widget _headerAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 2),
      ),
      child: const CircleAvatar(
        radius: 24,
        backgroundColor: Color(0xFF1E293B),
        child: Icon(Icons.person_outline, color: Colors.white70),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, double> stats, NumberFormat format) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Toplam Ciro",
            format.format(stats['revenue'] ?? 0),
            Icons.account_balance_wallet_outlined,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _statCard(
            "Net Kâr",
            format.format(stats['profit'] ?? 0),
            Icons.auto_graph_rounded,
            const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 24),
          Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(AsyncValue<List<double>> weeklySales, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Satış Trendi",
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const Icon(Icons.more_horiz, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 260,
            child: weeklySales.when(
              data: (data) => _buildBarChart(data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Center(child: Text("Grafik yüklenemedi", style: TextStyle(color: Colors.white24))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<double> data) {
    if (data.isEmpty) data = List.filled(7, 0.0);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.3,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF1E293B),
            tooltipRoundedRadius: 12,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              "${rod.toY.toStringAsFixed(0)} ₺",
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(days[value.toInt() % 7], style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i],
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 18,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal * 1.3,
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickActionBtn("Raporlar", Icons.description_outlined, const Color(0xFFF59E0B)),
        _quickActionBtn("Ürünler", Icons.inventory_2_outlined, const Color(0xFF3B82F6)),
        _quickActionBtn("Ayarlar", Icons.settings_outlined, const Color(0xFF64748B)),
        _quickActionBtn("Kasa", Icons.point_of_sale_rounded, const Color(0xFFEC4899)),
      ],
    );
  }

  Widget _quickActionBtn(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          height: 64, width: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 12),
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}