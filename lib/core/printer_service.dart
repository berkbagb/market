import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:developer' as dev;

class PrinterService {
  static BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  /// Türkçe karakterleri termal yazıcının anlayacağı formata çevirir
  static String _fixTurkishChars(String text) {
    return text
        .replaceAll('Ğ', 'G').replaceAll('ğ', 'g')
        .replaceAll('Ü', 'U').replaceAll('ü', 'u')
        .replaceAll('Ş', 'S').replaceAll('ş', 's')
        .replaceAll('İ', 'I').replaceAll('ı', 'i')
        .replaceAll('Ö', 'O').replaceAll('ö', 'o')
        .replaceAll('Ç', 'C').replaceAll('ç', 'c');
  }

  /// Satış verisini byte formatına dönüştürür (58mm Termal Yazıcılar için)
  static Future<List<int>> createReceipt(Map<String, dynamic> data) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Mağaza Başlığı
    bytes += generator.text(
      _fixTurkishChars(data['storeName'] ?? 'BERK MARKET'),
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2, // PosFontSize yerine PosTextSize kullanıldı
        width: PosTextSize.size2,
      ),
    );
    
    bytes += generator.text(
      _fixTurkishChars(data['storeAddress'] ?? ''),
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    // Tarih ve Fiş No
    bytes += generator.text("Tarih: ${DateTime.now().toString().substring(0, 16)}");
    if (data['saleId'] != null) {
      bytes += generator.text("Fis No: ${data['saleId']}");
    }
    
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    // Ürün Tablo Başlığı
    bytes += generator.row([
      PosColumn(text: "Urun", width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: "Ad.", width: 2, styles: const PosStyles(bold: true, align: PosAlign.center)),
      PosColumn(text: "Tutar", width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    // Ürünler
    final List items = data['items'] ?? [];
    for (var item in items) {
      bytes += generator.row([
        PosColumn(text: _fixTurkishChars(item['name'] ?? 'Urun'), width: 7),
        PosColumn(text: "${item['qty']}", width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
          text: "${((item['price'] ?? 0) * (item['qty'] ?? 0)).toStringAsFixed(2)}", 
          width: 3, 
          styles: const PosStyles(align: PosAlign.right)
        ),
      ]);
    }

    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    // Toplam ve Ödeme
    bytes += generator.row([
      PosColumn(text: "TOPLAM", width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size1)), // Boyut size1 yapıldı (58mm tasma yapmasın diye)
      PosColumn(
        text: "${(data['totalAmount'] ?? 0).toStringAsFixed(2)} TL", 
        width: 6, 
        styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size1)
      ),
    ]);

    bytes += generator.text(
      "Odeme: ${_fixTurkishChars(data['paymentMethod'] ?? 'NAKIT')}", 
      styles: const PosStyles(align: PosAlign.right)
    );

    // Alt Bilgi
    bytes += generator.feed(1);
    bytes += generator.text("Iyi Gunler Dileriz", styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Yazıcıya veri gönderir
  static Future<void> printReceipt(List<int> bytes) async {
    try {
      bool? isConnected = await bluetooth.isConnected;
      
      if (isConnected != true) {
        dev.log("Yazıcı bağlı değil! Lütfen ayarlardan bağlanın.");
        return;
      }

      // BlueThermalPrinter Uint8List beklediği için dönüşüm yapıyoruz
      await bluetooth.writeBytes(Uint8List.fromList(bytes));
      dev.log("Yazdırma başarılı.");
    } catch (e) {
      dev.log("Yazdırma sırasında teknik hata: $e");
    }
  }

  /// Bluetooth cihazlarını listeler
  static Future<List<BluetoothDevice>> getDevices() async {
    try {
      return await bluetooth.getBondedDevices();
    } catch (e) {
      dev.log("Cihaz listesi alınamadı: $e");
      return [];
    }
  }
}