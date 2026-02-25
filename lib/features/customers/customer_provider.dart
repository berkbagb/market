import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/core/database_helper.dart';
import 'package:market/core/models/customer_model.dart';
import 'dart:developer' as dev;

/// Global Provider
final customersProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) {
    refresh(); // Başlangıçta verileri çek
  }

  /// 1. Veritabanından Müşterileri Çek (Arama Destekli)
  Future<void> refresh({String? query}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps;
      
      if (query == null || query.trim().isEmpty) {
        maps = await db.query('customers', orderBy: 'name ASC');
      } else {
        maps = await db.query(
          'customers',
          where: 'name LIKE ? OR phone LIKE ?',
          whereArgs: ['%${query.trim()}%', '%${query.trim()}%'],
          orderBy: 'name ASC',
        );
      }
      
      state = maps.map((m) => Customer.fromMap(m)).toList();
    } catch (e) {
      dev.log("Müşteri listesi çekilirken hata: $e");
    }
  }

  /// 2. Yeni Müşteri Ekle
  Future<void> addCustomer(String name, String phone) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('customers', {
        'name': name.trim(),
        'phone': phone.trim(),
        'balance': 0.0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await refresh();
    } catch (e) {
      dev.log("Müşteri eklenirken hata: $e");
    }
  }

  /// 3. Müşteri Güncelle (Düzeltildi)
  Future<void> updateCustomer(int id, String name, String phone) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'customers',
        {
          'name': name.trim(),
          'phone': phone.trim(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await refresh(); // Veritabanından güncel listeyi çek ve ekranı yenile
    } catch (e) {
      dev.log("Müşteri güncellenirken hata: $e");
    }
  }

  /// 4. Veresiye Borcu Ekle/Düş (Ödeme Al)
  Future<void> addDebt(int customerId, double amount) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Mevcut müşteriyi bul
      final List<Map<String, dynamic>> result = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (result.isNotEmpty) {
        double currentBalance = (result.first['balance'] as num).toDouble();
        double newBalance = currentBalance + amount;

        await db.update(
          'customers',
          {'balance': newBalance},
          where: 'id = ?',
          whereArgs: [customerId],
        );
        await refresh();
      }
    } catch (e) {
      dev.log("Borç güncellenirken hata: $e");
    }
  }

  /// 5. Müşteri Sil (Düzeltildi)
  Future<void> deleteCustomer(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      await refresh(); // Sildikten sonra listeyi tazele
    } catch (e) {
      dev.log("Müşteri silinirken hata: $e");
    }
  }
}