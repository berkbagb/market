import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('market_v3_final.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const intDefault0 = 'INTEGER NOT NULL DEFAULT 0';

    // 1. ÜRÜNLER
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        barcode TEXT UNIQUE NOT NULL,
        name $textType,
        buyPrice $doubleType,
        sellPrice $doubleType,
        stock REAL NOT NULL DEFAULT 0.0,
        minStockLevel REAL DEFAULT 5.0,
        category TEXT DEFAULT 'Genel',
        unit TEXT DEFAULT 'Adet',
        taxRate REAL DEFAULT 20.0,
        createdAt TEXT
      )
    ''');

    // 2. MÜŞTERİLER
   // DatabaseHelper içindeki tablo oluşturma kısmı böyle olmalı:
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL DEFAULT 0.0,
        points REAL DEFAULT 0.0,
        createdAt TEXT
      )
    ''');

    // 3. SATIŞLAR (customerId eklendi)
    await db.execute('''
      CREATE TABLE sales (
        id $idType,
        customerId INTEGER,
        totalAmount $doubleType,
        totalProfit $doubleType,
        paymentMethod $textType,
        isReturned $intDefault0,
        createdAt $textType,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE SET NULL
      )
    ''');

    // 4. SATIŞ DETAYLARI
    await db.execute('''
      CREATE TABLE sale_items (
        id $idType,
        saleId INTEGER NOT NULL,
        productBarcode TEXT NOT NULL,
        productName $textType,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        buyPriceAtSale REAL NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // 5. STOK LOGLARI
    await db.execute('''
      CREATE TABLE stock_logs (
        id $idType,
        productBarcode TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        createdAt TEXT,
        FOREIGN KEY (productBarcode) REFERENCES products (barcode) ON DELETE CASCADE
      )
    ''');
  }

  // --- ÜRÜN İŞLEMLERİ ---

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final results = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    final data = {...row};
    data['createdAt'] ??= DateTime.now().toIso8601String();
    return await db.insert('products', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'products',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- KATEGORİ İŞLEMLERİ ---

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('SELECT DISTINCT category as name FROM products');
    return res.isEmpty ? [{'name': 'Genel'}] : res;
  }

  // --- SATIŞ VE STOK YÖNETİMİ (CustomerId Düzeltildi) ---

  Future<void> completeSale({
    required double totalAmount,
    required double totalProfit,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    int? customerId, // Hata veren parametre eklendi
  }) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // 1. Satış ana kaydını oluştur
      final saleId = await txn.insert('sales', {
        'customerId': customerId,
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'paymentMethod': paymentMethod,
        'isReturned': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      for (var item in items) {
        // 2. Satış kalemlerini ekle
        await txn.insert('sale_items', {
          'saleId': saleId,
          'productBarcode': item['barcode'],
          'productName': item['name'],
          'quantity': item['qty'],
          'price': item['price'],
          'buyPriceAtSale': item['buyPrice'] ?? 0.0,
        });

        // 3. Stoğu Güncelle (Azalt)
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE barcode = ?',
          [item['qty'], item['barcode']],
        );

        // 4. Stok Logu Oluştur
        await txn.insert('stock_logs', {
          'productBarcode': item['barcode'],
          'amount': -item['qty'],
          'type': 'SATIS',
          'description': 'Satış ID: $saleId',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // 5. Müşteri Puanı Güncelleme (Opsiyonel: Satışın %1'i kadar puan)
      if (customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET points = points + ? WHERE id = ?',
          [(totalAmount * 0.01), customerId],
        );
      }
    });
  }

  // --- SATIŞ GEÇMİŞİ (Müşteri Adıyla Birlikte) ---

  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    final db = await instance.database;
    // JOIN kullanarak müşteri adını da çekiyoruz
    return await db.rawQuery('''
      SELECT s.*, c.name as customerName 
      FROM sales s
      LEFT JOIN customers c ON s.customerId = c.id
      ORDER BY s.createdAt DESC
    ''');
  }

  // --- STOK LOGLARI ---

  Future<List<Map<String, dynamic>>> getStockLogs() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT sl.*, p.name as productName 
      FROM stock_logs sl
      JOIN products p ON sl.productBarcode = p.barcode
      ORDER BY sl.createdAt DESC
    ''');
  }

  // --- ANALİTİK ---

  Future<Map<String, double>> getTodayStats() async {
    final db = await instance.database;
    final res = await db.rawQuery('''
      SELECT SUM(totalAmount) as revenue, SUM(totalProfit) as profit 
      FROM sales 
      WHERE date(createdAt) = date('now') AND isReturned = 0
    ''');

    if (res.isNotEmpty && res.first['revenue'] != null) {
      return {
        'revenue': (res.first['revenue'] as num).toDouble(),
        'profit': (res.first['profit'] as num).toDouble(),
      };
    }
    return {'revenue': 0.0, 'profit': 0.0};
  }
}