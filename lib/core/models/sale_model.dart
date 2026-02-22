import 'package:flutter/foundation.dart';

// --- SALE ITEM MODEL (v3 - Satır Bazlı Detaylandırma) ---
@immutable
class SaleItem {
  final String barcode;
  final String name;
  final double qty;
  final double price;
  final double buyPrice;

  const SaleItem({
    required this.barcode,
    required this.name,
    required this.qty,
    required this.price,
    required this.buyPrice,
  });

  // --- HESAPLANMIŞ ALANLAR ---
  double get lineTotal => qty * price;
  double get lineProfit => (price - buyPrice) * qty;

  Map<String, dynamic> toMap() => {
        'barcode': barcode,
        'name': name,
        'qty': qty,
        'price': price,
        'buyPrice': buyPrice,
      };

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        barcode: map['barcode'] ?? map['productBarcode'] ?? '',
        name: map['name'] ?? map['productName'] ?? 'Bilinmeyen Ürün',
        qty: (map['qty'] as num?)?.toDouble() ?? 0.0,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        buyPrice: (map['buyPrice'] as num?)?.toDouble() ?? 0.0,
      );
}

// --- MAIN SALE MODEL (v3 - Kurumsal Satış Modeli) ---
@immutable
class Sale {
  final int? id;
  final int? customerId;
  final String? customerName; 
  final double totalAmount;
  final double totalProfit;
  final String paymentMethod; // 'Nakit', 'Kredi Kartı', 'Veresiye'
  final DateTime createdAt;
  final List<SaleItem> items;
  final int isReturned; // 0: Normal, 1: İade

  const Sale({
    this.id,
    this.customerId,
    this.customerName,
    required this.totalAmount,
    required this.totalProfit,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
    this.isReturned = 0,
  });

  // --- HESAPLANMIŞ ALANLAR ---
  bool get isReturnSale => isReturned == 1;
  int get totalItemCount => items.length;

  // Veritabanı işlemleri için Map dönüşümü (Master Table)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'totalAmount': totalAmount,
      'totalProfit': totalProfit,
      'paymentMethod': paymentMethod,
      'isReturned': isReturned,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Veritabanından (veya JSON'dan) nesneye dönüşüm
  factory Sale.fromMap(Map<String, dynamic> map, {List<Map<String, dynamic>>? itemMaps}) {
    return Sale(
      id: map['id'] as int?,
      customerId: map['customerId'] as int?,
      customerName: map['customerName'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Nakit',
      isReturned: map['isReturned'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String) 
          : DateTime.now(),
      items: itemMaps != null 
          ? itemMaps.map((i) => SaleItem.fromMap(i)).toList()
          : [],
    );
  }

  // State yönetimi için copyWith
  Sale copyWith({
    int? id,
    int? customerId,
    String? customerName,
    double? totalAmount,
    double? totalProfit,
    String? paymentMethod,
    DateTime? createdAt,
    List<SaleItem>? items,
    int? isReturned,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      totalProfit: totalProfit ?? this.totalProfit,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      isReturned: isReturned ?? this.isReturned,
    );
  }
}