class Product {
  final int? id;
  final String name;
  final String barcode;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final String category;
  final String unit;
  final double taxRate;      // KDV Oranı (Örn: 20.0)
  final int minStockLevel;   // Kritik Stok Seviyesi

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.category,
    required this.unit,
    this.taxRate = 20.0,
    this.minStockLevel = 5,
  });

  // --- HESAPLANMIŞ ALANLAR (Computed Properties) ---

  /// Ürünün kritik stok seviyesinde olup olmadığını kontrol eder
  bool get isLowStock => stock <= minStockLevel;

  /// Ürün başına net kâr tutarı
  double get profitPerUnit => sellPrice - buyPrice;

  /// Kâr marjı yüzdesi (Yüzdelik formatta)
  double get profitMargin {
    if (buyPrice == 0) return 0;
    return ((sellPrice - buyPrice) / buyPrice) * 100;
  }

  /// KDV dahil toplam satış fiyatı (Eğer sellPrice KDV hariç tutuluyorsa kullanılır)
  /// Marketlerde genelde sellPrice KDV dahil girilir, bu fonksiyon opsiyoneldir.
  double get sellPriceWithTax => sellPrice * (1 + (taxRate / 100));

  // --- JSON / MAP DÖNÜŞÜMLERİ ---

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'barcode': barcode,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'stock': stock,
      'category': category,
      'unit': unit,
      'taxRate': taxRate,
      'minStockLevel': minStockLevel,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      buyPrice: (map['buyPrice'] ?? 0.0).toDouble(),
      sellPrice: (map['sellPrice'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      category: map['category'] ?? 'Genel',
      unit: map['unit'] ?? 'Adet',
      taxRate: (map['taxRate'] ?? 20.0).toDouble(),
      minStockLevel: map['minStockLevel'] ?? 5,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    String? category,
    String? unit,
    double? taxRate,
    int? minStockLevel,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      taxRate: taxRate ?? this.taxRate,
      minStockLevel: minStockLevel ?? this.minStockLevel,
    );
  }
}