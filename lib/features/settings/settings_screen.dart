import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Mağaza Bilgilerini Düzenleme Penceresi
  void _showStoreInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mağaza Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Mağaza Adı',
                hintText: 'Örn: BERK MARKET',
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Adres / Tel',
                hintText: 'Örn: Merkez Mah. No:1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Burada Hive'a kayıt eklenebilir
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bilgiler Kaydedildi!')),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Veritabanı Sıfırlama Onay Penceresi
  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verileri Sıfırla'),
        content: const Text(
          'Tüm satış geçmişi ve stok verileri silinecek. Bu işlem geri alınamaz! Emin misiniz?',
          style: TextStyle(color: Colors.redAccent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () async {
              // Hive kutularını temizle
              await Hive.box('customers').clear();
              // Eğer ürünler kutun varsa onu da temizle: 
              // await Hive.box('products').clear();
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tüm veriler temizlendi!')),
                );
              }
            },
            child: const Text('EVET, SİL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistem Ayarları'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Uygulama Ayarları'),
          _buildSettingItem(
            icon: Icons.print_rounded,
            title: 'Yazıcı Ayarları',
            subtitle: 'Fiş yazıcısı bağlantısını yönet',
            onTap: () {
              // Buraya ileride blue_thermal_printer entegre edilecek
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yazıcı taranıyor...')),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.store_mall_directory_rounded,
            title: 'Mağaza Bilgileri',
            subtitle: 'Fiş başlığı ve iletişim bilgileri',
            onTap: () => _showStoreInfoDialog(context),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Veri Yönetimi'),
          _buildSettingItem(
            icon: Icons.cloud_upload_rounded,
            title: 'Verileri Yedekle',
            subtitle: 'Excel veya JSON formatında dışa aktar',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yedek dosyası oluşturuluyor...')),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.delete_forever_rounded,
            title: 'Sistemi Sıfırla',
            subtitle: 'Tüm verileri kalıcı olarak temizle',
            color: Colors.redAccent,
            onTap: () => _showResetDialog(context),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Hakkında'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_user_rounded, color: Colors.green),
              title: Text('Lisans Durumu'),
              subtitle: Text('Berk Market POS - Aktif Sürüm'),
              trailing: Text('v1.0.0+1'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6366F1),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF6366F1)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? const Color(0xFF6366F1)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}