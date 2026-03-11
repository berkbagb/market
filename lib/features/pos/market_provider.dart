import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:market/core/database_helper.dart';
import 'package:market/core/models/product_model.dart';
import 'package:market/core/printer_service.dart';
import '../settings/settings_provider.dart';

// --- GLOBAL PROVIDERS ---

final searchQueryProvider = StateProvider<String>((ref) => "");

final categoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getAllCategories();
});

final cartProvider = StateNotifierProvider<CartNotifier, List<Map<String, dynamic>>>((ref) {
  return CartNotifier(ref);
});

// ProductsNotifier AsyncValue dönerken StateNotifierProvider tanımı düzeltildi
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

final todayStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  // watch yerine read kullanımı veya invalidation sonrası güncellenen veriyi çekmek için
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

class Customer {
  final String id;
  final String name;
  final String phone;
  final double balance;

  Customer({required this.id, required this.name, required this.phone, this.balance = 0.0});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'phone': phone, 'balance': balance};

  factory Customer.fromMap(Map<dynamic, dynamic> map) => Customer(
    id: map['id'].toString(), 
    name: map['name'], 
    phone: map['phone'], 
    balance: (map['balance'] as num).toDouble(),
  );

  Customer copyWith({double? balance}) => Customer(
    id: id, name: name, phone: phone, balance: balance ?? this.balance,
  );
}

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
}

// --- CUSTOMER NOTIFIER ---
class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) { _loadFromHive(); }

  Box get _box => Hive.box('settings');

  void _loadFromHive() {
    final dynamic data = _box.get('customerList');
    if (data != null && data is List) {
      state = data.map((e) => Customer.fromMap(Map<dynamic, dynamic>.from(e))).toList();
    }
  }

  void addCustomer(String name, String phone) {
    final newCustomer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
    );
    state = [...state, newCustomer];
    _saveToHive();
  }

  void updateBalance(String id, double amount) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(balance: c.balance + amount) else c
    ];
    _saveToHive();
  }

  void _saveToHive() {
    _box.put('customerList', state.map((e) => e.toMap()).toList());
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
    return sum + (((item['price'] as num).toDouble() - buyPrice) * item['qty']);
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
        'qty': 1.0,
      }];
    }
    return true;
  }

  Future<bool> checkStock(String barcode, double requestedQty) async {
    final data = await DatabaseHelper.instance.getProductByBarcode(barcode);
    if (data == null) return false;
    final product = Product.fromMap(data);
    return (product.stock as num).toDouble() >= requestedQty;
  }

  void updateQuantity(String barcode, double newQty) {
    state = [
      for (final item in state)
        if (item['barcode'] == barcode) { ...item, 'qty': newQty } else item
    ];
  }

  void removeFromCart(String barcode) => state = state.where((item) => item['barcode'] != barcode).toList();
  void clear() => state = [];

  Future<void> completeSale(String paymentMethod, {String? customerId}) async {
    if (state.isEmpty) return;

    try {
      final double total = totalAmount;
      final double profit = totalProfit;
      final itemsSnapshot = List<Map<String, dynamic>>.from(state);

      // Veritabanı işlemleri
      await DatabaseHelper.instance.completeSale(
        totalAmount: total,
        totalProfit: profit,
        items: itemsSnapshot,
        paymentMethod: paymentMethod,
      );

      // Veresiye ise bakiyeyi güncelle
      if (paymentMethod == "VERESİYE" && customerId != null) {
        ref.read(customerProvider.notifier).updateBalance(customerId, total);
      }

      // Yazıcıya gönder
      await _printReceipt(itemsSnapshot, total, paymentMethod);

      clear();
      _refreshAll();
      
    } catch (e) {
      debugPrint("SATIŞ TAMAMLAMA HATASI: $e");
      rethrow;
    }
  }

  void _refreshAll() {
    ref.read(productsProvider.notifier).loadProducts();
    ref.invalidate(salesHistoryProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(weeklySalesProvider);
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
      debugPrint("Yazıcı Hatası: $e");
    }
  }
}