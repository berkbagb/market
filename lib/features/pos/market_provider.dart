import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/core/database_helper.dart';
// BU IMPORTU KESİNLİKLE EKLE, DİĞERİNİ SİL:
import 'package:market/features/customers/customer_provider.dart';
import 'package:market/core/models/product_model.dart';
import 'package:market/core/printer_service.dart';
import '../settings/settings_provider.dart';
import 'package:market/core/models/customer_model.dart';
import 'dart:developer' as dev;
// --- GLOBAL PROVIDERS ---

final searchQueryProvider = StateProvider<String>((ref) => "");

final categoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return await DatabaseHelper.instance.getAllCategories();
});

// STOK LOGLARI
final stockLogsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final db = await DatabaseHelper.instance.database;
  return await db.query('stock_logs', orderBy: 'createdAt DESC');
});

// MÜŞTERİLER

// ÜRÜNLER
final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
      return ProductsNotifier();
    });

final topProductsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return await DatabaseHelper.instance.getTopSellingProducts();
  // Not: getTopSellingProducts metodunu DatabaseHelper'a eklemiştik
});

// SEPET
final cartProvider =
    StateNotifierProvider<CartNotifier, List<Map<String, dynamic>>>((ref) {
      return CartNotifier(ref);
    });

// SATIŞ GEÇMİŞİ
final salesHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return await DatabaseHelper.instance.getSalesHistory();
});

final globalTaxProvider = StateProvider<double>((ref) => 20.0);

// GÜNLÜK İSTATİSTİKLER
final todayStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final allSales = await ref.watch(salesHistoryProvider.future);
  final now = DateTime.now();
  double revenue = 0;
  double profit = 0;

  for (var sale in allSales) {
    if (sale['createdAt'] == null) continue;
    final date = DateTime.parse(sale['createdAt']);
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day &&
        sale['isReturned'] == 0) {
      revenue += (sale['totalAmount'] as num).toDouble();
      profit += (sale['totalProfit'] as num).toDouble();
    }
  }
  return {'revenue': revenue, 'profit': profit};
});

// HAFTALIK SATIŞ GRAFİĞİ (Sadece bir kez tanımlanmalı)
final weeklySalesProvider = FutureProvider<List<double>>((ref) async {
  final allSales = await ref.watch(salesHistoryProvider.future);
  final now = DateTime.now();
  List<double> dailyTotals = List.filled(7, 0.0);

  for (var sale in allSales) {
    if (sale['isReturned'] == 1 || sale['createdAt'] == null) continue;
    final date = DateTime.parse(sale['createdAt']);
    final difference = now.difference(date).inDays;
    if (difference >= 0 && difference < 7) {
      dailyTotals[6 - difference] += (sale['totalAmount'] as num).toDouble();
    }
  }
  return dailyTotals;
});

// --- PRODUCTS NOTIFIER ---
class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  List<Product> _allProducts = [];
  ProductsNotifier() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final data = await DatabaseHelper.instance.getAllProducts();
      _allProducts = data.map((item) => Product.fromMap(item)).toList();
      state = AsyncValue.data(_allProducts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.insertProduct(product.toMap());
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    if (product.id != null) {
      await DatabaseHelper.instance.updateProduct(product.toMap());
      await loadProducts();
    }
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await loadProducts();
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      state = AsyncValue.data(_allProducts);
    } else {
      final lowerQuery = query.toLowerCase();
      final filtered = _allProducts
          .where(
            (p) =>
                p.name.toLowerCase().contains(lowerQuery) ||
                p.barcode.contains(lowerQuery),
          )
          .toList();
      state = AsyncValue.data(filtered);
    }
  }
}

// --- CUSTOMER NOTIFIER ---

// --- CART NOTIFIER ---
class CartNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  CartNotifier(this.ref) : super([]);

  double get totalAmount =>
      state.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));
  double get totalProfit => state.fold(0.0, (sum, item) {
    final buyPrice = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
    return sum + (((item['price'] as num).toDouble() - buyPrice) * item['qty']);
  });

  Future<bool> checkStock(String barcode, double requestedQty) async {
    final data = await DatabaseHelper.instance.getProductByBarcode(barcode);
    if (data == null) return false;
    final product = Product.fromMap(data);
    return (product.stock as num).toDouble() >= requestedQty;
  }

  Future<bool> addToCart(String barcode) async {
    final data = await DatabaseHelper.instance.getProductByBarcode(barcode);
    if (data == null) return false;
    final product = Product.fromMap(data);
    final index = state.indexWhere((item) => item['barcode'] == barcode);
    final currentInCart = index != -1
        ? (state[index]['qty'] as num).toDouble()
        : 0.0;

    if ((product.stock as num).toDouble() <= currentInCart) return false;

    if (index != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            {...state[i], 'qty': state[i]['qty'] + 1}
          else
            state[i],
      ];
    } else {
      state = [
        ...state,
        {
          'barcode': product.barcode,
          'name': product.name,
          'price': product.sellPrice,
          'buyPrice': product.buyPrice,
          'qty': 1.0,
        },
      ];
    }
    return true;
  }

  void updateQuantity(String barcode, double newQty) {
    state = [
      for (final item in state)
        if (item['barcode'] == barcode) {...item, 'qty': newQty} else item,
    ];
  }

  void removeFromCart(String barcode) =>
      state = state.where((item) => item['barcode'] != barcode).toList();
  void clear() => state = [];

  Future<void> completeSale(String paymentMethod, {int? customerId}) async {
    if (state.isEmpty) return;

    // 1. ÖDEME YÖNTEMİ KONTROLÜ (KRİTİK!)
    // Dışarıdan gelen veriyi temizleyip "KREDİ KARTI", "VERESİYE" veya "NAKİT" yapıyoruz.
    String finalMethod = paymentMethod.trim().toUpperCase();
    if (finalMethod.contains("KART")) {
      finalMethod = "KART";
    } else if (finalMethod.contains("VERESİYE") ||
        finalMethod.contains("BORÇ")) {
      finalMethod = "VERESİYE";
    } else {
      finalMethod = "NAKİT";
    }

    // 2. KÂR HESAPLAMA (0.0 KALMASIN)
    double totalProfit = state.fold(0.0, (sum, item) {
      double sell = (item['price'] as num).toDouble();
      double buy = (item['buyPrice'] as num).toDouble();
      double qty = (item['qty'] as num).toDouble();
      return sum + ((sell - buy) * qty);
    });

    // 3. VERİTABANINA GÖNDER
    await DatabaseHelper.instance.completeSale(
      totalAmount: totalAmount,
      totalProfit: totalProfit, // Hesapladığımız gerçek kârı gönderiyoruz
      items: List<Map<String, dynamic>>.from(state),
      paymentMethod: finalMethod,
      // Sadece "VERESİYE" ise müşteri ID'si gitsin, yoksa null gitmeli (Zırhlı kontrol)
      customerId: finalMethod == "VERESİYE" ? customerId : null,
    );

    // 4. TEMİZLİK VE TAZELEME
    state = []; // Sepeti temizle

    // Tüm ekranların (Dashboard, Stok, Müşteri) anında güncellenmesini sağlar
    ref.invalidate(salesHistoryProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(weeklySalesProvider);

    // Müşteri listesini ve bakiyelerini (refresh metoduyla) tazele
    await ref.read(customersProvider.notifier).refresh();
  }

  void _refreshGlobalProviders() {
    ref.read(productsProvider.notifier).loadProducts();
    ref.invalidate(salesHistoryProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(weeklySalesProvider);
    ref.invalidate(stockLogsProvider);
  }

  Future<void> _printReceipt(List items, double total, String method) async {
    try {
      final store = ref.read(settingsProvider);
      final receiptData = {
        'items': items,
        'totalAmount': total,
        'paymentMethod': method,
        'storeName': store.name,
        'address': store.address,
        'phone': store.phone,
        'footer': store.footerNote,
      };
      final bytes = await PrinterService.createReceipt(receiptData);
      await PrinterService.printReceipt(bytes);
    } catch (e) {
      dev.log("Yazıcı Hatası: $e");
    }
  }
}
