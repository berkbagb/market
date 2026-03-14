import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/core/database_helper.dart';
import 'package:market/core/models/customer_model.dart';
import 'dart:developer' as dev;

/// Global Provider - Tüm uygulama bu provider üzerinden müşterilere erişir.
final customersProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) {
    refresh(); // Uygulama ilk açıldığında listeyi yükle
  }

  /// 1. Veritabanından Müşterileri Çek (Arama Destekli)
  Future<void> refresh({String? query}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      List<Map<String, dynamic>> maps;
      
      if (query == null || query.trim().isEmpty) {
        // Arama yoksa tüm müşterileri isme göre sırala
        maps = await db.query('customers', orderBy: 'name ASC');
      } else {
        // Arama varsa hem isim hem de telefonda ara (Case-insensitive / Küçük-büyük harf duyarsız)
        final cleanQuery = query.trim();
        maps = await db.query(
          'customers',
          where: 'name LIKE ? OR phone LIKE ?',
          whereArgs: ['%$cleanQuery%', '%$cleanQuery%'],
          orderBy: 'name ASC',
        );
      }
      
      state = maps.map((m) => Customer.fromMap(m)).toList();
    } catch (e) {
      dev.log("Müşteri listesi çekilirken hata oluştu: $e");
    }
  }

  /// 2. Yeni Müşteri Ekle
  Future<void> addCustomer(String name, String phone) async {
    try {
      if (name.trim().isEmpty) return; // İsimsiz müşteri eklemeyi engelle

      await DatabaseHelper.instance.insertCustomer({
        'name': name.trim(),
        'phone': phone.trim(),
        'balance': 0.0,
        'points': 0.0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      await refresh(); // Ekleme sonrası listeyi anlık güncelle
      dev.log("Yeni müşteri eklendi: $name");
    } catch (e) {
      dev.log("Müşteri eklenirken hata: $e");
    }
  }

  /// 3. Müşteri Bilgilerini Güncelle (Ad-Telefon)
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
      await refresh(); 
      dev.log("Müşteri bilgileri güncellendi (ID: $id)");
    } catch (e) {
      dev.log("Müşteri güncellenirken hata: $e");
    }
  }

  /// 4. Bakiye Güncelleme (Merkezi Fonksiyon)
  /// Borç eklemek için: (+) pozitif değer
  /// Tahsilat/Ödeme için: (-) negatif değer gönderilir.
  Future<void> updateBalance(int customerId, double amount) async {
    try {
      // DatabaseHelper içindeki merkezi metodu kullanarak atomik işlem yapar
      await DatabaseHelper.instance.updateCustomerBalance(customerId, amount);
      await refresh(); 
      dev.log("Müşteri bakiyesi güncellendi (Miktar: $amount)");
    } catch (e) {
      dev.log("Bakiye güncellenirken hata: $e");
    }
  }

  /// 5. Müşteri Sil
  Future<void> deleteCustomer(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      await refresh();
      dev.log("Müşteri silindi (ID: $id)");
    } catch (e) {
      dev.log("Müşteri silinirken hata: $e");
    }
  }
}