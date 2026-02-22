import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/features/pos/market_provider.dart'; 
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class StockLogsPage extends ConsumerWidget {
  const StockLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Türkçe tarih desteğini başlatıyoruz
    initializeDateFormatting('tr_TR', null);

    final logsAsync = ref.watch(stockLogsProvider);

    // V3 Kurumsal Renk Paleti
    const Color bgDark = Color(0xFF020617);
    const Color cardBg = Color(0xFF0F172A);
    const Color primaryBlue = Color(0xFF6366F1);
    const Color successGreen = Color(0xFF10B981);
    const Color dangerRed = Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Stok Hareketleri",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, 
                color: Colors.white,
                fontSize: 20
              ),
            ),
            Text(
              "Sistemdeki son stok değişimleri listeleniyor",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w400
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: primaryBlue.withValues(alpha: 0.1),
              child: IconButton(
                onPressed: () => ref.invalidate(stockLogsProvider),
                icon: const Icon(Icons.refresh_rounded, color: primaryBlue, size: 22),
                tooltip: "Listeyi Yenile",
              ),
            ),
          )
        ],
      ),
      body: logsAsync.when(
        data: (logs) => logs.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final double amount = (log['amount'] as num?)?.toDouble() ?? 0.0;
                  final bool isReduction = amount < 0;
                  final String productName = log['productName'] ?? "Bilinmeyen Ürün";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cardBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isReduction 
                            ? dangerRed.withValues(alpha: 0.15) 
                            : successGreen.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // Sol renkli şerit (Giriş/Çıkış göstergesi)
                            Container(
                              width: 6,
                              color: isReduction ? dangerRed : successGreen,
                            ),
                            Expanded(
                              child: ListTile(
                                contentPadding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isReduction 
                                        ? dangerRed.withValues(alpha: 0.1) 
                                        : successGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isReduction ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                                    color: isReduction ? dangerRed : successGreen,
                                    size: 24,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        productName,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildBadge(log['type']?.toString() ?? "İşlem"),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.qr_code_rounded, size: 14, color: Colors.white24),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Barkod: ${log['productBarcode'] ?? '---'}",
                                          style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 14, color: primaryBlue.withValues(alpha: 0.6)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDate(log['createdAt']?.toString() ?? ""),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: primaryBlue.withValues(alpha: 0.7), 
                                            fontSize: 11, 
                                            fontWeight: FontWeight.w600
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${amount > 0 ? '+' : ''}${amount.toStringAsFixed(0)}",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: isReduction ? dangerRed : successGreen,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      "BİRİM",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white24, 
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 3)),
        error: (e, st) => _buildErrorState(e.toString()),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white54, 
          fontSize: 10, 
          fontWeight: FontWeight.w700, 
          letterSpacing: 0.5
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return "---";
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph_rounded, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 24),
          Text(
            "Henüz Kayıt Yok",
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            "Tüm stok giriş ve çıkış işlemleri\nburada kronolojik olarak listelenir.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 16),
            Text("Veriler Yüklenemedi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}