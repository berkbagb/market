import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market/features/settings/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.name);
    _addressController = TextEditingController(text: settings.address);
    _phoneController = TextEditingController(text: settings.phone);
    _footerController = TextEditingController(text: settings.footerNote);
  }

  // --- GİZLİ MEKANİZMA ---
  void _handleVersionTap() {
    setState(() {
      _versionTapCount++;
      if (_versionTapCount >= 15) {
        _versionTapCount = 0;
        _showSecretAuthDialog();
      }
    });
  }

  void _showSecretAuthDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Yönetici Girişi", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Giriş Şifresi",
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İPTAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
  final notifier = ref.read(settingsProvider.notifier);
  // checkAdminPassword artık şifre yoksa 1234'ü otomatik biliyor
  if (notifier.checkAdminPassword(passwordController.text)) {
    Navigator.pop(ctx);
    _showSecretVault(); // Kapı açıldı!
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Hatalı Şifre! (İlk giriş için 1234 deneyin)")),
    );
  }
},
            child: const Text("GİRİŞ"),
          ),
        ],
      ),
    );
  }

  // GİZLİ KUTU: Burası her şeyin yönetildiği yer
  void _showSecretVault() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("YÖNETİCİ PANELİ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.password, color: Colors.blue),
              title: const Text("Giriş Şifresini Değiştir", style: TextStyle(color: Colors.white)),
              onTap: () => _showSetPasswordDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Veritabanını Sıfırla (Kritik)", style: TextStyle(color: Colors.red)),
              onTap: () => _confirmHardReset(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPasswordDialog() {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yeni Şifre Belirle"),
        content: TextField(controller: passController, decoration: const InputDecoration(hintText: "Örn: 5566")),
        actions: [
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setAdminPassword(passController.text);
              Navigator.pop(ctx);
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }

  void _confirmHardReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("DİKKAT!"),
        content: const Text("Tüm satışlar ve stoklar silinecek. Uygulama sıfırlanacak!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("VAZGEÇ")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SİL", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
  final success = await ref.read(settingsProvider.notifier).resetEntireSystem();
  if (success && mounted) {
    // Uygulamayı tamamen baştan başlatmış gibi ilk sayfaya atar ve tüm provider'ları sıfırlar
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sistem sıfırlandı ve yeniden başlatıldı.")),
    );
  }
}
  }

  // --- UI TASARIMI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistem Ayarları"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard("Mağaza Bilgileri", [
                    _buildModernField(_nameController, "Mağaza Adı", Icons.store),
                    _buildModernField(_phoneController, "Telefon", Icons.phone),
                    _buildModernField(_addressController, "Adres", Icons.location_on),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard("Fiş Yazdırma Ayarları", [
                    _buildModernField(_footerController, "Fiş Altı Notu", Icons.note_alt),
                  ]),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text("TÜM AYARLARI KAYDET", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ref.read(settingsProvider.notifier).updateSettings(
                        name: _nameController.text,
                        phone: _phoneController.text,
                        address: _addressController.text,
                        footerNote: _footerController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ayarlar Güncellendi")));
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // GİZLİ VERSİYON BUTONU
          GestureDetector(
            onTap: _handleVersionTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.transparent,
              child: Opacity(
                opacity: 0.3,
                child: Column(
                  children: [
                    Text("Build: 2024.03.01", style: Theme.of(context).textTheme.bodySmall),
                    const Text("v2.1.0-stable", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          labelText: label,
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}