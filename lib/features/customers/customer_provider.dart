import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/core/database_helper.dart';
import 'package:market/models/customer_model.dart';
import 'dart:developer' as dev;

/// Müşteri listesini yöneten merkezi Provider
final customersProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) {
    refresh();
  }

  /// Veritabanından müşterileri çeker ve state'i günceller
  Future<void> refresh({String? query}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps;
      
      if (query == null || query.trim().isEmpty) {
        maps = await db.query('customers', orderBy: 'name ASC');
      } else {
        // SQL Injection koruması için whereArgs kullanımı
        maps = await db.query(
          'customers',
          where: 'name LIKE ? OR phone LIKE ?',
          whereArgs: ['%${query.trim()}%', '%${query.trim()}%'],
          orderBy: 'name ASC',
        );
      }
      
      state = maps.map((m) => Customer.fromMap(m)).toList();
    } catch (e) {
      dev.log("Müşteri listesi çekilirken hata oluştu: $e");
      // İsteğe bağlı olarak state = [] veya hata durumu eklenebilir
    }
  }

  /// Yeni müşteri ekler ve listeyi tazeler
  Future<void> addCustomer(String name, String phone) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('customers', {
        'name': name.trim(),
        'phone': phone.trim(),
        'points': 0.0, // Başlangıç puanı
        'createdAt': DateTime.now().toIso8601String(),
      });
      await refresh();
    } catch (e) {
      dev.log("Müşteri eklenirken hata: $e");
    }
  }

  /// Mevcut müşteriyi günceller
  Future<void> updateCustomer(Customer customer) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'customers',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
      // Tüm listeyi çekmek yerine sadece state'i lokalde güncellemek performansı artırır
      // Ancak veri tutarlılığı için refresh() en güvenli yoldur.
      await refresh(); 
    } catch (e) {
      dev.log("Müşteri güncellenirken hata: $e");
    }
  }

  /// Müşteriyi ID üzerinden siler
  Future<void> deleteCustomer(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
      await refresh();
    } catch (e) {
      dev.log("Müşteri silinirken hata: $e");
    }
  }

  /// Müşteriye puan ekleme/çıkarma (Sadakat Sistemi için)
  Future<void> updatePoints(int id, double newPoints) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'customers',
        {'points': newPoints},
        where: 'id = ?',
        whereArgs: [id],
      );
      await refresh();
    } catch (e) {
      dev.log("Puan güncellenirken hata: $e");
    }
  }
}