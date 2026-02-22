import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/core/database_helper.dart';
import 'package:intl/intl.dart';

// v3: Raporlar için veri modeli - Değişmez (Immutable) yapı
class ReportStats {
  final double totalRevenue;
  final double totalProfit;
  final int totalSales;
  final Map<String, double> paymentBreakdown;
  final List<Map<String, dynamic>> rawSales;

  ReportStats({
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalSales,
    required this.paymentBreakdown,
    required this.rawSales,
  });
}

// v3: Modern AsyncNotifier Yapısı
class ReportsNotifier extends AsyncNotifier<ReportStats> {
  @override
  Future<ReportStats> build() async {
    return _fetchReportData();
  }

  Future<ReportStats> _fetchReportData() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // v3: Filtreleme ve Güvenli Sorgu
    final List<Map<String, dynamic>> sales = await db.query(
      'sales',
      where: "createdAt LIKE ? AND isReturned = 0",
      whereArgs: ["$todayStr%"],
      orderBy: 'createdAt DESC',
    );

    double revenue = 0;
    double profit = 0;
    
    // Varsayılan ödeme yöntemleri
    Map<String, double> breakdown = {
      "NAKIT": 0.0,
      "KART": 0.0,
      "VERESIYE": 0.0
    };

    for (var sale in sales) {
      // Güvenli tip dönüşümü (Hata önleyici)
      final double saleTotal = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final double saleProfit = (sale['totalProfit'] as num?)?.toDouble() ?? 0.0;
      
      revenue += saleTotal;
      profit += saleProfit;
      
      // Ödeme yöntemi standardizasyonu (TR karakter temizliği)
      String method = sale['paymentMethod']
          .toString()
          .toUpperCase()
          .replaceAll('İ', 'I')
          .trim();

      if (breakdown.containsKey(method)) {
        breakdown[method] = (breakdown[method] ?? 0.0) + saleTotal;
      } else {
        // Tanımlı olmayan bir yöntem gelirse dinamik olarak ekle
        breakdown[method] = saleTotal;
      }
    }

    return ReportStats(
      totalRevenue: revenue,
      totalProfit: profit,
      totalSales: sales.length,
      paymentBreakdown: breakdown,
      rawSales: sales,
    );
  }

  // UI tarafından tetiklenecek yenileme metodu
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchReportData());
  }
}

// Global Provider Tanımı
final reportsProvider = AsyncNotifierProvider<ReportsNotifier, ReportStats>(() {
  return ReportsNotifier();
});

// v3: Haftalık Grafik için Optimize Edilmiş Provider
final weeklyChartProvider = FutureProvider<List<double>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  
  // Son 7 günün verisini çeken optimize SQL sorgusu (v3: Windows & SQLite uyumlu)
  final List<Map<String, dynamic>> res = await db.rawQuery('''
    SELECT 
      strftime('%w', createdAt) as day, 
      SUM(totalAmount) as total 
    FROM sales 
    WHERE createdAt >= date('now', '-6 days') AND isReturned = 0
    GROUP BY day
  ''');

  // Haftalık boş liste (Index 0: Pazar, 6: Cumartesi)
  List<double> dailyTotals = List.filled(7, 0.0);
  
  for (var row in res) {
    try {
      // SQLite'dan gelen day değerini güvenli parse etme
      final String? rawDay = row['day']?.toString();
      if (rawDay != null) {
        int dayIndex = int.parse(rawDay);
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyTotals[dayIndex] = (row['total'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } catch (e) {
      continue; // Hatalı satırı atla
    }
  }
  return dailyTotals;
});