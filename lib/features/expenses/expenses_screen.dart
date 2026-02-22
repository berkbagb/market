import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market/core/database_helper.dart';

/// Giderleri getiren reaktif provider
final expensesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  return await db.query('expenses', orderBy: 'createdAt DESC');
});

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: CustomScrollView(
        slivers: [
          // --- MODERN APPBAR ---
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF020617),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                "Dükkan Giderleri",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_chart_rounded, color: Colors.orangeAccent),
                onPressed: () => _showAddExpenseDialog(context, ref),
              ),
              const SizedBox(width: 12),
            ],
          ),

          // --- ANA İÇERİK ---
          expensesAsync.when(
            data: (list) {
              if (list.isEmpty) return SliverFillRemaining(child: _buildEmptyState());

              final totalExpense = list.fold<double>(0, (sum, item) => sum + (item['amount'] as num).toDouble());

              return SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSummaryCard(totalExpense),
                    const SizedBox(height: 8),
                    _buildExpenseList(list, ref),
                    const SizedBox(height: 100), // Alt boşluk
                  ],
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.orangeAccent))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text("Hata: $e", style: const TextStyle(color: Colors.redAccent)))),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: const DecorationImage(
          image: NetworkImage("https://www.transparenttextures.com/patterns/carbon-fibre.png"),
          opacity: 0.1,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.orangeAccent.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bu Ayki Toplam Gider", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              Icon(Icons.trending_up_rounded, color: Colors.white.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "₺${NumberFormat('#,###.00', 'tr_TR').format(total)}",
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List<Map<String, dynamic>> list, WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final date = DateTime.parse(item['createdAt']);
        
        return Dismissible(
          key: Key(item['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
          ),
          onDismissed: (_) async {
            final db = await DatabaseHelper.instance.database;
            await db.delete('expenses', where: 'id = ?', whereArgs: [item['id']]);
            ref.invalidate(expensesProvider);
          },
          child: _buildExpenseTile(item, date),
        );
      },
    );
  }

  Widget _buildExpenseTile(Map<String, dynamic> item, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: _getCategoryColor(item['category']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getCategoryIcon(item['category']), color: _getCategoryColor(item['category'])),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  "${item['category']} • ${DateFormat('dd MMMM', 'tr_TR').format(date)}",
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "-₺${item['amount']}",
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCat = 'Toptancı';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text("Yeni Gider Kaydı", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 32),
            _buildInput(titleCtrl, "Harcama Nedeni", Icons.description_outlined),
            const SizedBox(height: 16),
            _buildInput(amountCtrl, "Tutar (₺)", Icons.confirmation_number_outlined, isNum: true),
            const SizedBox(height: 16),
            _buildCategorySelector((val) => selectedCat = val),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                  final db = await DatabaseHelper.instance.database;
                  await db.insert('expenses', {
                    'title': titleCtrl.text,
                    'amount': double.tryParse(amountCtrl.text) ?? 0,
                    'category': selectedCat,
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                  ref.invalidate(expensesProvider);
                  Navigator.pop(context);
                },
                child: const Text("KAYDI TAMAMLA", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(Function(String) onSelected) {
    return DropdownButtonFormField<String>(
      value: 'Toptancı',
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        prefixIcon: const Icon(Icons.grid_view_rounded, color: Colors.orangeAccent),
      ),
      items: ['Toptancı', 'Kira', 'Fatura', 'Personel', 'Diğer'].map((cat) {
        return DropdownMenuItem(value: cat, child: Text(cat));
      }).toList(),
      onChanged: (v) => onSelected(v!),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, {bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Toptancı': return Icons.shopping_bag_rounded;
      case 'Kira': return Icons.vpn_key_rounded;
      case 'Fatura': return Icons.wb_incandescent_rounded;
      case 'Personel': return Icons.people_alt_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Toptancı': return Colors.blueAccent;
      case 'Kira': return Colors.purpleAccent;
      case 'Fatura': return Colors.amberAccent;
      case 'Personel': return Colors.tealAccent;
      default: return Colors.orangeAccent;
    }
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_graph_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 20),
        const Text("Harcama verisi bulunamadı.", style: TextStyle(color: Colors.white24, fontSize: 16)),
      ],
    );
  }
}