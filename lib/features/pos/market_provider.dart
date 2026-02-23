import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/core/database_helper.dart';
import 'package:market/core/models/product_model.dart';
import 'package:market/core/printer_service.dart';

// --- GLOBAL PROVIDERS ---

/// Arama terimini tutan state
final searchQueryProvider = StateProvider<String>((ref) => "");

/// Kategori listesini çeken provider
final categoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getAllCategories();
});

/// Sepet durumunu yöneten ana provider
final cartProvider = StateNotifierProvider<CartNotifier, List<Map<String, dynamic>>>((ref) {
  return CartNotifier(ref);
});

/// Ürün listesini yöneten provider
/// ÖNEMLİ: ref.watch(searchQueryProvider) buradan kaldırıldı çünkü notifier içinde filtreleme yapacağız.
/// Bu sayede her harf yazıldığında notifier baştan yaratılmaz, sadece liste filtrelenir.
final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier();
});

/// Satış geçmişi provider'ı
final salesHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getSalesHistory();
});

// Varsayılan KDV oranını tutan provider
final globalTaxProvider = StateProvider<double>((ref) => 20.0);

/// Stok hareket günlüklerini çeken provider
final stockLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getStockLogs();
});

/// Günlük ciro ve kar özet provider'ı
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

/// Haftalık grafik verisi
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

/// Müşteri Listesi Provider
final customersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  return await db.query('customers', orderBy: 'name ASC');
});



// Mağaza Bilgileri Modeli
class StoreInfo {
  final String name;
  final String phone;
  final String address;
  final String footerNote;

  StoreInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.footerNote,
  });

  StoreInfo copyWith({String? name, String? phone, String? address, String? footerNote}) {
    return StoreInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      footerNote: footerNote ?? this.footerNote,
    );
  }
}

// Mağaza bilgilerini tutan Provider
final storeInfoProvider = StateProvider<StoreInfo>((ref) => StoreInfo(
  name: "BERK MARKET",
  phone: "05XX XXX XX XX",
  address: "Merkez/İstanbul",
  footerNote: "Bizi tercih ettiğiniz için teşekkürler!",
));


// --- PRODUCTS NOTIFIER ---

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  // Veritabanındaki tüm ürünleri hafızada tutmak için
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
      debugPrint("STOK YÜKLEME HATASI: $e");
      state = AsyncValue.error(e, stack);
    }
  }

  /// Arama işlemini state üzerinden anlık yapar (Hızlı Filtreleme)
  void filterProducts(String query) {
    if (query.isEmpty) {
      state = AsyncValue.data(_allProducts);
    } else {
      final lowerQuery = query.toLowerCase();
      final filtered = _allProducts.where((p) => 
        p.name.toLowerCase().contains(lowerQuery) || 
        p.barcode.contains(lowerQuery)
      ).toList();
      state = AsyncValue.data(filtered);
    }
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.insertProduct(product.toMap());
    await loadProducts(); // Listeyi güncelle
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
}

// --- CART NOTIFIER ---

class CartNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  CartNotifier(this.ref) : super([]);

  bool get isEmpty => state.isEmpty;

  double get totalAmount => state.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));
  
  double get totalProfit => state.fold(0.0, (sum, item) {
    final buyPrice = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
    return sum + ((item['price'] - buyPrice) * item['qty']);
  });

  Future<bool> addToCart(String barcode) async {
    final data = await DatabaseHelper.instance.getProductByBarcode(barcode);
    if (data == null) return false;
    
    final product = Product.fromMap(data);
    final index = state.indexWhere((item) => item['barcode'] == barcode);
    final currentInCart = index != -1 ? (state[index]['qty'] as num).toDouble() : 0.0;

    if (product.stock <= currentInCart) return false;

    if (index != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) { ...state[i], 'qty': state[i]['qty'] + 1 } else state[i]
      ];
    } else {
      state = [...state, {
        'barcode': product.barcode,
        'name': product.name,
        'price': product.sellPrice,
        'buyPrice': product.buyPrice,
        'qty': 1,
      }];
    }
    return true;
  }

  Future<void> updateQuantity(String barcode, num newQty) async {
    if (newQty <= 0) {
      removeFromCart(barcode);
      return;
    }

    final data = await DatabaseHelper.instance.getProductByBarcode(barcode);
    if (data == null) return;
    final product = Product.fromMap(data);

    if (newQty > product.stock) return;

    state = [
      for (final item in state)
        if (item['barcode'] == barcode) { ...item, 'qty': newQty } else item
    ];
  }

  void removeFromCart(String barcode) {
    state = state.where((item) => item['barcode'] != barcode).toList();
  }

  void clear() => state = [];

  Future<void> completeSale(String paymentMethod, {int? customerId}) async {
    if (state.isEmpty) return;

    final double total = totalAmount;
    final double profit = totalProfit;
    final itemsSnapshot = List<Map<String, dynamic>>.from(state);

    try {
      await DatabaseHelper.instance.completeSale(
        totalAmount: total,
        totalProfit: profit,
        items: itemsSnapshot,
        paymentMethod: paymentMethod,
        customerId: customerId,
      );

      _printReceipt(itemsSnapshot, total, paymentMethod);

      clear();
      
      // Provider'ları tazele
      ref.read(productsProvider.notifier).loadProducts();
      ref.invalidate(salesHistoryProvider);
      ref.invalidate(weeklySalesProvider);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(stockLogsProvider);
      ref.invalidate(customersProvider);
      
    } catch (e) {
      debugPrint("SATIŞ HATASI: $e");
      rethrow;
    }
  }

  void _printReceipt(List items, double total, String method) async {
    try {
      final receiptData = {
        'items': items,
        'totalAmount': total,
        'paymentMethod': method,
        'storeName': 'BERK MARKET',
      };
      final bytes = await PrinterService.createReceipt(receiptData);
      await PrinterService.printReceipt(bytes);
    } catch (e) {
      debugPrint("Yazdırma Hatası: $e");
    }
  }
}