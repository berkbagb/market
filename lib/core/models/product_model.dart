class Product {
  final int? id;
  final String barcode;
  final String name;
  final double buyPrice;
  final double sellPrice;
  final double stock;
  final double minStockLevel;
  final String category;
  final String unit;
  final double taxRate;
  final DateTime? createdAt;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    this.minStockLevel = 5.0,
    this.category = 'Genel',
    this.unit = 'Adet',
    this.taxRate = 20.0,
    this.createdAt,
  });

  // HATA ÇÖZÜMÜ: copyWith metodu eksikti, ekledik.
  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    double? buyPrice,
    double? sellPrice,
    double? stock,
    double? minStockLevel,
    String? category,
    String? unit,
    double? taxRate,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'stock': stock,
      'minStockLevel': minStockLevel,
      'category': category,
      'unit': unit,
      'taxRate': taxRate,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      // HATA ÇÖZÜMÜ: num to double dönüşümü yapıldı
      buyPrice: (map['buyPrice'] ?? 0.0).toDouble(),
      sellPrice: (map['sellPrice'] ?? 0.0).toDouble(),
      stock: (map['stock'] ?? 0.0).toDouble(),
      minStockLevel: (map['minStockLevel'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'Genel',
      unit: map['unit'] ?? 'Adet',
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}