import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  static const String _dbName = 'market_v3_final.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
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
    // 1. Ürünler Tablosu
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        barcode TEXT UNIQUE, 
        name TEXT, 
        buyPrice REAL, 
        sellPrice REAL, 
        stock REAL DEFAULT 0, 
        minStockLevel REAL DEFAULT 5, 
        category TEXT, 
        unit TEXT, 
        taxRate REAL, 
        createdAt TEXT
      )
    ''');

    // 2. Satışlar Tablosu
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        customerId INTEGER, 
        totalAmount REAL, 
        totalProfit REAL, 
        paymentMethod TEXT, 
        isReturned INTEGER DEFAULT 0, 
        createdAt TEXT
      )
    ''');

    // 3. Satış Detayları Tablosu
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        saleId INTEGER, 
        productBarcode TEXT, 
        productName TEXT, 
        quantity REAL, 
        price REAL, 
        buyPriceAtSale REAL,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // 4. Stok Hareket Logları
    await db.execute('''
      CREATE TABLE stock_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productBarcode TEXT,
        oldStock REAL,
        newStock REAL,
        changeAmount REAL,
        type TEXT, 
        createdAt TEXT
      )
    ''');

    // 5. Müşteriler Tablosu
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        balance REAL DEFAULT 0,
        createdAt TEXT
      )
    ''');
  }

  // --- ÜRÜN İŞLEMLERİ ---

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await database;
    final res = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('products', {
      ...row,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateProduct(Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('products', row, where: 'barcode = ?', whereArgs: [row['barcode']]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÜŞTERİ (VERESİYE) İŞLEMLERİ ---

  Future<int> insertCustomer(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('customers', {
      ...row,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query('customers', orderBy: 'name ASC');
  }

  Future<int> updateCustomerBalance(int customerId, double amount) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE customers SET balance = balance + ? WHERE id = ?',
      [amount, customerId]
    );
  }

  // --- SATIŞ İŞLEMLERİ (TRANSACTION) ---

  Future<void> completeSale({
    required double totalAmount,
    required double totalProfit,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    int? customerId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'customerId': customerId,
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'paymentMethod': paymentMethod,
        'isReturned': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (paymentMethod == 'VERESİYE' && customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET balance = balance + ? WHERE id = ?',
          [totalAmount, customerId]
        );
      }

      for (var item in items) {
        final List<Map<String, dynamic>> p = await txn.query(
          'products', 
          columns: ['stock'], 
          where: 'barcode = ?', 
          whereArgs: [item['barcode']]
        );
        
        double currentStock = p.isNotEmpty ? (p.first['stock'] as num).toDouble() : 0.0;

        await txn.insert('sale_items', {
          'saleId': saleId,
          'productBarcode': item['barcode'],
          'productName': item['name'],
          'quantity': item['qty'],
          'price': item['price'],
          'buyPriceAtSale': item['buyPrice'] ?? 0.0,
        });

        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE barcode = ?', 
          [item['qty'], item['barcode']]
        );

        await txn.insert('stock_logs', {
          'productBarcode': item['barcode'],
          'oldStock': currentStock,
          'newStock': currentStock - (item['qty'] as num).toDouble(),
          'changeAmount': item['qty'],
          'type': 'SATIŞ',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  // --- RAPORLAMA VE EKSTRA SORGULAR ---

  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    final db = await database;
    return await db.query('sales', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.rawQuery('SELECT DISTINCT category FROM products WHERE category IS NOT NULL');
  }

  Future<List<Map<String, dynamic>>> getStockLogs() async {
    final db = await database;
    return await db.query('stock_logs', orderBy: 'createdAt DESC');
  }

  // --- SİSTEMİ SIFIRLA (KRİTİK) ---
  Future<void> windowsTamTemizlik() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final dbPath = await getDatabasesPath();
      final mainPath = join(dbPath, _dbName);
      final walPath = "$mainPath-wal";
      final shmPath = "$mainPath-shm";

      for (var path in [mainPath, walPath, shmPath]) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      await Hive.deleteFromDisk();
      debugPrint("Sistem tamamen temizlendi.");
    } catch (e) {
      debugPrint("Sıfırlama Hatası: $e");
      rethrow;
    }
  }
}