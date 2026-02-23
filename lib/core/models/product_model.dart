class Product {
  final int? id;
  final String name;
  final String barcode;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final int minStockLevel;
  final double taxRate;
  final String unit;
  final String category;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.minStockLevel,
    required this.taxRate,
    required this.unit,
    required this.category,
  });

  // HATAYI ÇÖZEN KISIM BURASI:
  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    int? minStockLevel,
    double? taxRate,
    String? unit,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      taxRate: taxRate ?? this.taxRate,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'stock': stock,
      'minStockLevel': minStockLevel,
      'taxRate': taxRate,
      'unit': unit,
      'category': category,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    // Burası hatanın çözüldüğü yer: Gelen veri num (double/int) ise toInt() veya toDouble() ile zorluyoruz
    return Product(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      buyPrice: (map['buyPrice'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (map['sellPrice'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      minStockLevel: (map['minStockLevel'] as num?)?.toInt() ?? 0,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? 'Adet',
      category: map['category']?.toString() ?? 'Genel',
    );
  }
}