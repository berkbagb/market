import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:market/features/pos/market_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class BarcodeScannerView extends ConsumerStatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  ConsumerState<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends ConsumerState<BarcodeScannerView> with SingleTickerProviderStateMixin {
  bool isProcessing = false;
  late AnimationController _animationController;
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? "";
      if (code.isNotEmpty) {
        setState(() => isProcessing = true);
        
        // Kullanıcıya hafif bir titreşim ver
        HapticFeedback.mediumImpact();

        // Ürünü sepete ekle
        final success = await ref.read(cartProvider.notifier).addToCart(code);

        if (mounted) {
          if (success) {
            _showSuccessIndicator(code);
            // Başarılı okutmadan sonra kısa bir bekleme (Çift okumayı önler)
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) setState(() => isProcessing = false);
          } else {
            _showErrorNotification(code);
          }
        }
      }
    }
  }

  void _showSuccessIndicator(String code) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "$code başarıyla eklendi", 
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 140, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showErrorNotification(String code) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.redAccent, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              "Ürün Tanımsız", 
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)
            ),
            const SizedBox(height: 12),
            Text(
              "[$code] barkodlu ürün envanterinizde bulunamadı. Lütfen ürünü ekleyin veya barkodu kontrol edin.", 
              style: GoogleFonts.plusJakartaSans(color: Colors.white54, height: 1.5), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("TARAMAYA DEVAM ET", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanAreaSize = 260.0;
    final topOffset = MediaQuery.of(context).size.height / 2.2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          
          // Kamera Karartma Maskesi
          CustomPaint(
            painter: ScannerOverlayPainter(
              rect: Rect.fromCenter(
                center: Offset(MediaQuery.of(context).size.width / 2, topOffset),
                width: scanAreaSize,
                height: scanAreaSize,
              ),
            ),
            child: Container(),
          ),

          // Lazer Çizgisi Animasyonu
          _buildLaserLine(topOffset, scanAreaSize),

          // Üst Kontroller
          _buildTopControls(),
          
          // Alt Bilgi Kartı
          _buildBottomStatusCard(),
        ],
      ),
    );
  }

  Widget _buildLaserLine(double topOffset, double size) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          top: (topOffset - size / 2) + (size * _animationController.value),
          left: MediaQuery.of(context).size.width / 2 - size / 2,
          child: Container(
            width: size,
            height: 3,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 1),
              ],
              gradient: const LinearGradient(
                colors: [Colors.transparent, Color(0xFF6366F1), Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 54,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleBtn(Icons.close_rounded, () => Navigator.pop(context)),
          Row(
            children: [
              _circleBtn(Icons.flashlight_on_rounded, () => controller.toggleTorch(), isTorch: true),
              const SizedBox(width: 16),
              _circleBtn(Icons.cameraswitch_rounded, () => controller.switchCamera()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool isTorch = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        child: isTorch
            ? ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, state, child) {
                  final bool isOn = state.torchState == TorchState.on;
                  return Icon(
                    isOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                    color: isOn ? const Color(0xFFFACC15) : Colors.white,
                    size: 24,
                  );
                },
              )
            : Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildBottomStatusCard() {
    final cartCount = ref.watch(cartProvider).length;
    
    return Positioned(
      bottom: 48,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(20)
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_cart_rounded, color: Color(0xFF6366F1)),
                  if (cartCount > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          cartCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProcessing ? "İşleniyor..." : "Tarama Hazır", 
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isProcessing ? "Lütfen bekleyin" : "Barkodu alana hizalayın", 
                    style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(14)
              ),
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect rect;
  ScannerOverlayPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.75);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(32)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Köşe çerçeveleri (Corners)
    final borderPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final double cornerSize = 40;
    
    // Sol Üst Köşe
    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.top + cornerSize)
      ..lineTo(rect.left, rect.top + 20)
      ..arcToPoint(Offset(rect.left + 20, rect.top), radius: const Radius.circular(20))
      ..lineTo(rect.left + cornerSize, rect.top), borderPaint);

    // Sağ Üst Köşe
    canvas.drawPath(Path()
      ..moveTo(rect.right - cornerSize, rect.top)
      ..lineTo(rect.right - 20, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + 20), radius: const Radius.circular(20))
      ..lineTo(rect.right, rect.top + cornerSize), borderPaint);

    // Sol Alt Köşe
    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.bottom - cornerSize)
      ..lineTo(rect.left, rect.bottom - 20)
      ..arcToPoint(Offset(rect.left + 20, rect.bottom), radius: const Radius.circular(20))
      ..lineTo(rect.left + cornerSize, rect.bottom), borderPaint);

    // Sağ Alt Köşe
    canvas.drawPath(Path()
      ..moveTo(rect.right - cornerSize, rect.bottom)
      ..lineTo(rect.right - 20, rect.bottom)
      ..arcToPoint(Offset(rect.right, rect.bottom - 20), radius: const Radius.circular(20))
      ..lineTo(rect.right, rect.bottom - cornerSize), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}