import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:market/core/database_helper.dart';
import 'package:market/core/models/product_model.dart';
import 'package:market/core/printer_service.dart';

// --- GLOBAL PROVIDERS ---

final searchQueryProvider = StateProvider<String>((ref) => "");

final categoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getAllCategories();
});

final cartProvider = StateNotifierProvider<CartNotifier, List<Map<String, dynamic>>>((ref) {
  return CartNotifier(ref);
});

final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier();
});

final salesHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getSalesHistory();
});

final globalTaxProvider = StateProvider<double>((ref) => 20.0);

final stockLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getStockLogs();
});

// Günlük ciro ve kar özet provider'ı
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

// Haftalık grafik verisi
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

// --- MODELS ---

class StoreInfo {
  final String name;
  final String phone;
  final String address;
  final String footerNote;

  StoreInfo({required this.name, required this.phone, required this.address, required this.footerNote});

  StoreInfo copyWith({String? name, String? phone, String? address, String? footerNote}) {
    return StoreInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      footerNote: footerNote ?? this.footerNote,
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final double balance;

  Customer({required this.id, required this.name, required this.phone, this.balance = 0.0});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'phone': phone, 'balance': balance};

  factory Customer.fromMap(Map<dynamic, dynamic> map) => Customer(
    id: map['id'], 
    name: map['name'], 
    phone: map['phone'], 
    balance: (map['balance'] as num).toDouble(),
  );

  Customer copyWith({double? balance}) => Customer(
    id: id, name: name, phone: phone, balance: balance ?? this.balance,
  );
}

// --- STORE INFO PROVIDER ---
final storeInfoProvider = StateProvider<StoreInfo>((ref) => StoreInfo(
  name: "BERK MARKET",
  phone: "05XX XXX XX XX",
  address: "Merkez/İstanbul",
  footerNote: "Bizi tercih ettiğiniz için teşekkürler!",
));

// --- PRODUCTS NOTIFIER ---
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
      debugPrint("STOK YÜKLEME HATASI: $e");
      state = AsyncValue.error(e, stack);
    }
  }

  /// Arama işlemi
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

  // --- EKSİK OLAN VE HATAYA SEBEP OLAN METODLAR BURADA ---

  Future<void> addProduct(Product product) async {
    try {
      await DatabaseHelper.instance.insertProduct(product.toMap());
      await loadProducts(); // Listeyi yeniden yükle ki ekranda hemen görünsün
    } catch (e) {
      debugPrint("Ürün ekleme hatası: $e");
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      if (product.id != null) {
        await DatabaseHelper.instance.updateProduct(product.toMap());
        await loadProducts(); // Güncel halini çek
      }
    } catch (e) {
      debugPrint("Ürün güncelleme hatası: $e");
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await DatabaseHelper.instance.deleteProduct(id);
      await loadProducts(); // Silindikten sonra listeyi tazele
    } catch (e) {
      debugPrint("Ürün silme hatası: $e");
      rethrow;
    }
  }
}
// --- CUSTOMER NOTIFIER (HIVE) ---
class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) { _loadFromHive(); }

  final _box = Hive.box('customers');

  void _loadFromHive() {
    final data = _box.values.map((e) => Customer.fromMap(e)).toList();
    state = data;
  }

  void addCustomer(String name, String phone) {
    final newCustomer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
    );
    state = [...state, newCustomer];
    _box.put(newCustomer.id, newCustomer.toMap());
  }

  void updateBalance(String id, double amount) {
    state = [
      for (final c in state)
        if (c.id == id) _updateAndSave(c, amount) else c
    ];
  }

  Customer _updateAndSave(Customer c, double amount) {
    final updated = c.copyWith(balance: c.balance + amount);
    _box.put(updated.id, updated.toMap());
    return updated;
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

// --- CART NOTIFIER ---
class CartNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  CartNotifier(this.ref) : super([]);

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

  void updateQuantity(String barcode, num newQty) {
    state = [
      for (final item in state)
        if (item['barcode'] == barcode) { ...item, 'qty': newQty } else item
    ];
  }

  void removeFromCart(String barcode) => state = state.where((item) => item['barcode'] != barcode).toList();
  void clear() => state = [];

  Future<void> completeSale(String paymentMethod, {String? customerId}) async {
    if (state.isEmpty) return;

    final double total = totalAmount;
    final double profit = totalProfit;
    final itemsSnapshot = List<Map<String, dynamic>>.from(state);

    await DatabaseHelper.instance.completeSale(
      totalAmount: total,
      totalProfit: profit,
      items: itemsSnapshot,
      paymentMethod: paymentMethod,
    );

    // Müşteri seçildiyse borcuna işle (Hive)
    if (customerId != null && paymentMethod == "VERESİYE") {
      ref.read(customerProvider.notifier).updateBalance(customerId, total);
    }

    _printReceipt(itemsSnapshot, total, paymentMethod);
    clear();
    _refreshAll();
  }

  void _refreshAll() {
    ref.read(productsProvider.notifier).loadProducts();
    ref.invalidate(salesHistoryProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(weeklySalesProvider);
  }

  void _printReceipt(List items, double total, String method) async {
    try {
      final receiptData = {
        'items': items,
        'totalAmount': total,
        'paymentMethod': method,
        'storeName': ref.read(storeInfoProvider).name,
      };
      final bytes = await PrinterService.createReceipt(receiptData);
      await PrinterService.printReceipt(bytes);
    } catch (e) {
      debugPrint("Yazıcı Hatası: $e");
    }
  }
}