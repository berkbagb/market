import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:market/core/database_helper.dart';

// --- MODELLER ---

class StoreInfo {
  final String name;
  final String phone;
  final String address;
  final String footerNote;

  StoreInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.footerNote,
  });

  StoreInfo copyWith({
    String? name,
    String? phone,
    String? address,
    String? footerNote,
  }) {
    return StoreInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      footerNote: footerNote ?? this.footerNote,
    );
  }
}

// --- NOTIFIER (MANTIK KATMANI) ---

class SettingsNotifier extends StateNotifier<StoreInfo> {
  SettingsNotifier() : super(_initialValue()) {
    _loadSettingsFromHive();
  }

  // Fabrika Ayarları (Sıfırlama sonrası dönecek değerler)
  static StoreInfo _initialValue() => StoreInfo(
        name: "BERK MARKET",
        phone: "05XX XXX XX XX",
        address: "Merkez / İstanbul",
        footerNote: "Bizi tercih ettiğiniz için teşekkürler!",
      );

  // Hive kutusu: 'settings' adıyla main.dart'ta açılmış olmalı
  Box get _box => Hive.box('settings');

  // 1. Verileri Hive'dan Çek
  void _loadSettingsFromHive() {
    try {
      state = StoreInfo(
        name: _box.get('storeName', defaultValue: _initialValue().name) as String,
        phone: _box.get('storePhone', defaultValue: _initialValue().phone) as String,
        address: _box.get('storeAddress', defaultValue: _initialValue().address) as String,
        footerNote: _box.get('footerNote', defaultValue: _initialValue().footerNote) as String,
      );
    } catch (e) {
      debugPrint("Hive yükleme hatası: $e");
    }
  }

  // 2. Mağaza Ayarlarını Güncelle
  Future<void> updateSettings({
    required String name,
    required String phone,
    required String address,
    required String footerNote,
  }) async {
    try {
      await _box.put('storeName', name);
      await _box.put('storePhone', phone);
      await _box.put('storeAddress', address);
      await _box.put('footerNote', footerNote);

      state = state.copyWith(
        name: name,
        phone: phone,
        address: address,
        footerNote: footerNote,
      );
    } catch (e) {
      debugPrint("Ayarlar kaydedilirken hata: $e");
    }
  }

  // 3. YÖNETİCİ PANELİ VE GÜVENLİK İŞLEMLERİ
  
  // Şifre kontrolü (SettingsScreen'de giriş yaparken kullanılır)
  bool checkAdminPassword(String input) {
    final savedPass = _box.get('adminPassword');
    
    if (savedPass == null) {
      // Daha önce hiç şifre belirlenmemişse '1234' ile giriş yapmasına izin ver
      return input == "1234";
    }

    debugPrint("Kaydedilmiş şifre: $savedPass, Girilen şifre: $input");
    
    return input == (savedPass as String);
  }

  // Ham şifreyi getir (UI'da kontrol veya gösterme için)
  String? getAdminPassword() {
    return _box.get('adminPassword') as String?;
  }

  // Yeni Şifre Kaydet (Gizli panelden değiştirilince çalışır)
  Future<void> setAdminPassword(String newPassword) async {
    try {
      await _box.put('adminPassword', newPassword);
      debugPrint("Yönetici şifresi güncellendi.");
    } catch (e) {
      debugPrint("Şifre kaydedilirken hata: $e");
    }
  }

  // 4. KRİTİK: Tam Temizlik (Atom Bombası)
  // Bu metod hem SQLite'ı hem Hive'ı hem de belleği temizler.
  Future<bool> resetEntireSystem() async {
  try {
    // 1. Fiziksel temizlik
    await DatabaseHelper.instance.windowsTamTemizlik();
    
    // 2. Bellek temizliği (Riverpod state'ini ilk haline getir)
    state = _initialValue();
    
    // 3. Hive temizliği
    await _box.clear();

    return true;
  } catch (e) {
    debugPrint("Sıfırlama hatası: $e");
    return false;
  }
}
}

// --- PROVIDER TANIMI ---

final settingsProvider = StateNotifierProvider<SettingsNotifier, StoreInfo>((ref) {
  return SettingsNotifier();
});